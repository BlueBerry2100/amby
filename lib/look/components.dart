import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/art_sources.dart';
import '../art/ascii_art.dart';
import '../models.dart';
import '../ui/dot_slider.dart';
import 'look.dart';

// Базовые компоненты, которые выглядят по-разному в каждом оформлении.

const _neuLight = Color(0xFFFFFFFF);
const _neuDark = Color(0xFFA3B1C6);

List<BoxShadow> _neuRaised([double d = 6]) => [
  BoxShadow(color: _neuLight.withValues(alpha: 0.9), offset: Offset(-d, -d), blurRadius: d * 2.3),
  BoxShadow(color: _neuDark.withValues(alpha: 0.7), offset: Offset(d, d), blurRadius: d * 2.3),
];

/// «Вдавленная» поверхность неоморфизма — Flutter не умеет внутренние тени,
/// поэтому имитируем их градиентом от тёмного угла к светлому.
const _neuPressed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFCFD6E1), Color(0xFFE4E9F0), Color(0xFFF2F5F9)],
  stops: [0, 0.45, 1],
);

/// Фон экрана.
class LookBackground extends StatelessWidget {
  const LookBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    return switch (look.id) {
      LookId.ascii || LookId.neu => ColoredBox(color: look.background, child: child),
      LookId.retro => CustomPaint(painter: _PixelGridPainter(look), child: child),
      LookId.air => DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            // мягкое свечение акцентом, как в iOS-приложениях
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, -1.1),
                    radius: 1.3,
                    colors: [look.accent.withValues(alpha: 0.55), look.accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.2, 1.1),
                    radius: 1.1,
                    colors: [look.accent.withValues(alpha: 0.22), look.accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    };
  }
}

class _PixelGridPainter extends CustomPainter {
  _PixelGridPainter(this.look);

  final Look look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = look.background);
    final dot = Paint()..color = look.text.withValues(alpha: 0.05);
    for (var y = 6.0; y < size.height; y += 14) {
      for (var x = 6.0; x < size.width; x += 14) {
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelGridPainter old) => old.look != look;
}

