import 'dart:io';
import 'dart:ui';
import 'package:amby/catalog.dart';
import 'package:amby/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SoundSet переживает сериализацию в JSON', () {
    const set = SoundSet(id: 's1', name: 'Ночь', volumes: {'rain': 0.8, 'wind': 0.25});
    final restored = SoundSet.fromJson(set.toJson());
    expect(restored.id, 's1');
    expect(restored.name, 'Ночь');
    expect(restored.volumes, {'rain': 0.8, 'wind': 0.25});
  });

  test('Sound.custom переживает сериализацию в JSON', () {
    final sound = Sound.custom(id: 'c1', name: 'Кот', path: '/tmp/cat.ogg');
    final restored = Sound.fromJson(sound.toJson());
    expect(restored.isCustom, isTrue);
    expect(restored.path, '/tmp/cat.ogg');
  });

  group('ArtPlacement', () {
    const card = Size(160, 200);
    const wide = Size(1600, 900);

    test('withCenter и center согласованы', () {
      const art = ArtPlacement(scale: 2);
      final moved = art.withCenter(const Offset(0.7, 0.4), card, wide);
      final c = moved.center(card, wide);
      expect(c.dx, closeTo(0.7, 1e-9));
      expect(c.dy, closeTo(0.4, 1e-9));
    });

    test('zoomedAt оставляет точку под пальцем на месте', () {
      const art = ArtPlacement(scale: 1.5, dx: 0.2, dy: -0.3);
      const focal = Offset(40, 150);
      Offset pointUnder(ArtPlacement a) {
        final r = a.visibleRegion(card, wide);
        final c = a.center(card, wide);
        return c + Offset((focal.dx / card.width - 0.5) * r.width,
            (focal.dy / card.height - 0.5) * r.height);
      }

      final zoomed = art.zoomedAt(2.5, focal, card, wide);
      expect(zoomed.scale, 2.5);
      expect((pointUnder(zoomed) - pointUnder(art)).distance, lessThan(1e-9));
    });

    test('кадр не выходит за края картинки', () {
      final art = const ArtPlacement(scale: 1).withCenter(const Offset(0, 0), card, wide);
      expect(art.dx, -1);
      expect(art.dy, 0); // по высоте запаса нет — картинка вписана по высоте
    });
  });

  test('файлы встроенных звуков и обложек существуют', () {
    for (final sound in builtInSounds) {
      expect(File(sound.path).existsSync(), isTrue, reason: sound.path);
      expect(File(sound.imagePath!).existsSync(), isTrue, reason: sound.imagePath);
    }
  });

  test('встроенные сеты ссылаются только на существующие звуки', () {
    final ids = builtInSounds.map((s) => s.id).toSet();
    for (final set in builtInSets) {
      expect(ids.containsAll(set.volumes.keys), isTrue, reason: set.name);
    }
  });
}
