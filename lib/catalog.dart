import 'package:flutter/material.dart';

import 'models.dart';

/// Встроенные звуки. Файлы лежат в assets/sounds/ (генерируются tool/gen_sounds.sh).
const builtInSounds = <Sound>[
  Sound(id: 'rain', name: 'Дождь', path: 'assets/sounds/rain.ogg', icon: Icons.water_drop),
  Sound(id: 'ocean', name: 'Океан', path: 'assets/sounds/ocean.ogg', icon: Icons.waves),
  Sound(id: 'wind', name: 'Ветер', path: 'assets/sounds/wind.ogg', icon: Icons.air),
  Sound(id: 'stream', name: 'Ручей', path: 'assets/sounds/stream.ogg', icon: Icons.water),
  Sound(id: 'fan', name: 'Вентилятор', path: 'assets/sounds/fan.ogg', icon: Icons.wind_power),
  Sound(id: 'white', name: 'Белый шум', path: 'assets/sounds/white.ogg', icon: Icons.blur_on),
  Sound(id: 'pink', name: 'Розовый шум', path: 'assets/sounds/pink.ogg', icon: Icons.grain),
  Sound(
    id: 'brown',
    name: 'Коричневый шум',
    path: 'assets/sounds/brown.ogg',
    icon: Icons.blur_circular,
  ),
];

/// Готовые сеты.
const builtInSets = <SoundSet>[
  SoundSet(
    id: 'set_storm_night',
    name: 'Дождливая ночь',
    builtIn: true,
    volumes: {'rain': 0.8, 'wind': 0.4, 'brown': 0.3},
  ),
  SoundSet(id: 'set_seaside', name: 'У моря', builtIn: true, volumes: {'ocean': 0.9, 'wind': 0.25}),
  SoundSet(id: 'set_focus', name: 'Фокус', builtIn: true, volumes: {'pink': 0.6, 'stream': 0.3}),
  SoundSet(
    id: 'set_deep_sleep',
    name: 'Глубокий сон',
    builtIn: true,
    volumes: {'brown': 0.7, 'fan': 0.5},
  ),
];