/// Карточка/поверхность. [active] — включённое состояние.
class LookSurface extends StatelessWidget {
  const LookSurface({
    super.key,
    required this.child,
    this.active = false,
    this.radius,
    this.color,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final bool active;
  final double? radius;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final r = radius ?? look.radius;
    final ShapeBorder shape = look.id == LookId.retro
        ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(math.min(r, 8)))
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

    final Decoration decoration = switch (look.id) {
      LookId.ascii => ShapeDecoration(
        color: color ?? (active ? const Color(0xFFF4F4F4) : look.surface),
        shape: shape,
      ),
      LookId.retro => ShapeDecoration(
        color: color ?? look.surface,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(math.min(r, 8)),
          side: BorderSide(color: active ? look.accent : look.line, width: 2),
        ),
        shadows: [
          BoxShadow(
            color: active ? look.accent.withValues(alpha: 0.85) : Colors.black,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      LookId.neu => BoxDecoration(
        color: color ?? look.background,
        borderRadius: BorderRadius.circular(r),
        gradient: active && color == null ? _neuPressed : null,
        boxShadow: active ? null : _neuRaised(),
      ),
      LookId.air => BoxDecoration(
        color: color ?? (active ? look.surfaceHigh : look.surface.withValues(alpha: 0.88)),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: active
              ? look.accent.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: look.accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onLongPress,
          customBorder: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Круглая (в Retro — со скошенными углами) кнопка-иконка.
class LookIconButton extends StatelessWidget {
  const LookIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.filled = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final fg = filled ? look.onAccent : (selected ? look.accent : look.text);
    final Color? bg = filled
        ? look.accent
        : switch (look.id) {
            LookId.neu => null,
            LookId.air => Colors.white.withValues(alpha: 0.1),
            _ => look.surfaceHigh,
          };
    final button = SizedBox.square(
      dimension: size,
      child: LookSurface(
        radius: size / 2,
        color: bg,
        onTap: onPressed,
        child: Center(
          child: Icon(icon, size: size * 0.46, color: fg),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Ползунок громкости в стиле оформления.
class LookSlider extends StatelessWidget {
  const LookSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 20,
    this.trackColor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double height;

  /// Цвет «пустой» части (нужен, например, на белой карточке ASCII).
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    if (look.id == LookId.ascii) {
      return DotSlider(
        value: value,
        onChanged: onChanged,
        height: height,
        color: look.accent,
        trackColor: trackColor ?? look.textFaint,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        void update(Offset local) => onChanged((local.dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition),
          onHorizontalDragStart: (d) => update(d.localPosition),
          onHorizontalDragUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            height: math.max(height, look.id == LookId.neu ? 26 : height),
            width: double.infinity,
            child: CustomPaint(painter: _SliderPainter(look, value, trackColor)),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(this.look, this.value, this.trackColor);

  final Look look;
  final double value;
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    switch (look.id) {
      case LookId.retro:
        // ряд «пиксельных» блоков
        const step = 9.0;
        final count = (size.width / step).floor().clamp(2, 100);
        final filled = (value * count).round();
        final h = math.min(size.height * 0.75, 12.0);
        final fill = Paint()
          ..color = look.accent
          ..isAntiAlias = false;
        final empty = Paint()
          ..color = (trackColor ?? look.textFaint)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = false;
        for (var i = 0; i < count; i++) {
          final rect = Rect.fromLTWH(i * step, mid - h / 2, step - 3, h);
          canvas.drawRect(i < filled ? rect : rect.deflate(0.75), i < filled ? fill : empty);
        }
      case LookId.neu:
        const th = 12.0;
        final track = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, mid - th / 2, size.width, th),
          const Radius.circular(th / 2),
        );
        canvas.drawRRect(
          track,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC8D0DC), Color(0xFFEEF2F7)],
            ).createShader(track.outerRect),
        );
        final x = (size.width * value).clamp(th / 2, size.width - th / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, mid - th / 2, x, th),
            const Radius.circular(th / 2),
          ),
          Paint()
            ..shader = LinearGradient(
              colors: [Color.lerp(look.accent, Colors.white, 0.35)!, look.accent],
            ).createShader(Rect.fromLTWH(0, 0, math.max(x, 1), size.height)),
        );
        // выпуклая ручка
        const r = 11.0;
        final c = Offset(x, mid);
        final blur = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(
          c + const Offset(2.5, 2.5),
          r,
          blur..color = _neuDark.withValues(alpha: 0.8),
        );
        canvas.drawCircle(c - const Offset(2.5, 2.5), r, blur..color = _neuLight);
        canvas.drawCircle(c, r, Paint()..color = look.background);
        canvas.drawCircle(c, 4, Paint()..color = look.accent);
      case LookId.air:
      case LookId.ascii:
        const th = 6.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, mid - th / 2, size.width, th),
            const Radius.circular(th / 2),
          ),
          Paint()..color = trackColor ?? Colors.white.withValues(alpha: 0.2),
        );
        final w = size.width * value;
        if (w > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, mid - th / 2, w, th),
              const Radius.circular(th / 2),
            ),
            Paint()..color = look.accent,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.value != value || old.look != look || old.trackColor != trackColor;
}

/// Переключатель вкладок.
class LookTabs extends StatelessWidget {
  const LookTabs({super.key, required this.index, required this.labels, required this.onChanged});

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final pillRadius = look.id == LookId.retro ? 4.0 : 22.0;

    Decoration? selected() => switch (look.id) {
      LookId.ascii => BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(pillRadius),
      ),
      LookId.retro => BoxDecoration(
        color: look.accent,
        borderRadius: BorderRadius.circular(pillRadius),
      ),
      LookId.neu => BoxDecoration(
        gradient: _neuPressed,
        borderRadius: BorderRadius.circular(pillRadius),
      ),
      LookId.air => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(pillRadius),
      ),
    };
    Color selectedText() => switch (look.id) {
      LookId.ascii => Colors.black,
      LookId.retro => look.onAccent,
      LookId.neu => look.accent,
      LookId.air => look.text,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: LookSurface(
        radius: look.id == LookId.retro ? 6 : 26,
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: i == index ? selected() : null,
                      child: Text(
                        look.t(label),
                        style: look.label(
                          color: i == index ? selectedText() : look.textDim,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Боковая панель (сеты на широком экране).
class LookPanel extends StatelessWidget {
  const LookPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final r = look.id == LookId.retro ? 6.0 : 30.0;
    return DecoratedBox(
      decoration: switch (look.id) {
        LookId.neu => BoxDecoration(gradient: _neuPressed, borderRadius: BorderRadius.circular(r)),
        LookId.air => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        _ => BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: look.id == LookId.retro ? look.line : look.line,
            width: look.id == LookId.retro ? 2 : 1.5,
          ),
        ),
      },
      child: child,
    );
  }
}

/// Обложка звука в стиле оформления: ASCII, пиксели, обычное фото или «альбомная» обложка.
class SoundCover extends StatelessWidget {
  const SoundCover({super.key, required this.sound, required this.active});

  final Sound sound;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final path = sound.imagePath;

    // в Neumorphism и Air иконки рисуются обычным Icon — так чётче
    if (path == null && look.id == LookId.neu) {
      return _NeuIconCover(icon: sound.icon, active: active);
    }
    if (path == null && look.id == LookId.air) {
      return _AirIconCover(icon: sound.icon, active: active);
    }

    return FutureBuilder<ui.Image>(
      future: path != null ? ArtSources.file(path) : ArtSources.icon(sound.icon),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) return const SizedBox.expand();
        return switch (look.id) {
          LookId.ascii => AsciiArt(
            image: image,
            placement: sound.art,
            color: active ? Colors.black : const Color(0xFF6E6E6E),
            // у иконок фон пустой — инверсия залила бы всю карточку
            invert: active && path != null,
            animate: active,
          ),
          LookId.retro => PixelArt(
            image: image,
            placement: sound.art,
            tint: path == null ? (active ? look.accent : look.text) : null,
            animate: active,
          ),
          LookId.neu || LookId.air => PlacedImage(image: image, placement: sound.art),
        };
      },
    );
  }
}

