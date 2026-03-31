#!/usr/bin/env bash
set -e

echo "== Yarncrawler bootstrap =="

########################################
# DIRECTORIES
########################################

mkdir -p common
mkdir -p state
mkdir -p logs
mkdir -p morphisms/registry/entries
mkdir -p morphisms/transferred
mkdir -p python
mkdir -p controllers/registry
mkdir -p controllers/state
mkdir -p controllers/transformations
mkdir -p controllers/quotient
mkdir -p engine

########################################
# COMMON
########################################

cat > common/common_io.py << 'EOF'
import json
from pathlib import Path

def load_json(path):
    return json.loads(Path(path).read_text())

def save_json(path, obj):
    Path(path).write_text(json.dumps(obj, indent=2))

def append_jsonl(path, obj):
    with open(path, "a") as f:
        f.write(json.dumps(obj) + "\n")
EOF

########################################
# STATE
########################################

cat > state/initial_state.json << 'EOF'
{
  "Phi": 1.0,
  "v": [0.0, 0.0],
  "S": 0.1,
  "meta": {}
}
EOF

cat > state/topology.json << 'EOF'
{
  "nodes": ["n1","n2","n3"],
  "edges": [
    {"from": "n1", "to": "n2"},
    {"from": "n2", "to": "n3"}
  ]
}
EOF

cat > state/topology_B.json << 'EOF'
{
  "nodes": ["n1","n2","n3","n4","n5","n6"],
  "edges": [
    {"from": "n1", "to": "n2"},
    {"from": "n2", "to": "n3"},
    {"from": "n3", "to": "n4"},
    {"from": "n4", "to": "n5"},
    {"from": "n5", "to": "n6"}
  ]
}
EOF

cat > state/typing_rules.yaml << 'EOF'
scalar_field:
  - scalar_field
  - joint_field

flux_field:
  - flux_field
  - joint_field

joint_field:
  - joint_field
EOF

cat > state/domain_A.json << 'EOF'
{
  "domain_id": "chain_4_rgb_ir",
  "topology": "state/topology.json",
  "sensor_bundle": ["infrared", "geometry", "audio_entropy", "flow_magnitude", "mean_entropy"],
  "field_types": ["scalar_field", "flux_field", "joint_field"]
}
EOF

cat > state/domain_B.json << 'EOF'
{
  "domain_id": "chain_6_rgb_ir",
  "topology": "state/topology_B.json",
  "sensor_bundle": ["infrared", "geometry", "audio_entropy", "flow_magnitude", "mean_entropy"],
  "field_types": ["scalar_field", "flux_field", "joint_field"]
}
EOF

cat > state/transfer_A_to_B.json << 'EOF'
{
  "source_domain": "chain_4_rgb_ir",
  "target_domain": "chain_6_rgb_ir",

  "sensor_map": {
    "infrared": "infrared",
    "geometry": "geometry",
    "audio_entropy": "audio_entropy",
    "flow_magnitude": "flow_magnitude",
    "mean_entropy": "mean_entropy"
  },

  "type_map": {
    "scalar_field": "scalar_field",
    "flux_field": "flux_field",
    "joint_field": "joint_field"
  },

  "topology_map": {
    "node_scale": 1.5,
    "edge_scale": 1.5
  }
}
EOF

########################################
# LOGS
########################################

touch logs/history.jsonl
touch logs/controller_trace.jsonl
touch logs/class_transforms.jsonl

########################################
# MORPHISMS
########################################

cat > morphisms/registry/index.json << 'EOF'
{
  "morphisms": []
}
EOF

cat > morphisms/registry/entries/morph_identity.json << 'EOF'
{
  "id": "morph_identity",
  "name": "identity",
  "type": "symbolic",
  "domain": "scalar_field",
  "codomain": "scalar_field",
  "properties": ["identity"],
  "definition": "lambda x: x"
}
EOF

########################################
# PYTHON: MORPHISM CORE
########################################

cat > python/morphism_apply.py << 'EOF'
import sys, json, subprocess
from common.common_io import load_json, save_json

morph_file, input_file, output_file = sys.argv[1:4]

m = load_json(morph_file)
X = load_json(input_file)

