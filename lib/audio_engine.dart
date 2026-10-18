import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'models.dart';

/// Тонкая обёртка над SoLoud: каждый активный звук — отдельный зацикленный голос
/// со своей громкостью. Микширование делает сам SoLoud.
class AudioEngine {
  final SoLoud _soloud = SoLoud.instance;
  final Map<String, Future<AudioSource>> _sources = {};
  final Map<String, SoundHandle> _handles = {};

  static const fade = Duration(milliseconds: 600);

  Future<void> init() async {
    if (_soloud.isInitialized) return;
    if (defaultTargetPlatform == TargetPlatform.linux) {
      // Через ALSA звук идёт в PipeWire-клиент прямо в нашем процессе, а его RT-модуль
      // без rtkit ставит RLIMIT_RTTIME = 0, и ядро убивает приложение SIGKILL'ом.
      // PulseAudio (pipewire-pulse) держит realtime-потоки на стороне сервера.
      try {
        await _soloud.init(linuxAudioBackend: LinuxAudioBackend.pulseAudio);
        return;
      } catch (_) {
        // нет PulseAudio/pipewire-pulse — пусть miniaudio выберет сам
      }
    }
    await _soloud.init();
  }

  /// Слайдер линейный, а слух — логарифмический; квадрат даёт более ровную шкалу.
  static double _gain(double v) => v * v;

  Future<AudioSource> _load(Sound sound) => _sources[sound.id] ??=
      (sound.isAsset ? _soloud.loadAsset(sound.path) : _soloud.loadFile(sound.path)).catchError((
        Object e,
      ) {
        _sources.remove(sound.id);
        throw e;
      });

  bool isPlaying(String id) => _handles.containsKey(id);

  Future<void> start(Sound sound, double volume) async {
    if (_handles.containsKey(sound.id)) return;
    final source = await _load(sound);
    if (_handles.containsKey(sound.id)) return; // запустили параллельно, пока грузилось
    final handle = _soloud.play(source, volume: 0, looping: true);
    _handles[sound.id] = handle;
    _soloud.fadeVolume(handle, _gain(volume), fade);
  }

  void stop(String id) {
    final handle = _handles.remove(id);
    if (handle == null) return;
    _soloud.fadeVolume(handle, 0, fade);
    _soloud.scheduleStop(handle, fade);
  }

  void stopAll() => _handles.keys.toList().forEach(stop);

  void setVolume(String id, double volume) {
    final handle = _handles[id];
    if (handle != null) _soloud.setVolume(handle, _gain(volume));
  }

  void setMasterVolume(double volume) => _soloud.setGlobalVolume(_gain(volume));

  void setPaused(bool paused) {
    for (final handle in _handles.values) {
      _soloud.setPause(handle, paused);
    }
  }

  /// Плавно гасит все звуки за [duration] и останавливает их.
  void fadeOutAll(Duration duration) {
    for (final handle in _handles.values) {
      _soloud.fadeVolume(handle, 0, duration);
      _soloud.scheduleStop(handle, duration);
    }
    _handles.clear();
  }

  Future<void> forget(String id) async {
    stop(id);
    final pending = _sources.remove(id);
    if (pending == null) return;
    try {
      await _soloud.disposeSource(await pending);
    } catch (_) {
      // источник так и не загрузился — освобождать нечего
    }
  }
}
