import 'package:flutter/material.dart';

/// Как картинка лежит на карточке: приближение, сдвиг кадра и плотность ASCII-сетки.
@immutable
class ArtPlacement {
  const ArtPlacement({this.scale = 1, this.dx = 0, this.dy = 0, this.columns = 18});

  static const minScale = 1.0, maxScale = 4.0;
  static const minColumns = 10.0, maxColumns = 44.0;

  /// Приближение, 1 — картинка целиком закрывает карточку (cover).
  final double scale;

  /// Сдвиг кадра внутри картинки, -1..1 (0 — по центру).
  final double dx, dy;

  /// Сколько символов помещается по ширине карточки.
  final double columns;

  ArtPlacement copyWith({double? scale, double? dx, double? dy, double? columns}) => ArtPlacement(
    scale: (scale ?? this.scale).clamp(minScale, maxScale),
    dx: (dx ?? this.dx).clamp(-1.0, 1.0),
    dy: (dy ?? this.dy).clamp(-1.0, 1.0),
    columns: (columns ?? this.columns).clamp(minColumns, maxColumns),
  );

  /// Видимая доля картинки по осям — та же формула, что в shaders/ascii.frag.
  Size visibleRegion(Size card, Size image) {
    final aspect = card.width / card.height;
    final imageAspect = image.width / image.height;
    final region = imageAspect > aspect
        ? Size(aspect / imageAspect, 1)
        : Size(1, imageAspect / aspect);
    return region / scale;
  }

  /// Сдвигает кадр так, чтобы картинка «ехала» за пальцем на [delta] пикселей.
  ArtPlacement panned(Offset delta, Size card, Size image) {
    final region = visibleRegion(card, image);
    double move(double current, double d, double extent, double visible) {
      final slack = (1 - visible) / 2;
      if (slack <= 1e-6) return 0;
      return current - d / extent * visible / slack;
    }

    return copyWith(
      dx: move(dx, delta.dx, card.width, region.width),
      dy: move(dy, delta.dy, card.height, region.height),
    );
  }

  /// Центр видимого кадра в координатах картинки (0..1).
  Offset center(Size card, Size image) {
    final region = visibleRegion(card, image);
    return Offset(0.5 + dx * (1 - region.width) / 2, 0.5 + dy * (1 - region.height) / 2);
  }

  /// Ставит центр кадра в [center] (0..1), не выпуская кадр за края картинки.
  ArtPlacement withCenter(Offset center, Size card, Size image) {
    final region = visibleRegion(card, image);
    double offset(double c, double visible) {
      final slack = (1 - visible) / 2;
      return slack <= 1e-6 ? 0 : (c - 0.5) / slack;
    }

    return copyWith(dx: offset(center.dx, region.width), dy: offset(center.dy, region.height));
  }

  /// Меняет приближение так, чтобы точка картинки под [focal] (px от левого верхнего угла
  /// карточки) осталась на месте — как при щипке в редакторах аватарок.
  ArtPlacement zoomedAt(double newScale, Offset focal, Size card, Size image) {
    final f = Offset(focal.dx / card.width - 0.5, focal.dy / card.height - 0.5);
    final before = visibleRegion(card, image);
    final c = center(card, image);
    final point = c + Offset(f.dx * before.width, f.dy * before.height);

    final zoomed = copyWith(scale: newScale);
    final after = zoomed.visibleRegion(card, image);
    return zoomed.withCenter(point - Offset(f.dx * after.width, f.dy * after.height), card, image);
  }

  Map<String, dynamic> toJson() => {'scale': scale, 'dx': dx, 'dy': dy, 'columns': columns};

  factory ArtPlacement.fromJson(Map<String, dynamic>? json) => json == null
      ? const ArtPlacement()
      : ArtPlacement(
          scale: (json['scale'] as num).toDouble(),
          dx: (json['dx'] as num).toDouble(),
          dy: (json['dy'] as num).toDouble(),
          columns: (json['columns'] as num).toDouble(),
        );

  @override
  bool operator ==(Object other) =>
      other is ArtPlacement &&
      other.scale == scale &&
      other.dx == dx &&
      other.dy == dy &&
      other.columns == columns;

  @override
  int get hashCode => Object.hash(scale, dx, dy, columns);
}

/// Один звук: встроенный (asset) или добавленный пользователем (файл).
class Sound {
  const Sound({
    required this.id,
    required this.name,
    required this.path,
    this.icon = Icons.graphic_eq,
    this.isAsset = true,
    this.imagePath,
    this.art = const ArtPlacement(),
  });

  final String id;
  final String name;

  /// Ключ ассета для встроенных звуков или абсолютный путь к файлу для своих.
  final String path;

  /// Иконка рисуется ASCII, если нет своей картинки.
  final IconData icon;
  final bool isAsset;

  /// Картинка для карточки (рисуется ASCII-шейдером): ключ ассета для встроенных звуков,
  /// путь к файлу для своих.
  final String? imagePath;
  final ArtPlacement art;

  bool get isCustom => !isAsset;

  factory Sound.custom({
    required String id,
    required String name,
    required String path,
    String? imagePath,
    ArtPlacement art = const ArtPlacement(),
  }) => Sound(id: id, name: name, path: path, isAsset: false, imagePath: imagePath, art: art);

  Sound copyWith({String? name, String? path, String? imagePath, ArtPlacement? art}) => Sound(
    id: id,
    name: name ?? this.name,
    path: path ?? this.path,
    icon: icon,
    isAsset: isAsset,
    imagePath: imagePath ?? this.imagePath,
    art: art ?? this.art,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'imagePath': imagePath,
    'art': art.toJson(),
  };

  factory Sound.fromJson(Map<String, dynamic> json) => Sound.custom(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    imagePath: json['imagePath'] as String?,
    art: ArtPlacement.fromJson(json['art'] as Map<String, dynamic>?),
  );
}

/// Сет — сохранённая комбинация звуков с громкостями (id звука → громкость 0..1).
class SoundSet {
  const SoundSet({
    required this.id,
    required this.name,
    required this.volumes,
    this.builtIn = false,
  });

  final String id;
  final String name;
  final Map<String, double> volumes;
  final bool builtIn;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'volumes': volumes};

  factory SoundSet.fromJson(Map<String, dynamic> json) => SoundSet(
    id: json['id'] as String,
    name: json['name'] as String,
    volumes: (json['volumes'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
  );
}