# composite morphism
if m.get("type") == "composite":
    current = X
    for p in m.get("sequence", []):
        tmp_in = "/tmp/_current.json"
        tmp_out = "/tmp/_morph_step.json"

        save_json(tmp_in, current)

        subprocess.run([
            "python3", "python/morphism_apply.py",
            p, tmp_in, tmp_out
        ], check=True)

        current = load_json(tmp_out)

    save_json(output_file, current)
    sys.exit(0)

# symbolic morphism
if m.get("definition"):
    f = eval(m["definition"])
    result = f(X)
    save_json(output_file, result)
    sys.exit(0)

# fallback: identity
save_json(output_file, X)
EOF

cat > python/compose_morphisms.py << 'EOF'
import sys
import subprocess
from common.common_io import save_json

rules = "state/typing_rules.yaml"
paths = sys.argv[1:-1]
out = sys.argv[-1]

for i in range(len(paths) - 1):
    subprocess.run([
        "python3", "python/check_composable.py",
        paths[i], paths[i + 1], rules
    ], check=True)

save_json(out, {
    "type": "composite",
    "sequence": paths,
    "properties": ["typed_composed"]
})
EOF

cat > python/discover_compositions.py << 'EOF'
import sys
import json
from collections import Counter
from common.common_io import save_json

history_file, output_file = sys.argv[1:3]

pairs = Counter()

with open(history_file, "r") as f:
    prev = None
    for line in f:
        row = json.loads(line)
        morph = row.get("morphism")
        score = row.get("score", -1e9)

        if prev and score > 0:
            pairs[(prev, morph)] += 1
        prev = morph

top = pairs.most_common(10)

results = []
for (a, b), _ in top:
    results.append({
        "type": "composite",
        "sequence": [a, b],
        "properties": ["composed"]
    })

save_json(output_file, results)
EOF

cat > python/abstract_morphism.py << 'EOF'
import sys
from common.common_io import load_json, save_json

composite_file, output_file = sys.argv[1:3]

m = load_json(composite_file)
seq = m.get("sequence", [])

save_json(output_file, {
    "type": "abstracted",
    "source_sequence": seq,
    "properties": ["abstracted"]
})
EOF

cat > python/admit_morphism.py << 'EOF'
import sys
import uuid
import os
from common.common_io import load_json, save_json

morphism_file, score_file, registry_dir = sys.argv[1:4]

m = load_json(morphism_file)
score = load_json(score_file).get("score", -1e9)

THRESHOLD = -0.5  # tune this

# Reject low-quality morphisms
if score < THRESHOLD:
    sys.exit(0)

# Ensure registry structure exists
entries_dir = os.path.join(registry_dir, "entries")
os.makedirs(entries_dir, exist_ok=True)

index_file = os.path.join(registry_dir, "index.json")

# Load or initialize index
if os.path.exists(index_file):
    index = load_json(index_file)
else:
    index = {"morphisms": []}

# Generate unique ID
mid = "morph_" + uuid.uuid4().hex[:8]

entry = {
    "id": mid,
    "operator": m,
    "properties": m.get("properties", []),
    "created_from": morphism_file,
    "contexts": [],
    "usage_count": 0,
    "success_count": 0,
    "score_mean": score,
    "score_var": 0.0
}

# Write entry
entry_path = os.path.join(entries_dir, f"{mid}.json")
save_json(entry_path, entry)

# Update index
index["morphisms"].append(mid)
save_json(index_file, index)
EOF

cat > python/update_registry_stats.py << 'EOF'
import sys
from common.common_io import load_json, save_json

entry_file, score_file = sys.argv[1:3]

entry = load_json(entry_file)
score = load_json(score_file).get("score", 0.0)

n = entry.get("usage_count", 0)
mean = entry.get("score_mean", 0.0)
m2 = entry.get("score_var", 0.0)

new_n = n + 1
delta = score - mean
new_mean = mean + delta / new_n
delta2 = score - new_mean
new_m2 = m2 + delta * delta2

entry["usage_count"] = new_n
entry["score_mean"] = new_mean
entry["score_var"] = (new_m2 / new_n) if new_n > 0 else 0.0

if score > 0:
    entry["success_count"] = entry.get("success_count", 0) + 1

save_json(entry_file, entry)
EOF

