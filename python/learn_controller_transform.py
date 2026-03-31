import sys, json
from collections import defaultdict
from common.common_io import save_json

trace_file, src, tgt, output = sys.argv[1:5]

mapping = defaultdict(float)
count = 0

with open(trace_file) as f:
    for line in f:
        row = json.loads(line)
        if row["controller"] == src:
            count += 1
            # naive example: reward high-score actions
            if row["score"] > 0:
                mapping[row["selected"]] += 1

# normalize
total = sum(mapping.values()) or 1.0
for k in mapping:
    mapping[k] /= total

save_json(output, {
    "source": src,
    "target": tgt,
    "type": "learned_transform",
    "mapping": dict(mapping)
})
