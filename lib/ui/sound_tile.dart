import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/art_sources.dart';
import '../art/ascii_art.dart';
import '../look/components.dart';
import '../look/look.dart';
import '../models.dart';

/// Карточка звука. Раскладка своя у каждого оформления, поведение общее:
/// нажатие включает/выключает, долгое нажатие (или правый клик) — редактирование.
class SoundTile extends StatelessWidget {
  const SoundTile({
    super.key,
    required this.sound,
    required this.index,
    required this.active,
    required this.volume,
    required this.onTap,
    required this.onVolume,
    this.onEdit,
  });

  final Sound sound;
  final int index;
  final bool active;
  final double volume;
  final VoidCallback onTap;
  final ValueChanged<double> onVolume;
  final VoidCallback? onEdit;

  String get number => index.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) => switch (Look.of(context).id) {
    LookId.ascii => _AsciiTile(this),
    LookId.retro => _RetroTile(this),
    LookId.neu => _NeuTile(this),
    LookId.air => _AirTile(this),
  };
}

/// Обложка с пропорциями оформления, вписанная в доступное место.
class _FittedCover extends StatelessWidget {
  const _FittedCover({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(aspectRatio: Look.of(context).coverAspect, child: child),
  );
}

// ---------- ASCII: обложка на весь фон, текст поверх, включённая карточка белая ----------

class _AsciiTile extends StatelessWidget {
  const _AsciiTile(this.tile);

  final SoundTile tile;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final active = tile.active;
    final bg = active ? const Color(0xFFF4F4F4) : look.surface;
    final fg = active ? Colors.black : look.text;

    return LookSurface(
      active: active,
      onTap: tile.onTap,
      onLongPress: tile.onEdit,
      child: Stack(
        children: [
          Positioned.fill(
            child: SoundCover(sound: tile.sound, active: active),
          ),
          // подложка под текстом, чтобы символы не мешали читать
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0, 0.32, 0.55, 0.84, 1],
                    colors: [
                      bg,
                      bg.withValues(alpha: 0.85),
                      bg.withValues(alpha: 0),
                      bg.withValues(alpha: 0),
                      bg.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 14,
            child: Text(
              tile.number,
              style: look.label(color: active ? Colors.black : look.textDim),
            ),
          ),
          if (active)
            Positioned(
              top: 15,
              right: 14,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: look.accent, shape: BoxShape.circle),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  look.t(tile.sound.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: look.label(color: fg, size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 20,
                  child: active
                      ? LookSlider(
                          value: tile.volume,
                          onChanged: tile.onVolume,
                          trackColor: const Color(0xFFBDBDBD),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Retro: пиксельная обложка в рамке, пиксельный шрифт, блоки громкости ----------

class _RetroTile extends StatelessWidget {
  const _RetroTile(this.tile);

  final SoundTile tile;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final active = tile.active;
    return LookSurface(
      active: active,
      onTap: tile.onTap,
      onLongPress: tile.onEdit,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FittedCover(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: active ? look.accent : look.textFaint, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: look.background,
                        child: SoundCover(sound: tile.sound, active: active),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        color: active ? look.accent : look.line,
                        padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
                        child: Text(
                          tile.number,
                          style: look.label(
                            size: 9,
                            color: active ? look.onAccent : look.background,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            look.t(tile.sound.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: look.label(size: 11, color: active ? look.accent : look.text),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: active
                ? LookSlider(value: tile.volume, onChanged: tile.onVolume, height: 14)
                : Text('▶ PLAY', style: look.label(size: 9, color: look.textFaint)),
          ),
        ],
      ),
    );
  }
}

// ---------- Neumorphism: мягкие выпуклые карточки, включённая — «вдавлена» ----------

class _NeuTile extends StatelessWidget {
  const _NeuTile(this.tile);

  final SoundTile tile;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final active = tile.active;
    return LookSurface(
      active: active,
      onTap: tile.onTap,
      onLongPress: tile.onEdit,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FittedCover(
              child: LayoutBuilder(
                builder: (context, c) => ClipRRect(
                  borderRadius: BorderRadius.circular(look.coverRadius(c.maxWidth)),
                  child: SoundCover(sound: tile.sound, active: active),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  tile.sound.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: look.label(size: 14, weight: FontWeight.w700, color: look.text),
                ),
              ),
              if (active) PlayingBars(active: true, height: 11),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            child: active
                ? LookSlider(value: tile.volume, onChanged: tile.onVolume, height: 22)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Выключен', style: look.label(size: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- Air: стекло, размытая обложка фоном, «альбомная» обложка, как в iOS ----------

class _AirTile extends StatelessWidget {
  const _AirTile(this.tile);

  final SoundTile tile;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final active = tile.active;
    final path = tile.sound.imagePath;

    return LookSurface(
      active: active,
      onTap: tile.onTap,
      onLongPress: tile.onEdit,
      child: Stack(
        children: [
          if (path != null)
            Positioned.fill(
              child: _AirBackdrop(path: path, sound: tile.sound),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FittedCover(
                    child: LayoutBuilder(
                      builder: (context, c) => DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(look.coverRadius(c.maxWidth)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(look.coverRadius(c.maxWidth)),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SoundCover(sound: tile.sound, active: active),
                              ),
                              // громкость — «стеклянная» плашка поверх обложки
                              if (active)
                                Positioned(
                                  left: 6,
                                  right: 6,
                                  bottom: 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: LookSlider(
                                          value: tile.volume,
                                          onChanged: tile.onVolume,
                                          height: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tile.sound.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: look.label(size: 14, weight: FontWeight.w600, color: look.text),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    PlayingBars(active: active, height: 10),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        active ? 'Играет · ${(tile.volume * 100).round()}%' : 'Выкл.',
                        maxLines: 1,
                        style: look.label(size: 12, color: active ? look.accent : look.textDim),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Размытая обложка на фоне карточки — как подложка виджета «Сейчас играет».
class _AirBackdrop extends StatelessWidget {
  const _AirBackdrop({required this.path, required this.sound});

  final String path;
  final Sound sound;

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: ArtSources.file(path),
    builder: (context, snapshot) {
      final image = snapshot.data;
      if (image == null) return const SizedBox.expand();
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.mirror),
            child: PlacedImage(image: image, placement: sound.art),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
        ],
      );
    },
  );
}

class AddSoundTile extends StatelessWidget {
  const AddSoundTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final plus = switch (look.id) {
      LookId.ascii => Text('+', style: look.display(52, color: look.accent)),
      LookId.retro => Text('+', style: look.display(40, color: look.accent)),
      _ => Icon(Icons.add_rounded, size: 40, color: look.accent),
    };
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        plus,
        const SizedBox(height: 10),
        Text(
          look.t('Свой звук'),
          textAlign: TextAlign.center,
          style: look.label(color: look.text, size: 12, weight: FontWeight.w600),
        ),
      ],
    );

    // в ASCII и Retro — пунктирная «пустая» ячейка, в остальных — обычная карточка
    if (look.id == LookId.ascii || look.id == LookId.retro) {
      final shape = look.id == LookId.retro
          ? BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: look.textFaint, width: 2),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(look.radius),
              side: BorderSide(color: look.line, width: 1.5),
            );
      return Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      );
    }
    return LookSurface(onTap: onTap, child: content);
  }
}