cat > python/prune_registry.py << 'EOF'
import sys
import os
from common.common_io import load_json, save_json

registry_dir = sys.argv[1]

entries_dir = os.path.join(registry_dir, "entries")
index_file = os.path.join(registry_dir, "index.json")

if not os.path.exists(index_file):
    save_json(index_file, {"morphisms": []})
    sys.exit(0)

index = load_json(index_file)
kept = []

for mid in index.get("morphisms", []):
    path = os.path.join(entries_dir, f"{mid}.json")
    if not os.path.exists(path):
        continue

    entry = load_json(path)
    usage = entry.get("usage_count", 0)
    score_mean = entry.get("score_mean", -1e9)

    if usage > 10 and score_mean < -1.0:
        os.remove(path)
    else:
        kept.append(mid)

index["morphisms"] = kept
save_json(index_file, index)
EOF

cat > python/query_registry.py << 'EOF'
import sys
import os
from common.common_io import load_json, save_json

context_file, registry_dir, output_file = sys.argv[1:4]

ctx = load_json(context_file)

def dist(c1, c2):
    total = 0.0
    shared = False
    for k in c1:
        if k in c2 and isinstance(c1[k], (int, float)) and isinstance(c2[k], (int, float)):
            total += (c1[k] - c2[k]) ** 2
            shared = True
    return total if shared else 0.0

results = []

entries_dir = os.path.join(registry_dir, "entries")
if os.path.isdir(entries_dir):
    for fname in os.listdir(entries_dir):
        if not fname.endswith(".json"):
            continue
        entry = load_json(os.path.join(entries_dir, fname))

        contexts = entry.get("contexts", [])
        if not contexts:
            results.append((entry.get("score_mean", -1e9), entry.get("operator")))
            continue

        best = None
        for c in contexts:
            d = dist(ctx, c)
            score = entry.get("score_mean", -1e9) - d
            if best is None or score > best:
                best = score

        results.append((best if best is not None else -1e9, entry.get("operator")))

results.sort(reverse=True, key=lambda x: x[0])

top = [r[1] for r in results[:5] if r[1] is not None]

save_json(output_file, {"candidates": top})
EOF

cat > python/transfer_morphism.py << 'EOF'
import sys
from common.common_io import load_json, save_json

morphism_file, transfer_file, output_file = sys.argv[1:4]

m = load_json(morphism_file)
tr = load_json(transfer_file)

type_map = tr.get("type_map", {})
topo_map = tr.get("topology_map", {})

out = dict(m)

if "domain" in m:
    out["domain"] = type_map.get(m["domain"], m["domain"])
if "codomain" in m:
    out["codomain"] = type_map.get(m["codomain"], m["codomain"])

node_scale = topo_map.get("node_scale", 1.0)
edge_scale = topo_map.get("edge_scale", 1.0)

if "bias_phi" in out:
    out["bias_phi"] = out["bias_phi"] * node_scale
if "bias_s" in out:
    out["bias_s"] = out["bias_s"] * node_scale
if "bias_flux" in out:
    out["bias_flux"] = out["bias_flux"] * edge_scale

out["transferred_from"] = morphism_file
out["transfer_map"] = transfer_file
out["properties"] = sorted(set(out.get("properties", []) + ["transferred"]))

save_json(output_file, out)
EOF

cat > python/transfer_registry_slice.py << 'EOF'
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
EOF

cat > python/check_functoriality.py << 'EOF'
import sys
from common.common_io import load_json, save_json

source_file, transferred_file, output_file = sys.argv[1:4]

src = load_json(source_file)
tgt = load_json(transferred_file)

score = 1.0

if src.get("domain") != tgt.get("domain") and "transferred" not in tgt.get("properties", []):
    score -= 0.5

if src.get("codomain") != tgt.get("codomain") and tgt.get("codomain") is not None:
    score -= 0.25

if "transferred_from" not in tgt:
    score -= 0.25

save_json(output_file, {
    "functoriality_score": max(0.0, score)
})
EOF

cat > python/check_composable.py << 'EOF'
import sys
import yaml
from common.common_io import load_json

m1_file, m2_file, rules_file = sys.argv[1:4]

m1 = load_json(m1_file)
m2 = load_json(m2_file)

with open(rules_file, "r") as f:
    rules = yaml.safe_load(f)

