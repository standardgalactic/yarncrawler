#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${1:-morphisms/registry}"
TRANSFER="${2:-state/transfer_A_to_B.json}"
OUTDIR="${3:-morphisms/transferred}"

mkdir -p "$OUTDIR"

python3 python/transfer_registry_slice.py \
  "$REGISTRY" \
  "$TRANSFER" \
  "$OUTDIR"

echo "Transferred registry slice written to $OUTDIR"
