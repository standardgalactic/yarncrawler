#!/usr/bin/env bash
set -euo pipefail

CTRL="controllers/state/controller_state.json"
TRANSFORM="controllers/transformations/beam_to_learned.json"

for i in $(seq 1 10); do
  NEXT="/tmp/controller_next.json"

  python3 python/iterate_controller.py "$CTRL" "$TRANSFORM" "$NEXT"

  python3 python/check_fixed_point.py "$CTRL" "$NEXT" /tmp/fp.json

  python3 python/update_stability.py "$NEXT" /tmp/fp.json

  mv "$NEXT" "$CTRL"
done

echo "Controller iteration complete."
