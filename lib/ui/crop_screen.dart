import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../look/components.dart';
import '../look/look.dart';
import '../models.dart';

/// Кадрирование фото под карточку, как при выборе аватарки: фото двигается и
/// масштабируется под неподвижной рамкой-трафаретом. Возвращает [ArtPlacement].
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.imagePath, required this.initial});

  final String imagePath;
  final ArtPlacement initial;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late ArtPlacement _art = widget.initial;

  /// Фото в хорошем разрешении для кадрирования и уменьшенное — для ASCII-превью.
  ui.Image? _photo;

  Rect _frame = Rect.zero;
  double _gestureStartScale = 1;

  Size get _imageSize => Size(_photo!.width.toDouble(), _photo!.height.toDouble());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1600);
    final photo = (await codec.getNextFrame()).image;
    if (!mounted) return;
    setState(() => _photo = photo);
  }

  @override
  void dispose() {
    _photo?.dispose();
    super.dispose();
  }

  /// Рамка пропорций обложки текущего оформления, вписанная в область просмотра.
  Rect _frameIn(Size viewport, double aspect) {
    const pad = 28.0;
    final w = math.min(viewport.width - pad * 2, (viewport.height - pad * 2) * aspect);
    return Rect.fromCenter(center: viewport.center(Offset.zero), width: w, height: w / aspect);
  }

  void _zoomAt(double scale, Offset focal) => setState(() {
    _art = _art.zoomedAt(scale, focal - _frame.topLeft, _frame.size, _imageSize);
  });

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    final look = Look.of(context);
    return LookBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(look.t('Кадр')),
          actions: [
            TextButton(
              onPressed: photo == null
                  ? null
                  : () => setState(() => _art = _art.copyWith(scale: 1, dx: 0, dy: 0)),
              child: Text(look.t('Сбросить')),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: photo == null
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          _frame = _frameIn(constraints.biggest, look.coverAspect);
                          return Listener(
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent) {
                                _zoomAt(
                                  _art.scale * math.exp(-event.scrollDelta.dy / 400),
                                  event.localPosition,
                                );
                              }
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: (_) => _gestureStartScale = _art.scale,
                              onScaleUpdate: (d) => setState(() {
                                _art = _art.panned(d.focalPointDelta, _frame.size, _imageSize);
                                if (d.pointerCount > 1) {
                                  _art = _art.zoomedAt(
                                    _gestureStartScale * d.scale,
                                    d.localFocalPoint - _frame.topLeft,
                                    _frame.size,
                                    _imageSize,
                                  );
                                }
                              }),
                              onDoubleTapDown: (d) =>
                                  _zoomAt(_art.scale < 2 ? _art.scale * 2 : 1, d.localPosition),
                              onDoubleTap: () {},
                              child: CustomPaint(
                                size: constraints.biggest,
                                painter: _CropPainter(
                                  photo: photo,
                                  art: _art,
                                  frame: _frame,
                                  look: look,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final look = Look.of(context);
    // превью в стиле текущего оформления: так фото будет выглядеть на карточке
    final preview = Sound(
      id: 'crop',
      name: '',
      path: '',
      isAsset: false,
      imagePath: widget.imagePath,
      art: _art,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72 / look.coverAspect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(look.coverRadius(72)),
                    child: ColoredBox(
                      color: look.surface,
                      child: SoundCover(sound: preview, active: false),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(look.t('Масштаб'), style: look.label(size: 12)),
                          const Spacer(),
                          Text(
                            '×${_art.scale.toStringAsFixed(1)}',
                            style: look.label(color: look.text, size: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LookSlider(
                        value:
                            (_art.scale - ArtPlacement.minScale) /
                            (ArtPlacement.maxScale - ArtPlacement.minScale),
                        onChanged: _photo == null
                            ? (_) {}
                            : (v) => _zoomAt(
                                ArtPlacement.minScale +
                                    v * (ArtPlacement.maxScale - ArtPlacement.minScale),
                                _frame.center,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        look.t('Двигайте фото. Масштаб — щипком, колесом или двойным нажатием.'),
                        style: look.label(color: look.textFaint, size: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    onPressed: () => Navigator.pop(context),
                    child: Text(look.t('Отмена')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _photo == null ? null : () => Navigator.pop(context, _art),
                    child: Text(look.t('Готово')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({required this.photo, required this.art, required this.frame, required this.look});

  final ui.Image photo;
  final ArtPlacement art;
  final Rect frame;
  final Look look;

  @override
  void paint(Canvas canvas, Size size) {
    // увеличенное фото не должно залезать на панель управления
    canvas.clipRect(Offset.zero & size);
    final image = Size(photo.width.toDouble(), photo.height.toDouble());

    // фото в том же масштабе, в каком его увидит шейдер: рамка = видимый кадр
    final region = art.visibleRegion(frame.size, image);
    final shown = Size(frame.width / region.width, frame.height / region.height);
    final c = art.center(frame.size, image);
    final topLeft = frame.center - Offset(c.dx * shown.width, c.dy * shown.height);
    canvas.drawImageRect(
      photo,
      Offset.zero & image,
      topLeft & shown,
      Paint()..filterQuality = FilterQuality.medium,
    );

    // затемнение вокруг трафарета
    final card = RRect.fromRectAndRadius(frame, Radius.circular(look.coverRadius(frame.width)));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(card),
      Paint()..color = look.background.withValues(alpha: 0.8),
    );

    // контур рамки и сетка третей
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = look.text;
    canvas.drawRRect(card, line);
    final grid = Paint()
      ..strokeWidth = 1
      ..color = look.text.withValues(alpha: 0.18);
    for (var i = 1; i < 3; i++) {
      final x = frame.left + frame.width * i / 3;
      final y = frame.top + frame.height * i / 3;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), grid);
      canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), grid);
    }

    // акцентные уголки, как в видоискателе
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = look.accent;
    const len = 18.0, out = 10.0;
    final r = frame.inflate(out);
    for (final (p, sx, sy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy + sy * len)
          ..lineTo(p.dx, p.dy)
          ..lineTo(p.dx + sx * len, p.dy),
        corner,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.photo != photo || old.art != art || old.frame != frame || old.look != look;
}
