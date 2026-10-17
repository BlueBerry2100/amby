import 'package:flutter/material.dart';

import '../look/look.dart';

/// Ползунок в виде ряда точек: заполненная часть — вертикальные штрихи акцентного цвета.
class DotSlider extends StatelessWidget {
  const DotSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
    this.trackColor = const Color(0xFF5A5A5A),
    this.height = 20,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final Color? color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Look.of(context).accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        void update(Offset local) => onChanged((local.dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition),
          onHorizontalDragStart: (d) => update(d.localPosition),
          onHorizontalDragUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: _DotsPainter(value, color, trackColor)),
          ),
        );
      },
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.value, this.color, this.trackColor);

  final double value;
  final Color color;
  final Color trackColor;

  static const _pitch = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final count = (size.width / _pitch).floor().clamp(2, 200);
    final step = (size.width - 3) / (count - 1);
    final filled = (value * count).round();
    final paint = Paint()..isAntiAlias = true;
    final mid = size.height / 2;

    for (var i = 0; i < count; i++) {
      final x = 1.5 + i * step;
      if (i < filled) {
        // штрихи растут к концу заполненной части, как эквалайзер
        final h = size.height * (0.45 + 0.55 * (i + 1) / count);
        paint.color = color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, mid), width: 3, height: h),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        paint.color = trackColor;
        canvas.drawCircle(Offset(x, mid), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}
