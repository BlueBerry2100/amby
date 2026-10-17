import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'art/art_sources.dart';
import 'art/ascii_art.dart';
import 'audio_engine.dart';
import 'catalog.dart';
import 'models.dart';
import 'look/look.dart';

/// Состояние приложения: каталог звуков и сетов, текущий микс, таймер сна.
class AppState extends ChangeNotifier {
  AppState(this._engine);

  final AudioEngine _engine;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const _kCustomSounds = 'custom_sounds';
  static const _kCustomSets = 'custom_sets';
  static const _kMaster = 'master_volume';
  static const _kAccent = 'accent';
  static const _kLook = 'look';
  static const defaultVolume = 0.6;

  String _accent = Accents.defaultKey;
  LookId _look = LookId.ascii;

  final List<Sound> _customSounds = [];
  final List<SoundSet> _customSets = [];

  /// Текущий микс: id звука → громкость (порядок = порядок включения).
  final Map<String, double> _active = {};

  bool _paused = false;
  double _masterVolume = 1;
  Timer? _sleepTimer;
  DateTime? _sleepAt;
  String? lastError;

  List<Sound> get sounds => [...builtInSounds, ..._customSounds];
  List<SoundSet> get sets => [...builtInSets, ..._customSets];
  Map<String, double> get active => Map.unmodifiable(_active);
  bool get hasActive => _active.isNotEmpty;
  bool get paused => _paused;
  double get masterVolume => _masterVolume;
  DateTime? get sleepAt => _sleepAt;
  String get accentKey => _accent;
  Color get accent => Accents.all[_accent]!;
  LookId get lookId => _look;

  /// Оформление и тема пересобираются только при смене оформления или акцента —
  /// иначе каждое движение ползунка запускало бы анимацию смены темы.
  (Look, ThemeData)? _themeCache;
  Look get look => _theme.$1;
  ThemeData get theme => _theme.$2;
  (Look, ThemeData) get _theme {
    final cached = _themeCache;
    if (cached != null && cached.$1.id == _look && cached.$1.accent == accent) return cached;
    final look = Look.build(_look, accent);
    return _themeCache = (look, look.toTheme());
  }

  bool isActive(String id) => _active.containsKey(id);
  double volumeOf(String id) => _active[id] ?? defaultVolume;
  Sound? soundById(String id) => sounds.where((s) => s.id == id).firstOrNull;

  Future<void> load() async {
    await Future.wait([_engine.init(), ArtShaders.load()]);

    final accent = await _prefs.getString(_kAccent);
    if (Accents.all.containsKey(accent)) _accent = accent!;
    final look = await _prefs.getString(_kLook);
    _look = LookId.values.where((l) => l.name == look).firstOrNull ?? LookId.ascii;

    final soundsJson = await _prefs.getString(_kCustomSounds);
    if (soundsJson != null) {
      _customSounds.addAll(
        (jsonDecode(soundsJson) as List)
            .map((e) => Sound.fromJson(e as Map<String, dynamic>))
            .where((s) => File(s.path).existsSync()),
      );
    }
    final setsJson = await _prefs.getString(_kCustomSets);
    if (setsJson != null) {
      _customSets.addAll(
        (jsonDecode(setsJson) as List).map((e) => SoundSet.fromJson(e as Map<String, dynamic>)),
      );
    }
    _masterVolume = await _prefs.getDouble(_kMaster) ?? 1;
    _engine.setMasterVolume(_masterVolume);
    notifyListeners();
  }

  // ---------- Микс ----------

  Future<void> toggle(Sound sound) async {
    if (isActive(sound.id)) {
      _active.remove(sound.id);
      _engine.stop(sound.id);
      notifyListeners();
    } else {
      await _start(sound, defaultVolume);
    }
  }

  Future<void> _start(Sound sound, double volume) async {
    _active[sound.id] = volume;
    _resumeIfPaused();
    notifyListeners();
    try {
      await _engine.start(sound, volume);
      // пока звук грузился, его могли выключить
      if (!isActive(sound.id)) _engine.stop(sound.id);
    } catch (e) {
      _active.remove(sound.id);
      lastError = 'Не удалось воспроизвести «${sound.name}»: $e';
      notifyListeners();
    }
  }

  void setVolume(String id, double volume) {
    if (!isActive(id)) return;
    _active[id] = volume;
    _engine.setVolume(id, volume);
    notifyListeners();
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume;
    _engine.setMasterVolume(volume);
    _prefs.setDouble(_kMaster, volume);
    notifyListeners();
  }

  void setAccent(String key) {
    if (!Accents.all.containsKey(key)) return;
    _accent = key;
    _prefs.setString(_kAccent, key);
    notifyListeners();
  }

  void setLook(LookId look) {
    _look = look;
    _prefs.setString(_kLook, look.name);
    notifyListeners();
  }

  void togglePause() {
    _paused = !_paused;
    _engine.setPaused(_paused);
    notifyListeners();
  }

  void _resumeIfPaused() {
    if (!_paused) return;
    _paused = false;
    _engine.setPaused(false);
  }

