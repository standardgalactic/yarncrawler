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
