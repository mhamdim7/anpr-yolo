#!/usr/bin/env bash
set -euo pipefail
FPS="${FPS:-2}"
mkdir -p data/interim
for v in data/raw/*.mp4; do
  [ -e "$v" ] || continue
  name=$(basename "${v%.*}")
  ffmpeg -y -i "$v" -r "$FPS" -qscale:v 3 "data/interim/${name}_%06d.jpg"
done
echo "Frames extracted to data/interim/"
