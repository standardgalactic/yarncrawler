import sys
from common.common_io import load_json, save_json

c1_file, c2_file, output = sys.argv[1:4]

c1 = load_json(c1_file)
c2 = load_json(c2_file)

dist = 0.0

# identity mismatch
if c1["id"] != c2["id"]:
    dist += 0.5

# parameter difference
p1 = c1.get("parameters", {})
p2 = c2.get("parameters", {})

for k in set(p1) | set(p2):
    dist += abs(p1.get(k, 0) - p2.get(k, 0))

# stability similarity
dist += abs(c1.get("stability_score", 0) - c2.get("stability_score", 0)) * 0.1

save_json(output, {"distance": dist})
