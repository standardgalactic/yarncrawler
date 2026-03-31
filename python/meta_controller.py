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
