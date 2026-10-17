import 'package:flutter/material.dart';

/// Варианты оформления приложения.
enum LookId {
  ascii('ASCII'),
  retro('Retro'),
  neu('Neumorphism'),
  air('Air');

  const LookId(this.title);
  final String title;
}

/// Акцентные цвета — общие для всех оформлений.
abstract final class Accents {
  static const defaultKey = 'red';
  static const all = <String, Color>{
    'red': Color(0xFFE8202E),
    'orange': Color(0xFFFF5A1F),
    'yellow': Color(0xFFFFC21A),
    'green': Color(0xFF22C770),
    'blue': Color(0xFF2F7BFF),
    'purple': Color(0xFF8C6BFF),
  };

  /// Цвет текста поверх [color].
  static Color on(Color color) =>
      color.computeLuminance() > 0.4 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

/// Токены оформления: цвета, шрифты, формы. Лежит в ThemeData как расширение,
/// виджеты берут его через [Look.of]. Сами компоненты под каждое оформление —
/// в look/components.dart и ui/sound_tile.dart.
@immutable
class Look extends ThemeExtension<Look> {
  const Look._({
    required this.id,
    required this.accent,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.radius,
    required this.coverAspect,
    required this.tileAspect,
    required this.displayFont,
    required this.bodyFont,
    required this.labelFont,
    required this.caps,
    this.displayVariations = const [],
    this.labelSpacing = 0,
    this.labelScale = 1,
  });

  final LookId id;
  final Color accent;
  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color line;
  final Color text;
  final Color textDim;
  final Color textFaint;

  /// Скругление карточек.
  final double radius;

  /// Пропорции обложки на карточке (ширина / высота) — по ним кадрируется фото.
  final double coverAspect;

  /// Пропорции карточки звука в сетке.
  final double tileAspect;

  final String displayFont;
  final String bodyFont;
  final String labelFont;
  final List<FontVariation> displayVariations;

  /// Подписи капсом (ASCII, Retro) или как написано (Neumorphism, Air).
  final bool caps;
  final double labelSpacing;

  /// Множитель размера подписей — пиксельный шрифт крупный, его уменьшаем.
  final double labelScale;

  Color get onAccent => Accents.on(accent);

  /// Цвет текста на включённой карточке (в ASCII она белая).
  Color get activeText => id == LookId.ascii ? const Color(0xFF000000) : text;
  bool get isDark => brightness == Brightness.dark;

  static Look of(BuildContext context) => Theme.of(context).extension<Look>()!;

  /// Текст в регистре оформления.
  String t(String s) => caps ? s.toUpperCase() : s;

  /// Крупные цифры и заголовки.
  TextStyle display(double size, {Color? color}) => TextStyle(
    fontFamily: displayFont,
    fontSize: id == LookId.retro ? size * 0.62 : size,
    height: 1,
    color: color ?? text,
    fontWeight: FontWeight.w800,
    letterSpacing: id == LookId.air ? -size * 0.03 : 0,
    fontVariations: displayVariations,
  );

