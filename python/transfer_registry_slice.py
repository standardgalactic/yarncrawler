import sys
import os
import subprocess

registry_dir, transfer_file, out_dir = sys.argv[1:4]

os.makedirs(out_dir, exist_ok=True)

entries_dir = os.path.join(registry_dir, "entries")
if not os.path.isdir(entries_dir):
    sys.exit(0)

for fname in os.listdir(entries_dir):
    if not fname.endswith(".json"):
        continue

    src = os.path.join(entries_dir, fname)
    dst = os.path.join(out_dir, fname)

    subprocess.run([
        "python3", "python/transfer_morphism.py",
        src, transfer_file, dst
    ], check=True)
