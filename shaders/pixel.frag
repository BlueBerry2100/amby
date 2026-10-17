#version 460 core

// Пиксельный шейдер для оформления Retro: крупные пиксели, ограниченная палитра
// и упорядоченный дизеринг (матрица Байера 4×4), как у старых консолей.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // размер области, px
uniform vec2 uCell;        // размер «пикселя», px
uniform vec2 uImageSize;   // размер исходной картинки, px
uniform vec2 uOffset;      // сдвиг кадра, -1..1
uniform float uScale;      // приближение, >= 1
uniform float uLevels;     // уровней на канал (палитра)
uniform float uMono;       // 1 — одноцветный режим (иконки) с цветом uTint
uniform vec4 uTint;
uniform float uTime;
uniform float uActive;     // 0..1 — бегущая полоса, пока звук играет
uniform float uGap;        // 0..1 — тёмная сетка между пикселями (как на LCD)

uniform sampler2D uImage;

out vec4 fragColor;

float bayer2(vec2 a) {
  a = floor(a);
  return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(vec2 a) {
  return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 cell = floor(p / uCell);
  vec2 uv = (cell + 0.5) * uCell / uSize;

  float aspect = uSize.x / uSize.y;
  float imageAspect = uImageSize.x / uImageSize.y;
  vec2 region = imageAspect > aspect ? vec2(aspect / imageAspect, 1.0) : vec2(1.0, imageAspect / aspect);
  region /= uScale;
  vec2 center = 0.5 + uOffset * (1.0 - region) * 0.5;
  vec4 texel = texture(uImage, center + (uv - 0.5) * region);

  float dither = bayer4(cell) - 0.5;
  float steps = uLevels - 1.0;

  // бегущая яркая полоса по строкам, пока звук играет
  float sweep = uActive * 0.18 * smoothstep(0.85, 1.0, sin(uv.y * 6.0 - uTime * 3.0));

  vec4 color;
  if (uMono > 0.5) {
    float lum = dot(texel.rgb, vec3(0.299, 0.587, 0.114)) + sweep * texel.a;
    lum = clamp(floor(lum * steps + 0.5 + dither) / steps, 0.0, 1.0);
    color = vec4(uTint.rgb, 1.0) * uTint.a * lum;
  } else {
    vec3 rgb = texel.rgb + sweep;
    rgb = clamp(floor(rgb * steps + 0.5 + dither) / steps, 0.0, 1.0);
    color = vec4(rgb, 1.0) * texel.a;
  }

  vec2 local = fract(p / uCell);
  float edge = step(1.0 - 0.14 * uGap, max(local.x, local.y));
  fragColor = color * (1.0 - edge * 0.45);
}
