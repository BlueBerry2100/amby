import 'dart:async';
import 'dart:io';

import 'package:amby/app_state.dart';
import 'package:amby/audio_engine.dart';
import 'package:amby/main.dart';
import 'package:amby/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Воспроизводит сценарий «сохранил новый звук — приложение зависло»:
/// добавляет большой mp3 с картинкой, включает его и следит, не блокируется ли UI-поток.
///
/// Запуск: AMBY_AUDIO=/path/big.mp3 AMBY_IMAGE=/path/pic.jpg \
///   flutter test integration_test/big_sound_test.dart -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final audio = Platform.environment['AMBY_AUDIO'];
  final image = Platform.environment['AMBY_IMAGE'];

  testWidgets('большой свой звук не вешает интерфейс', (tester) async {
    final state = AppState(AudioEngine());
    await tester.pumpWidget(AmbyApp(state: state));
    // ждём загрузку аудиодвижка, шейдера и сохранённых звуков
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // самая длинная пауза между тиками таймера = насколько UI-поток был занят
    var maxGap = Duration.zero;
    var last = DateTime.now();
    final watchdog = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final gap = now.difference(last);
      if (gap > maxGap) maxGap = gap;
      last = now;
    });

    Future<void> step(String name, Future<void> Function() action) async {
      maxGap = Duration.zero;
      final sw = Stopwatch()..start();
      await action();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // ignore: avoid_print
      print('STEP $name: ${sw.elapsedMilliseconds} ms, max UI gap ${maxGap.inMilliseconds} ms');
    }

    await step('addSound', () => state.addSound(
          name: 'big test',
          audioPath: audio!,
          imagePath: image,
          art: const ArtPlacement(scale: 3.28, dx: 0.14, dy: 0.64, columns: 44),
        ));
    final sound = state.sounds.last;

    await step('toggle on', () => state.toggle(sound));
    // ignore: avoid_print
    print('active after toggle: ${state.isActive(sound.id)}, error: ${state.lastError}');

    await step('volume drag', () async {
      for (var v = 0.0; v <= 1; v += 0.05) {
        state.setVolume(sound.id, v);
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    await step('toggle off', () => state.toggle(sound));

    // ---- путь через интерфейс: редактор → кадр → сохранение ----
    final tile = find.text('BIG TEST');
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await step('open editor', () => tester.longPress(tile));
    await step('open crop', () => tester.tap(find.text('КАДР')));
    await step('drag photo', () => tester.drag(find.byType(CustomPaint).first, const Offset(-60, 40)));
    await step('crop done', () => tester.tap(find.text('ГОТОВО')));
    await step('rename', () => tester.enterText(find.byType(EditableText), 'big test 2'));
    await step('save', () => tester.tap(find.text('СОХРАНИТЬ')));
    // ignore: avoid_print
    print('editor closed: ${find.text('ИЗМЕНИТЬ ЗВУК').evaluate().isEmpty}');

    await step('delete', () => state.deleteSound(state.sounds.last));

    watchdog.cancel();
  }, skip: audio == null);
}
