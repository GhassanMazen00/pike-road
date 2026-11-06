"""Procedural accessories for MPFB characters (things the MakeHuman packs don't have).

Each accessory is a small mesh fitted to the character's measured body and skinned 100% to one
bone of the Mixamo rig, so it moves with the character and exports with the skin.
Used by build_character.py via the spec key "accessories": ["deputy_hat", "deputy_badge", "duty_belt"].
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector


# ---------------------------------------------------------------- helpers

def _material(name, color, metallic=0.0, roughness=0.8):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def _bone_world(armature, bone_name):
    b = armature.data.bones[bone_name]
    return armature.matrix_world @ b.head_local, armature.matrix_world @ b.tail_local


def _body_points(body):
    """Rest-pose skin vertices. Uses the raw mesh (MPFB's modifiers delete skin hidden under
    clothes) and only the "body" vertex group (skips MakeHuman's helper geometry)."""
    group = body.vertex_groups.get("body")
    pts = []
    for v in body.data.vertices:
        if group is None or any(g.group == group.index and g.weight > 0.5 for g in v.groups):
            pts.append(body.matrix_world @ v.co)
    return pts


def _finish(name, bm, mat, armature, bone, character):
    me = bpy.data.meshes.new(character + "." + name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(character + "." + name, me)
    bpy.context.scene.collection.objects.link(obj)
    if isinstance(mat, list):
        for m in mat:
            me.materials.append(m)
    else:
        me.materials.append(mat)
    vg = obj.vertex_groups.new(name=bone)
    vg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
    obj.parent = armature
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = armature
    return obj


def _box(bm, center, size, rot=Matrix.Identity(3), mat_index=0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    verts = res["verts"]
    for v in verts:
        v.co = rot @ Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) + center
    for f in {f for v in verts for f in v.link_faces}:
        f.material_index = mat_index
    return verts


def _cylinder(bm, center, radius, depth, segs=16, rot=Matrix.Identity(3), mat_index=0):
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=depth)
    for v in res["verts"]:
        v.co = rot @ v.co + center
    for f in {f for v in res["verts"] for f in v.link_faces}:
        f.material_index = mat_index
    return res["verts"]


# ---------------------------------------------------------------- accessories

def deputy_hat(armature, body, character):
    """Campaign ("Smokey") hat: wide flat brim, tall crown with the four-dent Montana pinch."""
    pts = _body_points(body)
    head, _ = _bone_world(armature, "mixamorig:Head")
    top = max(p.z for p in pts)
    near = [p for p in pts if p.z > top - 0.06]
    cx = sum(p.x for p in near) / len(near)
    cy = sum(p.y for p in near) / len(near)
    band = [p for p in pts if top - 0.11 < p.z < top - 0.07]
    rx = (max(p.x for p in band) - min(p.x for p in band)) / 2 + 0.012
    ry = (max(p.y for p in band) - min(p.y for p in band)) / 2 + 0.012
    base_z = top - 0.085          # hat sits low on the forehead
    crown_h = 0.135
    felt = _material("deputy_hat_felt", (0.42, 0.33, 0.21), roughness=0.95)
    band_mat = _material("deputy_hat_band", (0.12, 0.08, 0.05), roughness=0.6)
    bm = bmesh.new()
    segs = 32
    # brim: an annulus, slightly thicker toward the crown
    rings = [(1.0, 0.0), (1.9, -0.004), (2.05, -0.006)]
    brim = []
    for scale, dz in rings:
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            ring.append(bm.verts.new((cx + math.cos(a) * rx * scale, cy + math.sin(a) * ry * scale, base_z + dz)))
        brim.append(ring)
    lower = [[bm.verts.new((v.co.x, v.co.y, v.co.z - 0.008)) for v in ring] for ring in brim]
    for r in range(len(rings) - 1):
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((brim[r][i], brim[r][j], brim[r + 1][j], brim[r + 1][i]))
            bm.faces.new((lower[r][i], lower[r + 1][i], lower[r + 1][j], lower[r][j]))
    for i in range(segs):
        j = (i + 1) % segs
        bm.faces.new((brim[-1][i], brim[-1][j], lower[-1][j], lower[-1][i]))
    # crown: tapering walls, top pinched into four dents
    walls = []
    for k, (h, s) in enumerate([(0.0, 1.0), (0.04, 0.99), (0.09, 0.95), (crown_h, 0.86)]):
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            z = base_z + h
            if k == 3:
                z -= 0.025 * (0.5 + 0.5 * math.cos(4 * a))  # Montana pinch
            ring.append(bm.verts.new((cx + math.cos(a) * rx * s, cy + math.sin(a) * ry * s, z)))
        walls.append(ring)
    for r in range(len(walls) - 1):
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new((walls[r][i], walls[r][j], walls[r + 1][j], walls[r + 1][i]))
            f.material_index = 1 if r == 0 else 0
    peak = bm.verts.new((cx, cy, base_z + crown_h - 0.03))
    for i in range(segs):
        bm.faces.new((walls[-1][i], walls[-1][(i + 1) % segs], peak))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _finish("deputy_hat", bm, [felt, band_mat], armature, "mixamorig:Head", character)


def _chest_point(pts, side, height, x=0.1):
    """Front surface of the chest at a height and sideways offset, character's left (+1) or right (-1)."""
    zone = [p for p in pts if abs(p.z - height) < 0.02 and abs(side * p.x - x) < 0.015]
    front = min(zone, key=lambda p: p.y)  # MakeHuman faces -Y
    return front


def deputy_badge(armature, body, character):
    """Six-point sheriff's star on the left chest, plus a name bar on the right."""
    pts = _body_points(body)
    spine, _ = _bone_world(armature, "mixamorig:Spine2")
    h = spine.z + 0.065  # above the breast pocket
    gold = _material("deputy_badge_gold", (0.83, 0.64, 0.25), metallic=1.0, roughness=0.3)
    bm = bmesh.new()
    p = _chest_point(pts, +1, h)
    c = Vector((p.x, p.y - 0.012, p.z))   # just in front of the shirt
    r_out, r_in, thick = 0.032, 0.016, 0.004
    front, back = [], []
    for i in range(12):
        a = math.pi / 2 + i * math.pi / 6
        r = r_out if i % 2 == 0 else r_in
        x, z = math.cos(a) * r, math.sin(a) * r
        front.append(bm.verts.new((c.x + x, c.y, c.z + z)))
        back.append(bm.verts.new((c.x + x, c.y + thick, c.z + z)))
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(12):
        j = (i + 1) % 12
        bm.faces.new((front[i], back[i], back[j], front[j]))
    for i in range(0, 12, 2):  # ball tips
        a = math.pi / 2 + i * math.pi / 6
        tip = Vector((c.x + math.cos(a) * r_out, c.y - 0.001, c.z + math.sin(a) * r_out))
        res = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=6, radius=0.0045)
        for v in res["verts"]:
            v.co += tip
    # name bar on the right chest
    q = _chest_point(pts, -1, h)
    _box(bm, Vector((q.x, q.y - 0.01, q.z)), (0.06, 0.004, 0.012))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _finish("deputy_badge", bm, gold, armature, "mixamorig:Spine2", character)


