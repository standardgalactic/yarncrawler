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