cod1 = m1.get("codomain")
dom2 = m2.get("domain")

allowed = rules.get(cod1, [])

if dom2 in allowed:
    print("OK")
    sys.exit(0)
else:
    print("INVALID")
    sys.exit(1)
EOF

cat > python/type_path_resolver.py << 'EOF'
import sys, yaml
from collections import deque

rules_file, src, tgt = sys.argv[1:4]

rules = yaml.safe_load(open(rules_file))

queue = deque([(src, [src])])
visited = set()

while queue:
    cur, path = queue.popleft()
    if cur == tgt:
        print("->".join(path))
        sys.exit(0)
    for nxt in rules.get(cur, []):
        if nxt not in visited:
            visited.add(nxt)
            queue.append((nxt, path + [nxt]))

print("NO_PATH")
sys.exit(1)
EOF

cat > python/propose_type_bridge.py << 'EOF'
import sys
from common.common_io import save_json

src, tgt, output = sys.argv[1:4]

save_json(output, {
  "type": "symbolic",
  "domain": src,
  "codomain": tgt,
  "properties": ["bridge"]
})
EOF

cat > python/score_rollout.py << 'EOF'
import sys
import numpy as np
from common.common_io import load_json, save_json

def score(traj):
    phi = [t.get("Phi", 0.0) for t in traj]
    s = [t.get("S", 0.0) for t in traj]

    entropy_growth = float(sum(np.diff(s))) if len(s) > 1 else 0.0
    instability = float(np.var(phi)) if len(phi) > 0 else 0.0

    return -entropy_growth - instability

if __name__ == "__main__":
    in_file, out_file = sys.argv[1:3]
    data = load_json(in_file)
    traj = data.get("trajectory", data if isinstance(data, list) else [])
    save_json(out_file, {"score": score(traj)})
EOF

########################################
# CONTROLLERS
########################################

cat > controllers/registry/beam.json << 'EOF'
{"type": "beam", "width": 3}
EOF

cat > controllers/registry/dp.json << 'EOF'
{"type": "dp"}
EOF

cat > controllers/registry/learned.json << 'EOF'
{"type": "learned"}
EOF

cat > controllers/registry/spatial.json << 'EOF'
{"type": "spatial"}
EOF

cat > controllers/registry/repair.json << 'EOF'
{"type": "repair"}
EOF

cat > controllers/state/controller_state.json << 'EOF'
{
  "id": "learned",
  "parameters": {
    "attention_span": 3,
    "planning_horizon": 2
  },
  "history": [],
  "stability_score": 0.0
}
EOF

########################################
# CONTROLLER TRANSFORMS
########################################

cat > controllers/transformations/beam_to_learned.json << 'EOF'
{
  "source": "beam",
  "target": "learned",
  "type": "policy_transform",
  "mapping": {
    "beam_width": "attention_span",
    "depth": "planning_horizon"
  },
  "weight": 0.7
}
EOF

########################################
# QUOTIENT
########################################

cat > controllers/quotient/classes.json << 'EOF'
{
  "classes": []
}
EOF

cat > controllers/quotient/class_0001.json << 'EOF'
{
  "class_id": "class_0001",
  "members": [
    "beam"
  ],
  "representative": "beam",
  "stability_mean": 6.2,
  "stability_var": 0.4,
  "invariant_features": {
    "search_depth": "low",
    "entropy_regime": "high"
  }
}
EOF

cat > controllers/quotient/class_0002.json << 'EOF'
{
  "class_id": "class_0002",
  "members": [
    "learned"
  ],
  "representative": "learned",
  "stability_mean": 3.0,
  "stability_var": 0.2,
  "invariant_features": {
    "search_depth": "minimal",
    "entropy_regime": "low"
  }
}
EOF

cat > controllers/quotient/representatives.json << 'EOF'
{
  "beam": "beam",
  "learned": "learned"
}
EOF

########################################
# CONTROLLER PYTHON
########################################

cat > python/apply_controller_transform.py << 'EOF'
import sys
from common.common_io import load_json, save_json

ctrl_file, transform_file, output_file = sys.argv[1:4]

ctrl = load_json(ctrl_file)
tr = load_json(transform_file)