  void stopAll() {
    _active.clear();
    _engine.stopAll();
    _paused = false;
    cancelSleepTimer();
    notifyListeners();
  }

  // ---------- Сеты ----------

  Future<void> applySet(SoundSet set) async {
    for (final id in _active.keys.toList()) {
      if (!set.volumes.containsKey(id)) {
        _active.remove(id);
        _engine.stop(id);
      }
    }
    final futures = <Future<void>>[];
    for (final MapEntry(key: id, value: volume) in set.volumes.entries) {
      final sound = soundById(id);
      if (sound == null) continue; // звук удалён
      if (isActive(id)) {
        setVolume(id, volume);
      } else {
        futures.add(_start(sound, volume));
      }
    }
    _resumeIfPaused();
    notifyListeners();
    await Future.wait(futures);
  }

  /// Сет считается включённым, если текущий микс совпадает с ним по составу.
  bool isSetActive(SoundSet set) =>
      _active.length == set.volumes.length && set.volumes.keys.every(_active.containsKey);

  Future<void> saveCurrentAsSet(String name) async {
    _customSets.add(
      SoundSet(
        id: 'set_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        volumes: Map.of(_active),
      ),
    );
    notifyListeners();
    await _persistSets();
  }

  Future<void> deleteSet(SoundSet set) async {
    _customSets.removeWhere((s) => s.id == set.id);
    notifyListeners();
    await _persistSets();
  }

  Future<void> _persistSets() =>
      _prefs.setString(_kCustomSets, jsonEncode(_customSets.map((s) => s.toJson()).toList()));

  // ---------- Свои звуки ----------

  /// Копирует файл в папку приложения ([folder]) и возвращает новый путь.
  /// В имя входит время, чтобы замена картинки не попадала в старый кэш.
  Future<String> _copyIn(String sourcePath, String folder, String id) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/$folder');
    await dir.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.substring(sourcePath.lastIndexOf('.')) : '';
    final copy = await File(sourcePath)
        .copy('${dir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}$ext');
    return copy.path;
  }

  /// Добавляет свой звук: аудио и (необязательно) картинку копирует в папку приложения.
  Future<void> addSound({
    required String name,
    required String audioPath,
    String? imagePath,
    ArtPlacement art = const ArtPlacement(),
  }) async {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    _customSounds.add(
      Sound.custom(
        id: id,
        name: name,
        path: await _copyIn(audioPath, 'sounds', id),
        imagePath: imagePath == null ? null : await _copyIn(imagePath, 'images', id),
        art: art,
      ),
    );
    notifyListeners();
    await _persistSounds();
  }

  /// Меняет свой звук. [audioPath] и [imagePath] — новые файлы, если их выбрали заново.
  Future<void> updateSound(
    Sound sound, {
    required String name,
    String? audioPath,
    String? imagePath,
    required ArtPlacement art,
  }) async {
    final index = _customSounds.indexWhere((s) => s.id == sound.id);
    if (index < 0) return;

    var updated = sound.copyWith(name: name, art: art);
    if (imagePath != null) {
      updated = updated.copyWith(imagePath: await _copyIn(imagePath, 'images', sound.id));
      final old = sound.imagePath;
      if (old != null) {
        ArtSources.evict(old);
        _deleteQuietly(old);
      }
    }
    if (audioPath != null) {
      updated = updated.copyWith(path: await _copyIn(audioPath, 'sounds', sound.id));
      final volume = _active[sound.id];
      await _engine.forget(sound.id);
      _deleteQuietly(sound.path);
      _customSounds[index] = updated;
      if (volume != null) {
        _active.remove(sound.id);
        await _start(updated, volume);
      }
    }
    _customSounds[index] = updated;
    notifyListeners();
    await _persistSounds();
  }

  void _deleteQuietly(String path) => File(path).delete().ignore();

  Future<void> deleteSound(Sound sound) async {
    if (!sound.isCustom) return;
    _active.remove(sound.id);
    await _engine.forget(sound.id);
    _customSounds.removeWhere((s) => s.id == sound.id);
    for (var i = 0; i < _customSets.length; i++) {
      final set = _customSets[i];
      if (set.volumes.containsKey(sound.id)) {
        _customSets[i] = SoundSet(
          id: set.id,
          name: set.name,
          volumes: Map.of(set.volumes)..remove(sound.id),
        );
      }
    }
    _customSets.removeWhere((s) => s.volumes.isEmpty);
    notifyListeners();
    await _persistSounds();
    await _persistSets();
    _deleteQuietly(sound.path);
    final image = sound.imagePath;
    if (image != null) {
      ArtSources.evict(image);
      _deleteQuietly(image);
    }
  }

  Future<void> _persistSounds() =>
      _prefs.setString(_kCustomSounds, jsonEncode(_customSounds.map((s) => s.toJson()).toList()));

  // ---------- Таймер сна ----------

  static const _sleepFade = Duration(seconds: 15);

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _resumeIfPaused(); // на паузе затухание не идёт
      _engine.fadeOutAll(_sleepFade);
      _active.clear();
      _sleepAt = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}
