#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v cwebp >/dev/null 2>&1 || { echo "Missing cwebp (install libwebp)."; exit 1; }
command -v jpegoptim >/dev/null 2>&1 || { echo "Missing jpegoptim."; exit 1; }
command -v pngquant >/dev/null 2>&1 || { echo "Missing pngquant."; exit 1; }

# Optimize JPEGs
for f in img/*.jpg img/*.jpeg; do
  [ -e "$f" ] || continue
  jpegoptim --strip-all --max=82 "$f" >/dev/null 2>&1 || true
  out="${f%.*}.webp"
  if [ ! -f "$out" ] || [ "$f" -nt "$out" ]; then
    cwebp -q 80 "$f" -o "$out"
  fi
done

# Optimize and convert PNGs to WebP while keeping a small fallback on disk
for f in img/*.png; do
  [ -e "$f" ] || continue
  out="${f%.png}.webp"
  if [ ! -f "$out" ] || [ "$f" -nt "$out" ]; then
    cwebp -q 80 "$f" -o "$out"
  fi
  pngquant --force --quality=75-85 --speed 1 --output "$f" "$f" >/dev/null 2>&1 || true
  if [ -s "$f" ]; then
    pngquant --force --quality=75-85 --speed 1 --strip --output "$f" "$f" >/dev/null 2>&1 || true
  fi
done

# Keep SVGs as-is; they are already optimized vector assets.

printf '\nOptimized images in %s\n' "$ROOT"
printf 'Generated WebP versions for JPEG/PNG assets and minimized PNG files.\n'