out = dict(ctrl)
out["id"] = tr["target"]
out["transformed_from"] = ctrl["id"]
out["properties"] = sorted(set(out.get("properties", []) + ["transformed"]))

save_json(output_file, out)
EOF

cat > python/learn_controller_transform.py << 'EOF'
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
EOF

cat > python/iterate_controller.py << 'EOF'
import sys
from common.common_io import load_json, save_json

ctrl_file, transform_file, output_file = sys.argv[1:4]

ctrl = load_json(ctrl_file)
tr = load_json(transform_file)

new_ctrl = dict(ctrl)

new_ctrl["id"] = tr["target"]
new_ctrl["history"] = ctrl.get("history", []) + [ctrl["id"]]
new_ctrl["transformed_from"] = ctrl["id"]

save_json(output_file, new_ctrl)
EOF

cat > python/controller_distance.py << 'EOF'
import sys
from common.common_io import load_json, save_json

c1_file, c2_file, output = sys.argv[1:4]

c1 = load_json(c1_file)
c2 = load_json(c2_file)

dist = 0.0

if c1["id"] != c2["id"]:
    dist += 1.0

p1 = c1.get("parameters", {})
p2 = c2.get("parameters", {})

for k in set(p1) | set(p2):
    dist += abs(p1.get(k, 0) - p2.get(k, 0))

save_json(output, {"distance": dist})
EOF

cat > python/check_fixed_point.py << 'EOF'
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
EOF

cat > python/update_stability.py << 'EOF'
import sys
from common.common_io import load_json, save_json

ctrl_file, fp_file = sys.argv[1:3]

ctrl = load_json(ctrl_file)
fp = load_json(fp_file)

score = ctrl.get("stability_score", 0.0)

if fp["fixed_point"]:
    score += 1.0
else:
    score *= 0.9

ctrl["stability_score"] = score

save_json(ctrl_file, ctrl)
EOF

cat > python/controller_equivalence.py << 'EOF'
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
EOF

cat > python/build_controller_classes.py << 'EOF'
import sys, os
from common.common_io import load_json, save_json

controllers_dir, output = sys.argv[1:3]

files = [f for f in os.listdir(controllers_dir) if f.endswith(".json")]

classes = []
EPS = 0.5

def dist(a, b):
    d = 0.0
    if a["id"] != b["id"]:
        d += 0.5
    for k in set(a.get("parameters", {})) | set(b.get("parameters", {})):
        d += abs(a["parameters"].get(k, 0) - b["parameters"].get(k, 0))
    return d

for f in files:
    c = load_json(os.path.join(controllers_dir, f))
    placed = False

    for cls in classes:
        if dist(c, cls[0]) < EPS:
            cls.append(c)
            placed = True
            break

    if not placed:
        classes.append([c])

save_json(output, {
    "classes": [
        [c["id"] for c in cls] for cls in classes
    ]
})
EOF

cat > python/select_representatives.py << 'EOF'
import sys
from common.common_io import load_json, save_json

classes_file, controllers_dir, output = sys.argv[1:4]

data = load_json(classes_file)
classes = data["classes"]

reps = []

for cls in classes:
    best = None
    best_score = -1e9

    for cid in cls:
        c = load_json(f"{controllers_dir}/{cid}.json")
        score = c.get("stability_score", 0)

        if score > best_score:
            best_score = score
            best = cid

    reps.append(best)

save_json(output, {"representatives": reps})
EOF

cat > python/build_controller_quotient.py << 'EOF'
import sys, os
from common.common_io import load_json, save_json

controllers_dir, output = sys.argv[1:3]

files = [f for f in os.listdir(controllers_dir) if f.endswith(".json")]

EPS = 0.5

def dist(a, b):
    d = 0.0
    if a["id"] != b["id"]:
        d += 0.5
    for k in set(a.get("parameters", {})) | set(b.get("parameters", {})):
        d += abs(a["parameters"].get(k, 0) - b["parameters"].get(k, 0))
    return d

classes = []

for f in files:
    c = load_json(os.path.join(controllers_dir, f))
    placed = False

    for cls in classes:
        if dist(c, cls[0]) < EPS:
            cls.append(c)
            placed = True
            break

    if not placed:
        classes.append([c])

