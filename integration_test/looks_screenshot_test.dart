import 'dart:io';
import 'dart:ui' as ui;

import 'package:amby/app_state.dart';
import 'package:amby/audio_engine.dart';
import 'package:amby/look/look.dart';
import 'package:amby/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Снимает приложение во всех оформлениях — на широком экране и в размере телефона.
/// Запуск: AMBY_SHOTS=/tmp/shots flutter test integration_test/looks_screenshot_test.dart -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final dir = Platform.environment['AMBY_SHOTS'];

  testWidgets('скриншоты оформлений', (tester) async {
    final state = AppState(AudioEngine());
    final root = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: root, child: AmbyApp(state: state)));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // не шумим в колонки и потом возвращаем настройки как было
    final originalLook = state.lookId;
    final originalVolume = state.masterVolume;
    state.setMasterVolume(0);

    final playing = [state.sounds.first, state.sounds.last];
    for (final s in playing) {
      await state.toggle(s);
    }

    Future<void> shoot(String name) async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // рендерим кадр прямо из дерева — не зависит от того, что видно на экране
      final boundary = root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await tester.runAsync(() => boundary.toImage());
      final png = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
      File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    for (final look in LookId.values) {
      state.setLook(look);
      await shoot(look.name);
    }

    // телефонная раскладка
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    for (final look in LookId.values) {
      state.setLook(look);
      await shoot('phone_${look.name}');
    }
    await tester.tap(find.byTooltip('Оформление'));
    await shoot('phone_sheet');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    for (final s in playing) {
      await state.toggle(s);
    }
    state.setLook(originalLook);
    state.setMasterVolume(originalVolume);
    await tester.pump(const Duration(milliseconds: 500));
  }, skip: dir == null);
}