def duty_belt(armature, body, character):
    """Black leather duty belt: holstered pistol (right), radio and cuff case (left), flashlight."""
    pts = _body_points(body)
    hips, _ = _bone_world(armature, "mixamorig:Hips")
    z = hips.z + 0.075   # high enough to cover the gap between shirt hem and trousers
    # torso only: in the rest pose the hands hang at hip height
    ring = [p for p in pts if abs(p.z - z) < 0.02 and abs(p.x - hips.x) < 0.26]
    cx = (max(p.x for p in ring) + min(p.x for p in ring)) / 2
    cy = (max(p.y for p in ring) + min(p.y for p in ring)) / 2
    rx = (max(p.x for p in ring) - min(p.x for p in ring)) / 2 + 0.018  # over the clothes
    ry = (max(p.y for p in ring) - min(p.y for p in ring)) / 2 + 0.018
    leather = _material("duty_belt_leather", (0.03, 0.03, 0.03), roughness=0.45)
    steel = _material("duty_belt_steel", (0.55, 0.55, 0.58), metallic=1.0, roughness=0.35)
    grip = _material("duty_belt_grip", (0.07, 0.07, 0.07), roughness=0.7)
    bm = bmesh.new()
    segs, height, thick = 40, 0.075, 0.012
    rows = []
    for dz, off in [(-height / 2, 0.0), (height / 2, 0.0), (height / 2, thick), (-height / 2, thick)]:
        r = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            r.append(bm.verts.new((cx + math.cos(a) * (rx + off), cy + math.sin(a) * (ry + off), z + dz)))
        rows.append(r)
    for k in range(4):
        for i in range(segs):
            j = (i + 1) % segs
            bm.faces.new((rows[k][i], rows[k][j], rows[(k + 1) % 4][j], rows[(k + 1) % 4][i]))

    def on_belt(angle, out=0.0):
        return Vector((cx + math.cos(angle) * (rx + thick + out), cy + math.sin(angle) * (ry + thick + out), z))

    def facing(angle):
        return Matrix.Rotation(angle + math.pi / 2, 3, "Z")

    # buckle (front)
    _box(bm, on_belt(-math.pi / 2, 0.004), (0.06, 0.008, 0.045), facing(-math.pi / 2), mat_index=1)
    # holster + pistol grip on the character's right hip (-X side)
    a = math.pi + 0.35
    hc = on_belt(a, 0.03) + Vector((0, 0, -0.07))
    _box(bm, hc, (0.05, 0.045, 0.19), facing(a), mat_index=0)
    _box(bm, hc + Vector((0, 0, 0.13)) + facing(a) @ Vector((0, 0.01, 0)), (0.035, 0.03, 0.08),
         facing(a) @ Matrix.Rotation(0.25, 3, "Y"), mat_index=2)
    # radio on the left back, cuff case on the left front, flashlight ring on the left
    _box(bm, on_belt(0.55, 0.03) + Vector((0, 0, -0.02)), (0.06, 0.035, 0.11), facing(0.55), mat_index=2)
    _cylinder(bm, on_belt(0.55, 0.03) + Vector((0.0, 0.0, 0.065)), 0.006, 0.08, 8, mat_index=2)
    _box(bm, on_belt(-0.6, 0.02), (0.07, 0.03, 0.05), facing(-0.6), mat_index=0)
    _cylinder(bm, on_belt(-1.05, 0.03) + Vector((0, 0, -0.06)), 0.016, 0.2, 12, mat_index=1)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _finish("duty_belt", bm, [leather, steel, grip], armature, "mixamorig:Hips", character)


BUILDERS = {"deputy_hat": deputy_hat, "deputy_badge": deputy_badge, "duty_belt": duty_belt}


def add(names, armature, body, character):
    made = []
    for n in names:
        made.append(BUILDERS[n](armature, body, character))
    return made
