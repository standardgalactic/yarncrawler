#!/usr/bin/env bash
set -euo pipefail

mkdir -p backup
cp -n *.jpg *.webp backup/ 2>/dev/null || true

files=(
"4dbc8abd-c65e-4b9f-9b4e-96817e53b18f(1).jpg"
"6ade70ab-bda2-4321-80cc-f2b7716a98f8(1).jpg"
"70b7c2a7-60c3-4707-8ebb-b9f555eec0a6(1).jpg"
"7a55df58-b748-4c86-83cb-e3987ba99c7e(1).jpg"
"7a55df58-b748-4c86-83cb-e3987ba99c7e(2).jpg"
"80ca86b5-d2d7-4efb-82b7-b1e811bcd205(1).jpg"
"82f8c2c7-cba1-41e6-9dd9-a3aa8d41c964(1).jpg"
"9b2206e3-5e0b-4f18-93ec-1021fd0d7d52(1).jpg"
"a7b63e36-7b4e-42cb-81b7-5a301d97abf4(1).jpg"
"ba22b93f-a96e-4ee4-9040-668dc01fee4f(1).jpg"
"f6d79bd8-e733-48c1-a945-5a84c5c5a0a5(1).jpg"
"image (89).webp"
"image (90).webp"
"image (91).webp"
"image (92).webp"
"image (93).webp"
"image (94).webp"
"image (95).webp"
"image (96).webp"
"image (97)(1).jpg"
)

i=1
for file in "${files[@]}"; do
  ext="${file##*.}"
  new=$(printf "mech-%02d.%s" "$i" "$ext")

  echo "Renaming: $file -> $new"
  mv -n -- "$file" "$new"

  ((i++))
done
