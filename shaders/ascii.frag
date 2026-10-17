#version 460 core

// ASCII-шейдер: делит область на ячейки, берёт яркость картинки в центре ячейки
// и рисует символ соответствующей «плотности» из атласа глифов.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // размер области, px
uniform vec2 uCell;        // размер ячейки-символа, px
uniform vec2 uImageSize;   // размер исходной картинки, px
uniform vec2 uOffset;      // сдвиг кадра, -1..1 по каждой оси
uniform float uScale;      // приближение, >= 1
uniform float uGlyphCount; // число символов в атласе (от пустого к плотному)
uniform vec4 uColor;       // цвет символов
uniform float uTime;       // секунды, для анимации
uniform float uActive;     // 0..1 — «живая» рябь, пока звук играет
uniform float uContrast;
uniform float uInvert;     // 1 — инвертировать яркость (для светлого фона)

uniform sampler2D uImage;
uniform sampler2D uGlyphs;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 cell = floor(p / uCell);
  vec2 uv = (cell + 0.5) * uCell / uSize;

  // cover-вписывание картинки + масштаб и сдвиг кадра
  float aspect = uSize.x / uSize.y;
  float imageAspect = uImageSize.x / uImageSize.y;
  vec2 region = imageAspect > aspect ? vec2(aspect / imageAspect, 1.0) : vec2(1.0, imageAspect / aspect);
  region /= uScale;
  vec2 center = 0.5 + uOffset * (1.0 - region) * 0.5;
  vec2 imageUv = center + (uv - 0.5) * region;

  vec4 texel = texture(uImage, imageUv);
  float lum = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
  if (uInvert > 0.5) lum = texel.a - lum;
  lum = clamp((lum - 0.5) * uContrast + 0.5, 0.0, 1.0);

  // пока звук играет: бегущая волна яркости и лёгкое мерцание ячеек
  // на пустом фоне волна слабая — проступают лишь редкие точки на гребнях
  lum += uActive * (0.05 + 0.12 * lum) * sin(uv.y * 8.0 + uv.x * 3.0 - uTime * 2.4);
  lum += uActive * 0.08 * (hash(cell + floor(uTime * 6.0)) - 0.5);
  lum = clamp(lum, 0.0, 1.0);

  float index = floor(lum * (uGlyphCount - 1.0) + 0.5);
  vec2 local = fract(p / uCell);
  float glyph = texture(uGlyphs, vec2((index + local.x) / uGlyphCount, local.y)).a;

  fragColor = vec4(uColor.rgb, 1.0) * uColor.a * glyph;
}
