"""Render the whole cast side by side for review.
    blender --background --python tools/characters/lineup.py -- <out.png> <glb>...
"""
import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
out, files = argv[0], argv[1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

x = 0.0
tallest = 0.0
for f in files:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=f)
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    meshes = [o for o in new if o.type == "MESH"]
    xs = [(o.matrix_world @ v.co).x for o in meshes for v in list(o.data.vertices)[::50]]
    zs = [(o.matrix_world @ v.co).z for o in meshes for v in list(o.data.vertices)[::50]]
    width = max(xs) - min(xs)
    tallest = max(tallest, max(zs))
    for r in roots:
        r.location.x += x - min(xs)
    x += width + 0.35

cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
center = x / 2
cam_data.type = "ORTHO"
cam_data.ortho_scale = max(x, tallest * 1.8) * 1.05
cam.location = (center, -12, tallest * 0.52)
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam

for loc, energy in [((center - 4, -6, 4), 2500), ((center + 5, -5, 3), 1200), ((center, 4, 4), 1500)]:
    ld = bpy.data.lights.new("l", "AREA")
    ld.energy = energy
    ld.size = 6
    lo = bpy.data.objects.new("l", ld)
    lo.location = loc
    direction = (center - loc[0], 0 - loc[1], tallest * 0.5 - loc[2])
    lo.rotation_euler = direction_to_euler = (0, 0, 0)
    lo.rotation_mode = "QUATERNION"
    from mathutils import Vector
    lo.rotation_quaternion = Vector(direction).to_track_quat("-Z", "Y")
    scene.collection.objects.link(lo)

world = bpy.data.worlds.new("w")
world.color = (0.04, 0.04, 0.05)
scene.world = world
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.resolution_x = 1800
scene.render.resolution_y = int(1800 * tallest * 1.15 / max(x, 1))
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("LINEUP", out)
