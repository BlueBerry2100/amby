#!/usr/bin/env bash
# Генерирует бесшовные (seamless) звуковые петли-заглушки в assets/sounds/.
# Замените их на реальные записи — главное, чтобы конец петли гладко переходил в начало.
#
# Принцип бесшовности: генерируем L+F секунд, затем первые F секунд
# смешиваем с «хвостом» (L..L+F) через кроссфейд. Конец петли непрерывно
# переходит в её начало, поэтому щелчка на стыке нет.
set -euo pipefail

L=40   # длина петли, сек (периоды модуляций должны делить L нацело)
F=4    # длина кроссфейда, сек
OUT="$(dirname "$0")/../assets/sounds"
mkdir -p "$OUT"

# make <name> <source-filtergraph> [post-filter]
make() {
  local name=$1 src=$2 post=${3:-anull}
  ffmpeg -hide_banner -loglevel error -y -filter_complex "
    ${src},atrim=0:$((L + F)),asetpts=N/SR/TB,asplit[a][b];
    [a]atrim=0:${L},asetpts=N/SR/TB,afade=t=in:d=${F}:curve=qsin[body];
    [b]atrim=${L}:$((L + F)),asetpts=N/SR/TB,afade=t=out:d=${F}:curve=qsin,apad=whole_dur=${L}[tail];
    [body][tail]amix=inputs=2:normalize=0:duration=first,${post},alimiter=limit=0.9[out]" \
    -map '[out]' -ac 1 -ar 44100 -c:a libvorbis -q:a 4 "$OUT/$name.ogg"
  echo "  $name.ogg"
}

N="sample_rate=44100:duration=$((L + F))"

echo "Генерация звуков в $OUT:"
make white  "anoisesrc=${N}:color=white:amplitude=0.25"
make pink   "anoisesrc=${N}:color=pink:amplitude=0.5"
make brown  "anoisesrc=${N}:color=brown:amplitude=0.9"
make rain   "anoisesrc=${N}:color=white:amplitude=0.5,highpass=f=500,lowpass=f=7000,lowpass=f=7000"
make stream "anoisesrc=${N}:color=white:amplitude=0.7,bandpass=f=2500:width_type=o:w=2"
make wind   "anoisesrc=${N}:color=brown:amplitude=1,bandpass=f=400:width_type=o:w=2" \
            "tremolo=f=0.1:d=0.7"
make ocean  "anoisesrc=${N}:color=pink:amplitude=0.8,lowpass=f=1000" \
            "tremolo=f=0.125:d=0.85"
make fan    "anoisesrc=${N}:color=brown:amplitude=0.9,lowpass=f=350[n];sine=f=100:${N},volume=0.04[h];[n][h]amix=inputs=2:normalize=0"
