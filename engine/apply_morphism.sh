#!/usr/bin/env bash
set -euo pipefail

MORPH="$1"
INPUT="$2"
OUTPUT="$3"

python3 python/morphism_apply.py "$MORPH" "$INPUT" "$OUTPUT"
