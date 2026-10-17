import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Растровые источники для ASCII-шейдера: картинки из файлов и иконки. Кэшируются.
class ArtSources {
  static final Map<String, Future<ui.Image>> _cache = {};

  static Future<ui.Image> file(String path) => _cache.putIfAbsent('file:$path', () async {
    final bytes = await File(path).readAsBytes();
    // шейдерам хватает низкого разрешения, обычным обложкам — среднего
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 720);
    return (await codec.getNextFrame()).image;
  });

  /// Иконка белым по прозрачному, с мягким свечением — чтобы у краёв был градиент
  /// и в ASCII получались промежуточные символы, а не только «@» и пробел.
  static Future<ui.Image> icon(IconData icon) =>
      _cache.putIfAbsent('icon:${icon.codePoint}', () async {
        const w = 240.0, h = 300.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        TextPainter painter(Paint paint) => TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: 150,
              foreground: paint,
            ),
          ),
        )..layout();

        final glow = painter(
          Paint()
            ..color = const Color(0x99FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
        final sharp = painter(Paint()..color = Colors.white);
        // чуть выше центра — нижнюю часть карточки занимает подпись
        final origin = Offset((w - sharp.width) / 2, h * 0.4 - sharp.height / 2);
        glow.paint(canvas, origin);
        sharp.paint(canvas, origin);

        return recorder.endRecording().toImage(w.toInt(), h.toInt());
      });

  static void evict(String path) => _cache.remove('file:$path');
}
