"""Check that every asset a cast spec names exists in the MPFB data folder.
usage: python -I tools/characters/check_specs.py <mpfb_data_dir> <spec.json>...
"""
import json
import os
import sys

data = sys.argv[1]
bad = 0
for spec_path in sys.argv[2:]:
    s = json.load(open(spec_path, encoding="utf-8"))
    miss = []
    for key in ["eyes", "eyebrows", "eyelashes", "hair"]:
        if s.get(key) and not os.path.exists(os.path.join(data, key, s[key])):
            miss.append(key + ": " + s[key])
    for c in s.get("clothes", []):
        if not os.path.exists(os.path.join(data, "clothes", c)):
            miss.append("clothes: " + c)
    if not os.path.exists(os.path.join(data, "skins", s["skin_mhmat"])):
        miss.append("skin: " + s["skin_mhmat"])
    for asset, mat in s.get("materials", {}).items():
        sub = asset.split("/")[0]
        if not os.path.exists(os.path.join(data, asset)):
            miss.append("asset: " + asset)
        if not os.path.exists(os.path.join(data, sub, mat)):
            miss.append("material: " + mat)
    print(os.path.basename(spec_path), "OK" if not miss else miss)
    bad += bool(miss)
sys.exit(1 if bad else 0)