out = []
for i, cls in enumerate(classes):
    ids = [c["id"] for c in cls]

    # representative = highest stability
    best = max(cls, key=lambda x: x.get("stability_score", 0))

    out.append({
        "class_id": f"class_{i:04d}",
        "members": ids,
        "representative": best["id"],
        "stability_mean": sum(c.get("stability_score", 0) for c in cls) / len(cls)
    })

save_json(output, {"classes": out})
EOF

cat > python/split_classes.py << 'EOF'
import sys, os
from common.common_io import load_json, save_json

classes_file, out_dir = sys.argv[1:3]

os.makedirs(out_dir, exist_ok=True)

data = load_json(classes_file)

for cls in data["classes"]:
    cid = cls["class_id"]
    save_json(f"{out_dir}/{cid}.json", cls)
EOF

cat > python/select_controller_class.py << 'EOF'
import sys
from common.common_io import load_json, save_json

context_file, classes_file, output = sys.argv[1:4]

ctx = load_json(context_file)
classes = load_json(classes_file)["classes"]

best = None
best_score = -1e9

for cls in classes:
    score = cls.get("stability_mean", 0)

    # simple context weighting
    if ctx.get("mean_entropy", 0) > 0.7:
        score += 1.0

    if score > best_score:
        best_score = score
        best = cls

save_json(output, {
    "class_id": best["class_id"],
    "representative": best["representative"]
})
EOF

cat > python/log_class_transform.py << 'EOF'
import sys
from common.common_io import load_json, save_json

c1_file, c2_file, classes_file, output = sys.argv[1:5]

c1 = load_json(c1_file)
c2 = load_json(c2_file)
classes = load_json(classes_file)["classes"]

def find_class(cid):
    for cls in classes:
        if cid in cls["members"]:
            return cls["class_id"]
    return None

cl1 = find_class(c1["id"])
cl2 = find_class(c2["id"])

save_json(output, {
    "from_class": cl1,
    "to_class": cl2,
    "same_class": cl1 == cl2
})
EOF

cat > python/canonicalize_controller.py << 'EOF'
import sys
from common.common_io import load_json, save_json

ctrl_file, classes_file, output = sys.argv[1:4]

ctrl = load_json(ctrl_file)
classes = load_json(classes_file)["classes"]

for cls in classes:
    if ctrl["id"] in cls["members"]:
        save_json(output, {
            "id": cls["representative"],
            "canonical": True
        })
        sys.exit(0)

save_json(output, ctrl)
EOF

cat > python/meta_controller.py << 'EOF'
import sys
from common.common_io import load_json, save_json

context_file = "state/initial_state.json"
output = "/tmp/controller_choice.json"

ctx = load_json(context_file)

entropy = ctx.get("S", 0.0)
flux = sum(ctx.get("v", [0,0]))

if entropy > 0.7:
    chosen = "beam"
elif abs(flux) > 0.5:
    chosen = "spatial"
else:
    chosen = "learned"

save_json(output, {"controller": chosen})
print(f"Selected controller: {chosen}")
EOF

########################################
# ENGINE
########################################

cat > engine/apply_morphism.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

MORPH="$1"
INPUT="$2"
OUTPUT="$3"

python3 python/morphism_apply.py "$MORPH" "$INPUT" "$OUTPUT"
EOF
chmod +x engine/apply_morphism.sh

cat > engine/run_transfer.sh << 'EOF'
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
EOF
chmod +x engine/run_transfer.sh

cat > engine/run_controller_fixed_point.sh << 'EOF'
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
EOF
chmod +x engine/run_controller_fixed_point.sh

cat > engine/run_class_controller.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

CLASS_SELECTION="$1"

REP=$(jq -r '.representative' "$CLASS_SELECTION")

echo "Using representative controller: $REP"

cat "controllers/registry/$REP.json"
EOF
chmod +x engine/run_class_controller.sh

########################################
# RUN.SH (THOUGHT SYSTEM)
########################################

cat > run.sh << 'EOF'
#!/usr/bin/env bash
set -e

echo "== Yarncrawler Thought Loop =="

python3 python/meta_controller.py

bash engine/run_controller_fixed_point.sh

echo "Done"
EOF

chmod +x run.sh

########################################

echo "== DONE: system instantiated =="
