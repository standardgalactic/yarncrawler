#!/usr/bin/env bash
set -euo pipefail

CLASS_SELECTION="$1"

REP=$(jq -r '.representative' "$CLASS_SELECTION")

echo "Using representative controller: $REP"

cat "controllers/registry/$REP.json"
