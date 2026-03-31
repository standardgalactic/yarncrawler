#!/usr/bin/env bash
set -e

echo "== Yarncrawler Thought Loop =="

python3 python/meta_controller.py

bash engine/run_controller_fixed_point.sh

echo "Done"
