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
