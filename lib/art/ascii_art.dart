import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models.dart';

/// Шейдеры обложек и атлас глифов — грузятся один раз при старте.
class ArtShaders {
  static late ui.FragmentProgram ascii;
  static late ui.FragmentProgram pixel;
  static late ui.Image glyphs;

  /// Символы ASCII-шейдера от «пустого» к «плотному».
  static const ramp = ' .:-=+*#%@';

  /// Ширина символа моноширинного шрифта относительно высоты.
  static const glyphAspect = 0.6;

  static Future<void> load() async {
    ascii = await ui.FragmentProgram.fromAsset('shaders/ascii.frag');
    pixel = await ui.FragmentProgram.fromAsset('shaders/pixel.frag');
    glyphs = await _buildAtlas();
  }

  static Future<ui.Image> _buildAtlas() async {
    const cellH = 50.0, cellW = cellH * glyphAspect;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var i = 0; i < ramp.length; i++) {
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: ramp[i],
          style: const TextStyle(
            fontFamily: 'PlexMono',
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      )..layout();
      tp.paint(canvas, Offset(i * cellW + (cellW - tp.width) / 2, (cellH - tp.height) / 2));
    }
    return recorder.endRecording().toImage((cellW * ramp.length).ceil(), cellH.toInt());
  }
}

/// Значения uniform-переменных шейдера для области [size] в момент [time].
typedef ShaderUniforms = List<double> Function(Size size, double time);

/// Общая обвязка для шейдерных обложек: создаёт шейдер, при [animate] гоняет время,
/// перерисовывается, когда меняется [config] (любой сравнимый набор параметров).
class ShaderArt extends StatefulWidget {
  const ShaderArt({
    super.key,
    required this.program,
    required this.samplers,
    required this.uniforms,
    required this.config,
    this.animate = false,
  });

  final ui.FragmentProgram program;
  final List<ui.Image> samplers;
  final ShaderUniforms uniforms;
  final Object config;
  final bool animate;

  @override
  State<ShaderArt> createState() => _ShaderArtState();
}

class _ShaderArtState extends State<ShaderArt> with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) => _time.value = elapsed.inMicroseconds / 1e6);
  late final ui.FragmentShader _shader = widget.program.fragmentShader();

  @override
  void initState() {
    super.initState();
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(ShaderArt old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_ticker.isActive) _ticker.start();
    if (!widget.animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: CustomPaint(
      painter: _ShaderPainter(
        shader: _shader,
        time: _time,
        samplers: widget.samplers,
        uniforms: widget.uniforms,
        config: widget.config,
      ),
    ),
  );
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({
    required this.shader,
    required this.time,
    required this.samplers,
    required this.uniforms,
    required this.config,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  final List<ui.Image> samplers;
  final ShaderUniforms uniforms;
  final Object config;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final values = uniforms(size, time.value);
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    for (var i = 0; i < samplers.length; i++) {
      shader.setImageSampler(i, samplers[i]);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) =>
      old.config != config || !identical(old.samplers.first, samplers.first);
}

/// Uniform-переменные кадра, общие для обоих шейдеров.
List<double> _frame(Size size, ui.Image image, ArtPlacement p) => [
  image.width.toDouble(),
  image.height.toDouble(),
  p.dx,
  p.dy,
  p.scale,
];

/// Картинка, нарисованная ASCII-символами.
class AsciiArt extends StatelessWidget {
  const AsciiArt({
    super.key,
    required this.image,
    required this.placement,
    required this.color,
    this.invert = false,
    this.animate = false,
  });

  final ui.Image image;
  final ArtPlacement placement;
  final Color color;
  final bool invert;
  final bool animate;

  @override
  Widget build(BuildContext context) => ShaderArt(
    program: ArtShaders.ascii,
    samplers: [image, ArtShaders.glyphs],
    animate: animate,
    config: (placement, color, invert, animate),
    uniforms: (size, time) {
      // число колонок задаётся относительно ширины — превью и плитка выглядят одинаково
      final cellW = size.width / placement.columns;
      return [
        size.width, size.height,
        cellW, cellW / ArtShaders.glyphAspect,
        ..._frame(size, image, placement),
        ArtShaders.ramp.length.toDouble(),
        color.r, color.g, color.b, color.a,
        time,
        animate ? 1 : 0,
        1.2, // контраст
        invert ? 1 : 0,
      ];
    },
  );
}

/// Картинка крупными пикселями с ограниченной палитрой и дизерингом.
class PixelArt extends StatelessWidget {
  const PixelArt({
    super.key,
    required this.image,
    required this.placement,
    this.tint,
    this.animate = false,
    this.levels = 4,
  });

  final ui.Image image;
  final ArtPlacement placement;

  /// Если задан — одноцветный режим (для иконок).
  final Color? tint;
  final bool animate;
  final double levels;

  @override
  Widget build(BuildContext context) => ShaderArt(
    program: ArtShaders.pixel,
    samplers: [image],
    animate: animate,
    config: (placement, tint, animate, levels),
    uniforms: (size, time) {
      // те же «колонки», что и у ASCII, но пиксели квадратные и чуть крупнее
      final cell = size.width / (placement.columns * 0.8);
      final tint = this.tint ?? Colors.white;
      return [
        size.width, size.height,
        cell, cell,
        ..._frame(size, image, placement),
        levels,
        this.tint == null ? 0 : 1,
        tint.r, tint.g, tint.b, tint.a,
        time,
        animate ? 1 : 0,
        1, // сетка между пикселями
      ];
    },
  );
}

/// Обычная (не шейдерная) картинка в кадре [placement] — для Neumorphism и Air.
class PlacedImage extends StatelessWidget {
  const PlacedImage({super.key, required this.image, required this.placement});

  final ui.Image image;
  final ArtPlacement placement;

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: CustomPaint(painter: _PlacedImagePainter(image, placement)));
}

class _PlacedImagePainter extends CustomPainter {
  _PlacedImagePainter(this.image, this.placement);

  final ui.Image image;
  final ArtPlacement placement;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final region = placement.visibleRegion(size, imageSize);
    final c = placement.center(size, imageSize);
    final src = Rect.fromCenter(
      center: Offset(c.dx * imageSize.width, c.dy * imageSize.height),
      width: region.width * imageSize.width,
      height: region.height * imageSize.height,
    );
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PlacedImagePainter old) => old.image != image || old.placement != placement;
}
