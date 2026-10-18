import 'package:flutter/material.dart';

import 'models.dart';

/// Встроенные звуки. Аудио лежит в assets/sounds/, обложки — в assets/images/.
const builtInSounds = <Sound>[
  Sound(
    id: 'forest',
    name: 'Nature forest',
    path: 'assets/sounds/forest.ogg',
    icon: Icons.forest,
    imagePath: 'assets/images/forest.jpg',
    art: ArtPlacement(dy: 0.4516, columns: 44),
  ),
  Sound(
    id: 'wind',
    name: 'Nature wind',
    path: 'assets/sounds/wind.ogg',
    icon: Icons.air,
    imagePath: 'assets/images/wind.jpg',
    art: ArtPlacement(dx: 0.8669, columns: 44),
  ),
  Sound(
    id: 'windy_room',
    name: 'Windy room',
    path: 'assets/sounds/windy_room.ogg',
    icon: Icons.sensor_door,
    imagePath: 'assets/images/windy_room.jpg',
    art: ArtPlacement(scale: 1.4881, dx: 0.0285, dy: 0.4662, columns: 44),
  ),
  Sound(
    id: 'rain',
    name: 'Rain',
    path: 'assets/sounds/rain.ogg',
    icon: Icons.water_drop,
    imagePath: 'assets/images/rain.jpg',
    art: ArtPlacement(dx: -0.2876, columns: 44),
  ),
  Sound(
    id: 'thunder',
    name: 'Thunder',
    path: 'assets/sounds/thunder.ogg',
    icon: Icons.bolt,
    imagePath: 'assets/images/thunder.jpg',
    art: ArtPlacement(columns: 44),
  ),
  Sound(
    id: 'storm',
    name: 'Storm',
    path: 'assets/sounds/storm.ogg',
    icon: Icons.thunderstorm,
    imagePath: 'assets/images/storm.jpg',
    art: ArtPlacement(scale: 1.4881, dx: -0.1152, dy: 1, columns: 44),
  ),
  Sound(
    id: 'ocean',
    name: 'Ocean',
    path: 'assets/sounds/ocean.ogg',
    icon: Icons.waves,
    imagePath: 'assets/images/ocean.jpg',
    art: ArtPlacement(scale: 1.4881, dx: 0.0422, dy: 1, columns: 44),
  ),
  Sound(
    id: 'river',
    name: 'River',
    path: 'assets/sounds/river.ogg',
    icon: Icons.water,
    imagePath: 'assets/images/river.jpg',
    art: ArtPlacement(scale: 1.2199, dx: 1, dy: -1, columns: 44),
  ),
  Sound(
    id: 'night',
    name: 'Night',
    path: 'assets/sounds/night.ogg',
    icon: Icons.nightlight,
    imagePath: 'assets/images/night.jpg',
    art: ArtPlacement(scale: 2.2144, dx: 0.0801, dy: -0.0966, columns: 44),
  ),
  Sound(
    id: 'campfire',
    name: 'Campfire',
    path: 'assets/sounds/campfire.ogg',
    icon: Icons.local_fire_department,
    imagePath: 'assets/images/campfire.jpg',
    art: ArtPlacement(scale: 1.4881, dx: 0.0856, dy: 0.3393, columns: 44),
  ),
  Sound(
    id: 'train',
    name: 'Train',
    path: 'assets/sounds/train.ogg',
    icon: Icons.train,
    imagePath: 'assets/images/train.jpg',
    art: ArtPlacement(scale: 1.2199, dx: 0.1252, dy: -0.043, columns: 44),
  ),
  Sound(
    id: 'cafe',
    name: 'Cafe',
    path: 'assets/sounds/cafe.ogg',
    icon: Icons.local_cafe,
    imagePath: 'assets/images/cafe.jpg',
    art: ArtPlacement(scale: 1.4881, dx: 0.7898, dy: 0.5294, columns: 44),
  ),
];

/// Готовые сеты.
const builtInSets = <SoundSet>[];
