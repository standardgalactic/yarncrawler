import sys
from common.common_io import load_json, save_json

prev_file, curr_file, output = sys.argv[1:4]

prev = load_json(prev_file)
curr = load_json(curr_file)

dist = 0.0

if prev["id"] != curr["id"]:
    dist += 1.0

for k in set(prev.get("parameters", {})) | set(curr.get("parameters", {})):
    dist += abs(prev["parameters"].get(k, 0) - curr["parameters"].get(k, 0))

THRESHOLD = 0.1

save_json(output, {
    "fixed_point": dist < THRESHOLD,
    "distance": dist
})
