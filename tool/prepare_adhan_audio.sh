#!/usr/bin/env bash
# Turns one adhan recording into the three files the app needs:
#   android/app/src/main/res/raw/adhan_<id>.ogg   full length (Android channel sound)
#   ios/Runner/adhan_<id>.caf                     29.5 s clip (iOS limit is 30 s)
#   assets/audio/preview_adhan_<id>.m4a           same clip (Settings preview)
#
# Usage, from the project root:
#   tool/prepare_adhan_audio.sh <id> <recording> [clip-start-seconds]
#
# <id> is one of: makkah madinah alafasy makkah_fajr madinah_fajr alafasy_fajr
# <recording> is any audio file ffmpeg reads (mp3, m4a, wav, ogg, flac...).
# [clip-start-seconds] is where the 29.5 s iOS/preview clip starts (default 0);
# pick the start of the first takbir if the recording has silence first.
#
# Needs ffmpeg (brew install ffmpeg) and macOS afconvert. Afterwards, follow
# the printed steps: add the .caf to the Runner target in Xcode, set the
# sound's `available: true` in lib/data/adhan_sounds.dart, and record the
# file's source and license in assets/audio/LICENSE.md.
set -euo pipefail

ids="makkah madinah alafasy makkah_fajr madinah_fajr alafasy_fajr"
if [[ $# -lt 2 ]]; then
  sed -n '2,20p' "$0"
  exit 1
fi
id=$1
src=$2
start=${3:-0}

if [[ " $ids " != *" $id "* ]]; then
  echo "Unknown id '$id'. Use one of: $ids" >&2
  exit 1
fi
if [[ ! -f $src ]]; then
  echo "No such file: $src" >&2
  exit 1
fi
if [[ ! -d android/app/src/main/res/raw || ! -d ios/Runner ]]; then
  echo "Run this from the project root." >&2
  exit 1
fi
if ! ffmpeg -hide_banner -version >/dev/null 2>&1; then
  echo "ffmpeg is missing or broken. Install or repair it with: brew reinstall ffmpeg" >&2
  exit 1
fi

name="adhan_$id"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Android: the whole recording, mono, loudness-normalised, Ogg Vorbis.
ffmpeg -hide_banner -loglevel error -y -i "$src" -vn \
  -af "loudnorm=I=-16:TP=-1.5" -ac 1 -ar 44100 -c:a libvorbis -q:a 4 \
  "android/app/src/main/res/raw/$name.ogg"

# iOS + preview: 29.5 s from the start point, faded in/out, normalised.
ffmpeg -hide_banner -loglevel error -y -ss "$start" -t 29.5 -i "$src" -vn \
  -af "afade=t=in:d=0.15,afade=t=out:st=28.0:d=1.5,loudnorm=I=-16:TP=-1.5" \
  -ac 1 -ar 44100 "$tmp/clip.wav"
afconvert -f caff -d ima4 "$tmp/clip.wav" "ios/Runner/$name.caf"
afconvert -f m4af -d aac "$tmp/clip.wav" "assets/audio/preview_$name.m4a"

seconds=$(afinfo "ios/Runner/$name.caf" | awk '/estimated duration/ {print $3}')
echo "Created:"
echo "  android/app/src/main/res/raw/$name.ogg"
echo "  ios/Runner/$name.caf ($seconds s)"
echo "  assets/audio/preview_$name.m4a"
echo
echo "Next:"
echo "  1. Xcode: open ios/Runner.xcworkspace, right-click the Runner folder > Add Files to \"Runner\"..."
echo "     select ios/Runner/$name.caf, untick 'Copy items if needed', tick target 'Runner', click Add."
echo "     (Check: Runner target > Build Phases > Copy Bundle Resources lists $name.caf.)"
echo "  2. lib/data/adhan_sounds.dart: set available: true on the '$id' sound."
echo "  3. assets/audio/LICENSE.md: fill in the source and license for $name."
echo "  4. flutter test test/adhan_sounds_test.dart   (checks all of the above)"