class _NeuIconCover extends StatelessWidget {
  const _NeuIconCover({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final d = math.min(c.maxWidth, c.maxHeight) * 0.62;
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: look.background,
              gradient: active ? _neuPressed : null,
              boxShadow: active ? null : _neuRaised(4),
            ),
            child: Icon(icon, size: d * 0.45, color: active ? look.accent : look.textDim),
          ),
        );
      },
    );
  }
}

/// Обложка в духе Apple Music: градиент от акцентного цвета и белая иконка.
class _AirIconCover extends StatelessWidget {
  const _AirIconCover({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final hsl = HSLColor.fromColor(look.accent);
    final light = hsl.withLightness((hsl.lightness + 0.18).clamp(0, 0.85)).toColor();
    final shifted = hsl.withHue((hsl.hue + 40) % 360).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [light, look.accent, shifted]
              : const [Color(0xFF3A3A3C), Color(0xFF242426)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Center(
          child: Icon(
            icon,
            size: c.maxWidth * 0.36,
            color: Colors.white.withValues(alpha: active ? 1 : 0.7),
          ),
        ),
      ),
    );
  }
}

/// Анимированный индикатор «играет» — прыгающие столбики, как в Dynamic Island.
class PlayingBars extends StatefulWidget {
  const PlayingBars({super.key, required this.active, this.color, this.height = 12});

  final bool active;
  final Color? color;
  final double height;

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(PlayingBars old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Look.of(context).accent;
    return SizedBox(
      width: widget.height * 1.4,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _BarsPainter(
            _c.value,
            widget.active ? color : color.withValues(alpha: 0.4),
            widget.active,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, this.color, this.active);

  final double t;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final w = size.width / (n * 1.8);
    final paint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final phase = t * 2 * math.pi + i * 1.7;
      final h = active
          ? size.height * (0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase)).abs())
          : size.height * 0.3;
      final x = i * w * 1.8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, w, h), Radius.circular(w / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.color != color || old.active != active;
}
