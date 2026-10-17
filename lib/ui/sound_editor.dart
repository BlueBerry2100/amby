import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../look/components.dart';
import '../look/look.dart';
import '../models.dart';
import 'crop_screen.dart';
import 'sound_tile.dart';

/// Создание или изменение своего звука: аудиофайл, картинка и её кадр на карточке.
class SoundEditorScreen extends StatefulWidget {
  const SoundEditorScreen({super.key, required this.state, this.sound});

  final AppState state;

  /// null — новый звук.
  final Sound? sound;

  @override
  State<SoundEditorScreen> createState() => _SoundEditorScreenState();
}

class _SoundEditorScreenState extends State<SoundEditorScreen> {
  late final _name = TextEditingController(text: widget.sound?.name ?? '');

  /// Новые файлы, выбранные в этом редакторе (null — оставить как было).
  String? _audioPath;
  String? _imagePath;

  late ArtPlacement _art = widget.sound?.art ?? const ArtPlacement(columns: 26);
  bool _previewActive = false;
  bool _saving = false;

  bool get _isNew => widget.sound == null;
  String? get _currentImage => _imagePath ?? widget.sound?.imagePath;
  bool get _canSave => !_saving && _name.text.trim().isNotEmpty && (_audioPath != null || !_isNew);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final file = await FilePicker.pickFile(type: FileType.audio, dialogTitle: 'Выберите аудиофайл');
    final path = file?.path;
    if (path == null) return;
    setState(() {
      _audioPath = path;
      if (_name.text.trim().isEmpty) {
        _name.text = file!.name.contains('.')
            ? file.name.substring(0, file.name.lastIndexOf('.'))
            : file.name;
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image, dialogTitle: 'Выберите картинку');
    final path = file?.path;
    if (path == null || !mounted) return;
    // сразу кадрируем; отмена кадрирования отменяет и выбор фото
    final art = await _crop(path, _art.copyWith(scale: 1, dx: 0, dy: 0));
    if (art == null) return;
    setState(() {
      _imagePath = path;
      _art = art;
    });
  }

  Future<ArtPlacement?> _crop(String path, ArtPlacement initial) => Navigator.of(context)
      .push<ArtPlacement>(
        MaterialPageRoute(
          builder: (_) => CropScreen(imagePath: path, initial: initial),
        ),
      );

  Future<void> _recrop() async {
    final path = _currentImage;
    if (path == null) return;
    final art = await _crop(path, _art);
    if (art != null && mounted) setState(() => _art = art);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final name = _name.text.trim();
    try {
      final sound = widget.sound;
      if (sound == null) {
        await widget.state.addSound(
          name: name,
          audioPath: _audioPath!,
          imagePath: _imagePath,
          art: _art,
        );
      } else {
        await widget.state.updateSound(
          sound,
          name: name,
          audioPath: _audioPath,
          imagePath: _imagePath,
          art: _art,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
    }
  }

  Future<void> _delete() async {
    final sound = widget.sound!;
    final look = Look.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(look.t('Удалить «${sound.name}»?')),
        content: const Text('Звук пропадёт из каталога и из своих сетов.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(look.t('Отмена'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(look.t('Удалить')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.state.deleteSound(sound);
    if (mounted) Navigator.pop(context);
  }

  // ---------- Превью ----------

  /// Номер, под которым звук стоит (или встанет) в сетке.
  int get _tileIndex {
    final sounds = widget.state.sounds;
    final i = sounds.indexWhere((s) => s.id == widget.sound?.id);
    return i < 0 ? sounds.length + 1 : i + 1;
  }

  /// Превью — та же карточка, что в сетке, в текущем оформлении.
  Widget _preview() {
    final look = Look.of(context);
    final name = _name.text.trim();
    final sound = Sound(
      id: widget.sound?.id ?? 'preview',
      name: name.isEmpty ? 'Без названия' : name,
      path: '',
      isAsset: false,
      icon: widget.sound?.icon ?? Icons.graphic_eq,
      imagePath: _currentImage,
      art: _art,
    );
    return AspectRatio(
      aspectRatio: look.tileAspect,
      child: SoundTile(
        sound: sound,
        index: _tileIndex,
        active: _previewActive,
        volume: 0.6,
        onTap: () => setState(() => _previewActive = !_previewActive),
        onVolume: (_) {},
      ),
    );
  }

  // ---------- Настройки ----------

  Widget _section(String title, Widget child, {String? value}) {
    final look = Look.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(look.t(title), style: look.label(size: 12)),
              const Spacer(),
              if (value != null) Text(look.t(value), style: look.label(color: look.text, size: 12)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _fileRow({
    required String value,
    required bool chosen,
    required VoidCallback onPick,
    Widget? extra,
  }) {
    final look = Look.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      decoration: BoxDecoration(
        color: look.surfaceHigh,
        borderRadius: BorderRadius.circular(look.id == LookId.retro ? 4 : 18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: look.label(color: chosen ? look.text : look.textDim, size: 12),
            ),
          ),
          if (extra != null) ...[extra, const SizedBox(width: 6)],
          OutlinedButton(onPressed: onPick, child: Text(look.t('Выбрать'))),
        ],
      ),
    );
  }

  String _fileName(String path) => path.split(RegExp(r'[/\\]')).last;

  Widget _controls() {
    final audio = _audioPath ?? widget.sound?.path;
    final image = _currentImage;
    final look = Look.of(context);
    final hasPhoto = image != null;
    // детализация есть только у шейдерных оформлений
    final hasDetail = look.id == LookId.ascii || look.id == LookId.retro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          'Название',
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: look.body(size: 15),
            decoration: InputDecoration(hintText: look.t('Например, костёр')),
          ),
        ),
        _section(
          'Звук',
          _fileRow(
            value: audio == null ? look.t('Файл не выбран') : _fileName(audio),
            chosen: audio != null,
            onPick: _pickAudio,
          ),
        ),
        _section(
          'Картинка',
          _fileRow(
            value: image == null ? look.t('Без картинки — иконка') : _fileName(image),
            chosen: image != null,
            onPick: _pickImage,
            extra: image == null
                ? null
                : OutlinedButton(onPressed: _recrop, child: Text(look.t('Кадр'))),
          ),
        ),
        if (hasDetail)
          _section(
            'Детализация',
            value: '${_art.columns.round()} ${look.id == LookId.ascii ? 'симв.' : 'пикс.'}',
            LookSlider(
              value:
                  (_art.columns - ArtPlacement.minColumns) /
                  (ArtPlacement.maxColumns - ArtPlacement.minColumns),
              onChanged: (v) => setState(
                () => _art = _art.copyWith(
                  columns:
                      ArtPlacement.minColumns +
                      v * (ArtPlacement.maxColumns - ArtPlacement.minColumns),
                ),
              ),
            ),
          ),
        Text(
          hasPhoto
              ? look.t(
                  '«Кадр» — подогнать масштаб и расположение фото. Нажатие на превью — вид включённой карточки.',
                )
              : look.t('Нажмите на превью, чтобы увидеть включённую карточку.'),
          style: look.label(color: look.textFaint, size: 11),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(look.t(_saving ? 'Сохраняю…' : 'Сохранить')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    return LookBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(look.t(_isNew ? 'Новый звук' : 'Изменить звук')),
          actions: [
            if (!_isNew)
              IconButton(
                tooltip: 'Удалить звук',
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 680) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: _preview()),
                          const SizedBox(width: 40),
                          Expanded(child: SingleChildScrollView(child: _controls())),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Center(
                        child: SizedBox(
                          width: math.min(260, constraints.maxWidth * 0.66),
                          child: _preview(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _controls(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
