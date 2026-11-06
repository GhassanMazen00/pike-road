"""Build one game character with MPFB (MakeHuman for Blender) and export it for Godot.

    blender --background --python tools/characters/build_character.py -- <spec.json> <out_dir> [--preview]

The spec is a small JSON (see tools/characters/cast/*.json): body sliders ("phenotype"), skin,
eyes, eyebrows, eyelashes, hair, clothes and an optional color tint per clothing item.
Output: <out_dir>/<name>.glb (Mixamo-compatible rig, baked body shape, simple PBR materials)
and optionally <name>_preview.png.
All MakeHuman system assets used here are CC0; some optional packs are CC-BY (see CREDITS.md).
"""
import json
import math
import os
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SPEC, OUT = argv[0], argv[1]
PREVIEW = "--preview" in argv

from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402

with open(SPEC, encoding="utf-8") as f:
    spec = json.load(f)
name = spec["name"]

# start from an empty scene
bpy.ops.wm.read_factory_settings(use_empty=True)

info = HumanService._create_default_human_info_dict()
info["name"] = name
info["phenotype"].update({k: v for k, v in spec.get("phenotype", {}).items() if k != "race"})
if "race" in spec.get("phenotype", {}):
    info["phenotype"]["race"] = spec["phenotype"]["race"]
for key in ["eyes", "eyebrows", "eyelashes", "teeth", "tongue", "hair", "skin_mhmat", "proxy"]:
    if key in spec:
        info[key] = spec[key]
info["clothes"] = spec.get("clothes", [])
info["rig"] = spec.get("rig", "mixamo")
info["skin_material_type"] = "MAKESKIN"      # plain textures: exports cleanly to glTF
info["eyes_material_type"] = "MAKESKIN"
info["clothes_material_type"] = "MAKESKIN"
info["targets"] = spec.get("targets", [])

# "materials": {"hair/short02/short02.mhclo": "short02/bogdan666_short_02_gray/bogdan666_short_02_gray.mhmat"}
# MPFB keys alternative materials by the asset's uuid, read from its .mhclo file.
from bl_ext.user_default.mpfb.services.locationservice import LocationService  # noqa: E402
alt = {}
for asset, mhmat in spec.get("materials", {}).items():
    path = os.path.join(LocationService.get_user_data(), asset)
    if not os.path.exists(path):
        path = os.path.join(LocationService.get_mpfb_data(), asset)
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            if line.startswith("uuid"):
                alt[line.split()[1].strip()] = mhmat
                break
info["alternative_materials"] = alt

settings = HumanService.get_default_deserialization_settings()
settings["subdiv_levels"] = 0
settings["material_instances"] = "NEVER"
basemesh = HumanService.deserialize_from_dict(info, settings)

meshes = [o for o in bpy.data.objects if o.type == "MESH"]
armature = next((o for o in bpy.data.objects if o.type == "ARMATURE"), None)

# bake body shape (MPFB keeps targets as shape keys) so the export is a plain skinned mesh
for o in meshes:
    if o.data.shape_keys:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)

# Clothing layers: push each garment out along its normals so skin and inner layers can't poke
# through, and outer layers (sweaters, jackets) cover the waistband of trousers underneath.
# Spec "offset" overrides per garment, in metres: {"sweater": 0.01}
LAYER_OFFSETS = [
    (("hooded", "jacket", "coat", "cardigan"), 0.007),
    (("sweater", "shirt", "blouse", "top", "tunic", "dress", "tee", "polo"), 0.004),
    (("jeans", "trousers", "pants", "skirt", "shorts"), 0.0015),
]
NO_OFFSET = ("body", "high-poly", "low-poly", "eyebrow", "eyelash", "teeth", "tongue", "hair", "braid",
             "ponytail", "bob", "long0", "short0", "shoe", "boot", "sneaker", "flat", "maryjane", "glasses", "hat")
overrides = spec.get("offset", {})
for o in meshes:
    lname = o.name.lower().split(".", 1)[-1]
    amount = None
    for key, value in overrides.items():
        if key.lower() in lname:
            amount = value
    if amount is None:
        if any(k in lname for k in NO_OFFSET):
            continue
        amount = next((v for keys, v in LAYER_OFFSETS if any(k in lname for k in keys)), 0.0)
    if amount:
        me = o.data
        for v in me.vertices:
            v.co += v.normal * amount
        me.update()
        print("LAYER", o.name, amount)

# accessories the MakeHuman packs don't have (deputy hat, badge, duty belt): see accessories.py
if spec.get("accessories"):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import accessories  # noqa: E402
    body = next(o for o in bpy.data.objects if o.type == "MESH" and o.name.endswith(".body"))
    for o in accessories.add(spec["accessories"], armature, body, name):
        meshes.append(o)

# Clothing tints (spec "tint") are applied in Godot by tools/characters/character_import.gd,
# because tint nodes don't survive glTF export.

os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
glb = os.path.join(OUT, name + ".glb")
bpy.ops.export_scene.gltf(
    filepath=glb, export_format="GLB", use_selection=False, export_apply=True,
    export_skins=True, export_animations=False, export_yup=True, export_image_format="AUTO")
print("EXPORTED", glb, "meshes:", [o.name for o in meshes], "rig:", armature.name if armature else None)

if PREVIEW:
    scene = bpy.context.scene
    zmax = max((o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices[:1]) if meshes else 1.8
    height = max(max((o.matrix_world @ v.co).z for v in o.data.vertices) for o in meshes)
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    dist = height * 1.6 + 0.6
    cam.location = (0.35 * dist, -dist, height * 0.6)
    cam.rotation_euler = (math.radians(88), 0, math.radians(19))
    cam_data.lens = 50
    scene.camera = cam
    for loc, energy in [((2, -3, 3), 600), ((-3, -2, 2), 250), ((0, 3, 3), 300)]:
        ld = bpy.data.lights.new("l", "AREA")
        ld.energy = energy
        ld.size = 2
        lo = bpy.data.objects.new("l", ld)
        lo.location = loc
        lo.rotation_euler = (0, 0, 0)
        con = lo.constraints.new("TRACK_TO")
        con.target = cam  # aim roughly at the subject via the camera line
        lo.constraints.remove(con)
        lo.rotation_euler = ((math.atan2(math.hypot(loc[0], loc[1]), loc[2] - height * 0.6)), 0, math.atan2(loc[1], loc[0]) + math.pi / 2)
        scene.collection.objects.link(lo)
    world = bpy.data.worlds.new("w")
    world.color = (0.05, 0.05, 0.06)
    scene.world = world
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 960
    scene.render.filepath = os.path.join(OUT, name + "_preview.png")
    bpy.ops.render.render(write_still=True)
    print("PREVIEW", scene.render.filepath)