  /// Подписи, названия, кнопки.
  TextStyle label({Color? color, double size = 11, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: labelFont,
        fontSize: size * labelScale,
        letterSpacing: labelSpacing,
        height: id == LookId.retro ? 1.5 : 1.25,
        color: color ?? textDim,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  /// Обычный текст (описания, поля ввода).
  TextStyle body({Color? color, double size = 14}) =>
      TextStyle(fontFamily: bodyFont, fontSize: size, height: 1.35, color: color ?? text);

  factory Look.build(LookId id, Color accent) => switch (id) {
    LookId.ascii => Look._(
      id: id,
      accent: accent,
      brightness: Brightness.dark,
      background: const Color(0xFF000000),
      surface: const Color(0xFF111111),
      surfaceHigh: const Color(0xFF1C1C1C),
      line: const Color(0xFF2A2A2A),
      text: const Color(0xFFF4F4F4),
      textDim: const Color(0xFF7C7C7C),
      textFaint: const Color(0xFF5A5A5A),
      radius: 24,
      coverAspect: 0.8,
      tileAspect: 0.8,
      displayFont: 'Doto',
      bodyFont: 'PlexMono',
      labelFont: 'PlexMono',
      caps: true,
      labelSpacing: 1.1,
      displayVariations: const [FontVariation('wght', 850), FontVariation('ROND', 100)],
    ),
    LookId.retro => Look._(
      id: id,
      accent: accent,
      brightness: Brightness.dark,
      background: const Color(0xFF14121F),
      surface: const Color(0xFF1F1C30),
      surfaceHigh: const Color(0xFF2B2742),
      line: const Color(0xFFEDE4D3),
      text: const Color(0xFFEDE4D3),
      textDim: const Color(0xFF9188AE),
      textFaint: const Color(0xFF5C5575),
      radius: 6,
      coverAspect: 1.3,
      tileAspect: 0.8,
      displayFont: 'PressStart2P',
      bodyFont: 'PlexMono',
      labelFont: 'PressStart2P',
      caps: true,
      labelScale: 0.78,
    ),
    LookId.neu => Look._(
      id: id,
      accent: accent,
      brightness: Brightness.light,
      background: const Color(0xFFE4E9F0),
      surface: const Color(0xFFE4E9F0),
      surfaceHigh: const Color(0xFFD9DFE8),
      line: const Color(0xFFC6CEDA),
      text: const Color(0xFF2B3240),
      textDim: const Color(0xFF7B8596),
      textFaint: const Color(0xFFA7B0BE),
      radius: 28,
      coverAspect: 1.3,
      tileAspect: 0.8,
      displayFont: 'Nunito',
      bodyFont: 'Nunito',
      labelFont: 'Nunito',
      caps: false,
      displayVariations: const [FontVariation('wght', 850)],
    ),
    LookId.air => Look._(
      id: id,
      accent: accent,
      brightness: Brightness.dark,
      background: const Color(0xFF000000),
      surface: const Color(0xFF1C1C1E),
      surfaceHigh: const Color(0xFF2C2C2E),
      line: const Color(0xFF38383A),
      text: const Color(0xFFFFFFFF),
      textDim: const Color(0xFF8E8E93),
      textFaint: const Color(0xFF545458),
      radius: 30,
      coverAspect: 1.0,
      tileAspect: 0.72,
      displayFont: 'Inter',
      bodyFont: 'Inter',
      labelFont: 'Inter',
      caps: false,
      displayVariations: const [FontVariation('wght', 700), FontVariation('opsz', 32)],
    ),
  };

  /// Скругление обложки шириной [width] (в кадрировании и на карточке).
  double coverRadius(double width) => switch (id) {
    LookId.ascii => width * 0.14,
    LookId.retro => 2,
    LookId.neu => width * 0.13,
    LookId.air => width * 0.11,
  };

  ThemeData toTheme() {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      error: accent,
      onError: onAccent,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textDim,
      surfaceContainerHighest: surfaceHigh,
      surfaceContainerHigh: surface,
      outline: line,
      outlineVariant: line,
    );
    final OutlinedBorder buttonShape = id == LookId.retro
        ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(6))
        : const StadiumBorder();
    final buttonText = label(size: 13, weight: FontWeight.w600, color: text);
    final sheetRadius = id == LookId.retro ? 6.0 : 28.0;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: bodyFont,
      splashFactory: InkSparkle.splashFactory,
      extensions: [this],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: label(size: 14, weight: FontWeight.w600, color: text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: id == LookId.neu ? background : surface,
        surfaceTintColor: Colors.transparent,
        shape: id == LookId.retro
            ? BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: line, width: 2),
              )
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: label(size: 15, weight: FontWeight.w700, color: text),
        contentTextStyle: body(color: textDim, size: 13),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: id == LookId.neu ? background : surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: line,
        showDragHandle: true,
        shape: id == LookId.retro
            ? BeveledRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
                side: BorderSide(color: line, width: 2),
              )
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
              ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: body(color: background, size: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        hintStyle: label(size: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(id == LookId.retro ? 4 : 18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(id == LookId.retro ? 4 : 18),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.35),
        selectionHandleColor: accent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: surfaceHigh,
          disabledForegroundColor: textFaint,
          shape: buttonShape,
          minimumSize: const Size(0, 52),
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(
            color: id == LookId.retro ? text : line,
            width: id == LookId.retro ? 2 : 1.5,
          ),
          shape: buttonShape,
          minimumSize: const Size(0, 44),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: text)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    );
  }

  @override
  Look copyWith() => this;

  @override
  Look lerp(covariant Look? other, double t) => other == null || t < 0.5 ? this : other;
}
