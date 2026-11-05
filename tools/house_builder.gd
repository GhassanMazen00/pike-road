extends SceneTree
## Generates scenes/house/house_shell.tscn: the whole Pike house (walls, floors, stairs,
## doors, windows, lights, switches, room areas) plus furniture, from the tables below.
##
##   godot --headless --path . --script res://tools/house_builder.gd
##
## Coordinates: metres. X = west(-)/east(+), Z = north(-)/south(+), Y = up.
## The front door faces south. Rects are [x0, x1, z0, z1] of each room's inside.

const OUT := "res://scenes/house/house_shell.tscn"
var DOOR_SCRIPT: Script
var SWITCH_SCRIPT: Script
var ROOM_SCRIPT: Script

# level: [floor y, ceiling height]
const LEVELS := {"g": [0.0, 2.7], "u": [2.85, 2.65], "b": [-2.6, 2.35]}
const EXT_T := 0.2   # exterior wall thickness
const OUTER := [-6.2, 6.2, -5.2, 5.2]

# name, level, rect, floor, wall, light, surface, reverb
var ROOMS := [
	{"id": "living", "lv": "g", "r": [-6.0, -0.07, 0.07, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "chandelier", "surface": "wood", "reverb": "medium"},
	{"id": "kitchen", "lv": "g", "r": [-6.0, -0.07, -5.0, -0.07], "floor": "linoleum", "wall": "plaster_wall", "light": "bulb", "surface": "linoleum", "reverb": "medium"},
	{"id": "hall", "lv": "g", "r": [0.07, 2.13, -5.0, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "bulb", "light_at": [[0.6, -2.4], [0.6, 3.6]], "surface": "wood", "reverb": "small",
		"ceil_holes": [[1.07, 2.13, -0.5, 3.0]]},
	{"id": "study", "lv": "g", "r": [2.27, 6.0, -0.93, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "bulb", "surface": "wood", "reverb": "medium"},
	{"id": "utility", "lv": "g", "r": [2.27, 6.0, -3.79, -1.07], "floor": "linoleum", "wall": "plaster_wall", "light": "bulb", "surface": "linoleum", "reverb": "small"},
	{"id": "basement_stairs", "lv": "g", "r": [2.27, 6.0, -5.0, -3.93], "floor": "floor_wood", "wall": "plaster_wall", "light": "bulb", "light_at": [[4.2, -4.46]], "surface": "stairs", "reverb": "small",
		"floor_only": [2.27, 2.6, -5.0, -3.93], "cut_below": true, "switch_also": ["basement"]},
	{"id": "upstairs_hall", "lv": "u", "r": [0.07, 2.13, -5.0, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "bulb", "light_at": [[0.6, -2.5], [1.1, 4.2]], "surface": "wood", "reverb": "small",
		"floor_holes": [[1.07, 2.13, -0.5, 3.0]], "cut_below_rect": [1.07, 2.13, -0.5, 3.0]},
	{"id": "bedroom", "lv": "u", "r": [-6.0, -0.07, 1.44, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "bulb", "surface": "wood", "reverb": "small"},
	{"id": "closet", "lv": "u", "r": [-1.9, -0.07, -1.6, 1.3], "floor": "floor_wood", "wall": "plaster_wall", "light": "none", "surface": "wood", "reverb": "closet"},
	{"id": "bathroom", "lv": "u", "r": [-6.0, -2.04, -1.6, 1.3], "floor": "linoleum", "wall": "plaster_wall", "light": "none", "surface": "linoleum", "reverb": "tiled"},
	{"id": "june_room", "lv": "u", "r": [-6.0, -0.07, -5.0, -1.74], "floor": "floor_wood", "wall": "june_wall", "light": "bulb", "surface": "wood", "reverb": "small"},
	{"id": "spare_room", "lv": "u", "r": [2.27, 6.0, 0.07, 5.0], "floor": "floor_wood", "wall": "wallpaper", "light": "bulb", "surface": "wood", "reverb": "medium"},
	{"id": "storage", "lv": "u", "r": [2.27, 6.0, -5.0, -0.07], "floor": "floor_wood", "wall": "plaster_wall", "light": "bulb", "surface": "wood", "reverb": "medium"},
	{"id": "basement", "lv": "b", "r": [-6.0, 6.0, -5.0, 1.0], "floor": "concrete", "wall": "stone_wall", "ceil": "beam_wood", "light": "bulb2", "surface": "concrete", "reverb": "basement"},
]

# axis: "x" = wall at constant x (opening runs along z), "z" = wall at constant z.
# kind: door / open (no slab). swing: which side the door opens into.
var DOORS := [
	{"id": "front_door", "lv": "g", "axis": "z", "at": 5.1, "from": 0.6, "to": 1.5, "ext": true, "swing": "-z", "h": 2.1, "room": "hall"},
	{"id": "back_door", "lv": "g", "axis": "z", "at": -5.1, "from": 0.6, "to": 1.5, "ext": true, "swing": "+z", "h": 2.1, "room": "hall"},
	{"id": "living_arch", "lv": "g", "axis": "x", "at": 0.0, "from": 1.6, "to": 2.8, "kind": "open", "h": 2.3, "room": "living"},
	{"id": "kitchen_door", "lv": "g", "axis": "x", "at": 0.0, "from": -3.4, "to": -2.5, "swing": "-x", "h": 2.1, "room": "kitchen"},
	{"id": "kitchen_arch", "lv": "g", "axis": "z", "at": 0.0, "from": -3.6, "to": -2.4, "kind": "open", "h": 2.3, "room": "kitchen"},
	{"id": "study_door", "lv": "g", "axis": "x", "at": 2.2, "from": 4.1, "to": 4.95, "swing": "+x", "h": 2.1, "room": "study"},
	{"id": "utility_door", "lv": "g", "axis": "x", "at": 2.2, "from": -3.2, "to": -2.3, "swing": "+x", "h": 2.1, "room": "utility"},
	{"id": "basement_door", "lv": "g", "axis": "z", "at": -3.86, "from": 2.35, "to": 3.2, "swing": "+z", "h": 2.05, "room": "basement_stairs", "locked": true, "msg": "Locked."},
	{"id": "bedroom_door", "lv": "u", "axis": "x", "at": 0.0, "from": 3.0, "to": 3.9, "swing": "-x", "h": 2.05, "room": "bedroom"},
	{"id": "closet_door", "lv": "u", "axis": "z", "at": 1.37, "from": -1.5, "to": -0.7, "swing": "+z", "h": 2.0, "room": "closet"},
	{"id": "bathroom_door", "lv": "u", "axis": "z", "at": 1.37, "from": -3.6, "to": -2.8, "swing": "+z", "h": 2.0, "room": "bathroom", "locked": true, "msg": "It's stuck."},
	{"id": "june_door", "lv": "u", "axis": "x", "at": 0.0, "from": -3.9, "to": -3.0, "swing": "-x", "h": 2.05, "room": "june_room"},
	{"id": "spare_door", "lv": "u", "axis": "x", "at": 2.2, "from": 3.6, "to": 4.5, "swing": "+x", "h": 2.05, "room": "spare_room"},
	{"id": "storage_door", "lv": "u", "axis": "x", "at": 2.2, "from": -3.9, "to": -3.0, "swing": "+x", "h": 2.05, "room": "storage"},
]

# exterior windows: axis/at as doors; sill and top are heights above the level floor.
var WINDOWS := [
	{"lv": "g", "axis": "z", "at": 5.1, "from": -4.6, "to": -3.2, "sill": 0.9, "top": 2.2},
	{"lv": "g", "axis": "x", "at": -6.1, "from": 2.0, "to": 3.3, "sill": 0.9, "top": 2.2},
	{"lv": "g", "axis": "z", "at": -5.1, "from": -4.4, "to": -3.2, "sill": 1.05, "top": 2.1},
	{"lv": "g", "axis": "x", "at": -6.1, "from": -3.3, "to": -2.0, "sill": 0.9, "top": 2.2},
	{"lv": "g", "axis": "x", "at": 6.1, "from": 1.0, "to": 2.3, "sill": 0.9, "top": 2.2},
	{"lv": "g", "axis": "z", "at": 5.1, "from": 3.4, "to": 4.6, "sill": 0.9, "top": 2.2},
	{"lv": "g", "axis": "x", "at": 6.1, "from": -3.0, "to": -2.0, "sill": 1.2, "top": 2.0},
	{"lv": "u", "axis": "z", "at": 5.1, "from": -4.6, "to": -3.2, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "x", "at": -6.1, "from": 2.6, "to": 3.9, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "z", "at": -5.1, "from": -4.0, "to": -2.8, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "x", "at": -6.1, "from": -3.9, "to": -2.6, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "x", "at": 6.1, "from": 1.8, "to": 3.1, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "x", "at": 6.1, "from": -3.1, "to": -1.8, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "z", "at": -5.1, "from": 0.5, "to": 1.7, "sill": 0.9, "top": 2.25},
	{"lv": "u", "axis": "x", "at": -6.1, "from": -0.6, "to": 0.4, "sill": 1.2, "top": 2.0},
]

# model id, position, rotation y in degrees, optional {scale, collide, name}
var FURNITURE := [
	# living room (the sofa faces the TV on the west wall, its back to the hall arch)
	["vintage_wooden_drawer_01", Vector3(-5.54, 0, 2.6), 90, {"name": "TvDresser"}],
	["Television_01", Vector3(-5.62, 1.09, 2.6), 90, {"name": "Television", "collide": false}],
	["sofa_03", Vector3(-2.0, 0, 2.6), -90, {"name": "Sofa"}],
	["gothic_coffee_table", Vector3(-3.6, 0, 2.6), 0, {"name": "CoffeeTable"}],
	["side_table_tall_01", Vector3(-2.0, 0, 0.85), 0, {"name": "SideTable"}],
	["Rockingchair_01", Vector3(-5.2, -0.1016, 4.35), 137, {"name": "RockingChair"}],
	["vintage_grandfather_clock_01", Vector3(-1.0, 0, 4.8), 180, {"name": "GrandfatherClock"}],
	["vintage_cabinet_01", Vector3(-4.95, 0, 0.36), 0, {"name": "ChinaCabinet"}],
	["Chandelier_01", Vector3(-3.5, 2.65, 2.6), 0, {"name": "Chandelier", "scale": 0.82, "collide": false, "no_shadow": true}],
	["fancy_picture_frame_01", Vector3(-0.07, 1.6, 4.0), -90, {"collide": false}],
	["ornate_mirror_01", Vector3(-5.4, 1.55, 5.0), 180, {"collide": false}],
	["Ottoman_01", Vector3(-1.0, 0, 1.0), 20, {}],
	# kitchen
	["electric_stove", Vector3(-1.5, 0, -4.69), 0, {"name": "Stove"}],
	["vintage_microwave", Vector3(-3.1, 0.9, -4.6), 0, {"name": "Microwave", "scale": 0.8, "collide": false}],
	["vintage_electric_kettle", Vector3(-4.6, 0.9, -4.7), 20, {"collide": false}],
	["wooden_cutting_board", Vector3(-2.2, 0.9, -4.65), 5, {"collide": false}],
	["pot_enamel_01", Vector3(-1.6, 0.86, -4.7), 0, {"collide": false}],
	["painted_wooden_cabinet", Vector3(-5.7, 0, -1.6), 90, {"name": "KitchenHutch"}],
	["round_wooden_table_01", Vector3(-3.0, 0, -2.3), 0, {"name": "KitchenTable", "scale_v": Vector3(0.85, 0.76, 0.85)}],
	["dining_chair_02", Vector3(-3.0, 0, -1.4), 180, {}],
	["dining_chair_02", Vector3(-3.9, 0, -2.4), 90, {}],
	["dining_chair_02", Vector3(-2.1, 0, -2.4), -90, {}],
	["tea_set_01", Vector3(-3.0, 0.765, -2.4), 30, {"scale": 0.7, "collide": false}],
	["jug_01", Vector3(-5.6, 1.18, -1.4), 0, {"collide": false}],
	# hall
	["Shelf_01", Vector3(0.08, 0, -1.0), 90, {}],
	["hanging_picture_frame_02", Vector3(0.07, 1.65, 3.9), 90, {"collide": false}],
	# study
	["wooden_bookshelf_worn", Vector3(5.7, 0, 2.0), -90, {}],
	["WoodenTable_03", Vector3(4.0, 0, 4.65), 180, {"name": "Desk"}],
	["painted_wooden_chair_01", Vector3(4.0, 0, 4.0), 0, {}],
	["book_encyclopedia_set_01", Vector3(3.6, 0.83, 4.7), 180, {"collide": false}],
	["Lantern_01", Vector3(4.6, 0.83, 4.75), 0, {"collide": false}],
	["cardboard_box_01", Vector3(2.8, 0, 0.0), 15, {}],
	["cardboard_box_01", Vector3(3.3, 0, -0.4), -10, {}],
	# utility
	["worn_metal_rack", Vector3(5.65, 0, -2.4), -90, {}],
	["wooden_bucket_01", Vector3(4.8, 0, -1.4), 0, {}],
	["trashbag", Vector3(2.7, 0, -1.4), 30, {}],
	["crowbar_01", Vector3(5.5, 0.84, -2.2), 0, {"collide": false}],
	# bedroom
	["GothicBed_01", Vector3(-4.93, 2.85, 3.2), 90, {"name": "Bed"}],
	["ClassicNightstand_01", Vector3(-5.75, 2.85, 1.95), 90, {"name": "NightstandA"}],
	["ClassicNightstand_01", Vector3(-5.75, 2.85, 4.45), 90, {"name": "NightstandB"}],
	["GothicCabinet_01", Vector3(-1.5, 2.85, 1.98), 0, {"name": "Wardrobe"}],
	["vintage_suitcase", Vector3(-3.4, 2.85, 4.75), 175, {"name": "Suitcase"}],
	# June's room
	["vintage_day_bed", Vector3(-5.55, 2.85, -3.4), 90, {"name": "JuneBed"}],
	["painted_wooden_nightstand", Vector3(-5.7, 2.85, -2.2), 90, {}],
	["painted_wooden_chair_01", Vector3(-2.6, 2.85, -4.4), 200, {}],
	["rubber_duck_toy", Vector3(-3.6, 2.85, -2.6), 40, {"collide": false, "scale": 0.5}],
	# spare room and storage
	["cardboard_box_01", Vector3(5.5, 2.85, 4.5), 5, {}],
	["cardboard_box_01", Vector3(5.5, 3.19, 4.5), 80, {"collide": false}],
	["cardboard_box_01", Vector3(4.9, 2.85, 4.6), -20, {}],
	["old_military_crate", Vector3(4.3, 2.85, 0.8), 0, {}],
	["Ottoman_01", Vector3(3.2, 2.85, 2.0), -30, {}],
	["steel_frame_shelves_01", Vector3(5.7, 2.85, -2.6), -90, {"scale": 0.1}],
	["wooden_crate_01", Vector3(3.2, 2.85, -4.6), 0, {}],
	["wooden_crate_01", Vector3(3.2, 3.2, -4.6), 10, {"collide": false}],
	["Barrel_02", Vector3(2.8, 2.85, -0.6), 0, {}],
	# basement
	["WoodenTable_03", Vector3(-5.6, -2.6, -2.0), 90, {"name": "Workbench"}],
	["bench_vice_01", Vector3(-5.5, -1.77, -2.5), 90, {"collide": false}],
	["metal_toolbox", Vector3(-5.55, -1.77, -1.6), 80, {"collide": false}],
	["hatchet", Vector3(-5.45, -1.77, -2.05), 30, {"collide": false}],
	["steel_frame_shelves_01", Vector3(-2.0, -2.6, -4.7), 0, {"scale": 0.1}],
	["steel_frame_shelves_01", Vector3(0.6, -2.6, -4.7), 0, {"scale": 0.1}],
	["worn_metal_rack", Vector3(-5.65, -2.6, 0.3), 90, {}],
	["wooden_crate_01", Vector3(3.0, -2.6, 0.4), 0, {}],
	["wooden_crate_01", Vector3(3.0, -2.25, 0.4), 15, {"collide": false}],
	["old_military_crate", Vector3(-0.6, -2.6, 0.5), 180, {}],
	["Barrel_02", Vector3(5.5, -2.6, 0.5), 0, {}],
	["Barrel_02", Vector3(5.0, -2.6, 0.7), 0, {}],
	["cardboard_box_01", Vector3(-3.4, -2.6, 0.6), 0, {}],
	["rusted_spade_01", Vector3(-4.2, -2.1, 0.92), 0, {"collide": false}],
	["trashbag", Vector3(1.6, -2.6, 0.6), 0, {}],
	# outside
	["power_box_01", Vector3(3.6, 1.3, -5.2), 180, {"name": "FuseBox", "collide": false}],
	["security_light", Vector3(1.05, 2.45, -5.2), 180, {"collide": false}],
	["wooden_bucket_01", Vector3(-1.2, -0.6, -6.2), 0, {}],
]

var house: Node3D
var mats := {}


func _init() -> void:
	_build.call_deferred()


func _build() -> void:
	# loaded at run time, once the project's autoloads (Sounds, Power) exist
	DOOR_SCRIPT = load("res://scripts/hinged_door.gd")
	SWITCH_SCRIPT = load("res://scripts/light_switch.gd")
	ROOM_SCRIPT = load("res://scripts/room_area.gd")
	if DOOR_SCRIPT == null or SWITCH_SCRIPT == null or ROOM_SCRIPT == null:
		push_error("could not load gameplay scripts")
		quit(1)
		return
	house = Node3D.new()
	house.name = "HouseShell"
	_build_shell()
	_build_floors_and_ceilings()
	_build_stairs()
	_build_doors()
	_build_windows()
	_build_trim()
	_build_rooms_lights_switches()
	_build_outside()
	_build_furniture()
	var ps := PackedScene.new()
	var err := ps.pack(house)
	if err != OK:
		push_error("pack failed: %s" % err)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://scenes/house")
	err = ResourceSaver.save(ps, OUT)
	print("saved ", OUT, " err=", err)
	house.free()
	quit()


# ------------------------------------------------------------------ helpers

func mat(name: String) -> Material:
	if not mats.has(name):
		mats[name] = load("res://assets/materials/%s.tres" % name)
	return mats[name]


func own(node: Node) -> void:
	node.owner = house
	for c in node.get_children():
		own(c)


func add(parent: Node, node: Node, name: String) -> Node:
	node.name = name
	parent.add_child(node)
	node.owner = house
	return node


func csg_box(parent: Node, name: String, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float,
		material: String, op := CSGShape3D.OPERATION_UNION) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = Vector3(x1 - x0, y1 - y0, z1 - z0)
	b.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
	b.operation = op
	if material != "":
		b.material = mat(material)
	add(parent, b, name)
	return b


func mesh_box(parent: Node, name: String, center: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = center
	if material != "":
		m.material_override = mat(material)
	add(parent, m, name)
	return m


func level_y(lv: String) -> float:
	return LEVELS[lv][0]


func level_top(lv: String) -> float:
	return LEVELS[lv][0] + LEVELS[lv][1]


func room(id: String) -> Dictionary:
	for r in ROOMS:
		if r.id == id:
			return r
	return {}


## Splits rect minus holes into pieces (holes assumed to touch the rect's long sides).
func subtract_rects(r: Array, holes: Array) -> Array:
	var pieces := [r]
	for h in holes:
		var next := []
		for p in pieces:
			var ix0: float = max(p[0], h[0])
			var ix1: float = min(p[1], h[1])
			var iz0: float = max(p[2], h[2])
			var iz1: float = min(p[3], h[3])
			if ix0 >= ix1 or iz0 >= iz1:
				next.append(p)
				continue
			if p[2] < iz0: next.append([p[0], p[1], p[2], iz0])
			if iz1 < p[3]: next.append([p[0], p[1], iz1, p[3]])
			if p[0] < ix0: next.append([p[0], ix0, iz0, iz1])
			if ix1 < p[1]: next.append([ix1, p[1], iz0, iz1])
		pieces = next
	return pieces


# ------------------------------------------------------------------ structure

func _build_shell() -> void:
	var shell := CSGCombiner3D.new()
	shell.use_collision = true
	add(house,shell, "Shell")
	csg_box(shell, "Outer", OUTER[0], OUTER[1], -3.0, 5.75, OUTER[2], OUTER[3], "siding")
	for r in ROOMS:
		var y0 := level_y(r.lv) - 0.05
		var y1 := level_top(r.lv)
		if r.get("cut_below", false):
			y0 = -0.3
		var rr: Array = r.r
		csg_box(shell, "Cavity_" + r.id, rr[0], rr[1], y0, y1, rr[2], rr[3], r.wall, CSGShape3D.OPERATION_SUBTRACTION)
		if r.has("cut_below_rect"):
			var c: Array = r.cut_below_rect
			csg_box(shell, "Stairwell_" + r.id, c[0], c[1], level_y(r.lv) - 0.4, level_y(r.lv) + 0.1, c[2], c[3], r.wall, CSGShape3D.OPERATION_SUBTRACTION)
	for d in DOORS:
		var t := 0.6
		var y0: float = level_y(d.lv) - 0.01
		var y1: float = y0 + d.h
		var mat_name := "trim_wood"
		if d.axis == "x":
			csg_box(shell, "Opening_" + d.id, d.at - t * 0.5, d.at + t * 0.5, y0, y1, d.from, d.to, mat_name, CSGShape3D.OPERATION_SUBTRACTION)
		else:
			csg_box(shell, "Opening_" + d.id, d.from, d.to, y0, y1, d.at - t * 0.5, d.at + t * 0.5, mat_name, CSGShape3D.OPERATION_SUBTRACTION)
	var i := 0
	for w in WINDOWS:
		var y0: float = level_y(w.lv) + w.sill
		var y1: float = level_y(w.lv) + w.top
		if w.axis == "x":
			csg_box(shell, "Window_%d" % i, w.at - 0.3, w.at + 0.3, y0, y1, w.from, w.to, "trim_wood", CSGShape3D.OPERATION_SUBTRACTION)
		else:
			csg_box(shell, "Window_%d" % i, w.from, w.to, y0, y1, w.at - 0.3, w.at + 0.3, "trim_wood", CSGShape3D.OPERATION_SUBTRACTION)
		i += 1


func _build_floors_and_ceilings() -> void:
	var floors := Node3D.new()
	add(house,floors, "Floors")
	for r in ROOMS:
		var y := level_y(r.lv)
		var base: Array = r.get("floor_only", r.r)
		var pieces := subtract_rects(base, r.get("floor_holes", []))
		var k := 0
		for p in pieces:
			var f := csg_box(floors, "Floor_%s_%d" % [r.id, k], p[0], p[1], y - 0.06, y, p[2], p[3], r.floor)
			f.use_collision = true
			f.set_meta("surface", r.surface)
			k += 1
		if r.id == "basement_stairs":
			continue
		var top := level_top(r.lv)
		var cpieces := subtract_rects(r.r, r.get("ceil_holes", []))
		k = 0
		for p in cpieces:
			csg_box(floors, "Ceiling_%s_%d" % [r.id, k], p[0], p[1], top - 0.05, top + 0.01, p[2], p[3], r.get("ceil", "ceiling"))
			k += 1
	# floor under each door opening so there's no gap in the wall thickness
	for d in DOORS:
		var y := level_y(d.lv)
		var t := (EXT_T if d.get("ext", false) else 0.14) + 0.02
		var surf: String = room(d.room).get("surface", "wood")
		var f: CSGBox3D
		if d.axis == "x":
			f = csg_box(floors, "Threshold_" + d.id, d.at - t * 0.5, d.at + t * 0.5, y - 0.06, y, d.from, d.to, "trim_wood")
		else:
			f = csg_box(floors, "Threshold_" + d.id, d.from, d.to, y - 0.06, y, d.at - t * 0.5, d.at + t * 0.5, "trim_wood")
		f.use_collision = true
		f.set_meta("surface", "wood" if surf == "stairs" else surf)


func _build_stairs() -> void:
	var stairs := CSGCombiner3D.new()
	stairs.use_collision = true
	add(house,stairs, "Stairs")
	# main stairs in the hall: 18 steps rising north from z = 4.0 to z = -0.5
	var rise := 2.85 / 18.0
	for i in 18:
		csg_box(stairs, "Main_%02d" % i, 1.07, 2.13, 0.0, (i + 1) * rise, 4.0 - (i + 1) * 0.25, 4.0 - i * 0.25, "trim_wood")
	# railing (pony wall) around the stairwell upstairs
	var rail := CSGCombiner3D.new()
	rail.use_collision = true
	add(house,rail, "Railing")
	csg_box(rail, "Side", 0.99, 1.07, 2.85, 3.8, -0.5, 3.08, "trim_wood")
	csg_box(rail, "End", 0.99, 2.13, 2.85, 3.8, 3.0, 3.08, "trim_wood")
	# basement stairs: 14 steps going down east from x = 2.6 to x = 5.68, landing at the bottom
	var brise := 2.6 / 14.0
	for i in 14:
		csg_box(stairs, "Basement_%02d" % i, 2.6 + i * 0.22, 2.6 + (i + 1) * 0.22, -2.6, -(i + 1) * brise, -5.0, -3.93, "trim_wood")
	# smooth ramps for walking (invisible), tagged as stairs for footsteps
	var ramps := StaticBody3D.new()
	add(house,ramps, "StairRamps")
	ramps.set_meta("surface", "stairs")
	# the ramp line runs through every step's front edge, so the player never snags
	_ramp(ramps, "MainRamp", Vector3(1.6, 0, 4.25), Vector3(1.6, 2.85, -0.25), 1.06, "x")
	_ramp(ramps, "BasementRamp", Vector3(2.6, 0, -4.465), Vector3(5.68, -2.6, -4.465), 1.07, "z")


func _ramp(body: StaticBody3D, name: String, from: Vector3, to: Vector3, width: float, across: String) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var length := from.distance_to(to)
	box.size = Vector3(width, 0.1, length) if across == "x" else Vector3(length, 0.1, width)
	shape.shape = box
	var dir := (to - from).normalized()
	var mid := (from + to) * 0.5
	var basis: Basis
	if across == "x":
		var fwd := dir  # along local z
		var up := Vector3.UP - fwd * Vector3.UP.dot(fwd)
		up = up.normalized()
		basis = Basis(up.cross(fwd).normalized(), up, fwd)
	else:
		var fwd := dir  # along local x
		var up := Vector3.UP - fwd * Vector3.UP.dot(fwd)
		up = up.normalized()
		basis = Basis(fwd, up, fwd.cross(up).normalized())
	shape.transform = Transform3D(basis, mid - basis.y * 0.05)
	add(body, shape, name)


func _build_doors() -> void:
	var doors := Node3D.new()
	add(house,doors, "Doors")
	for d in DOORS:
		if d.get("kind", "door") == "open":
			continue
		var y := level_y(d.lv)
		var w: float = d.to - d.from - 0.02
		var h: float = d.h - 0.03
		var hinge := Node3D.new()
		hinge.set_script(DOOR_SCRIPT)
		var open_deg := 95.0
		var slab_size: Vector3
		var slab_center: Vector3
		var knob_offset: Vector3
		if d.axis == "x":
			hinge.position = Vector3(d.at, y, d.from + 0.01)
			slab_size = Vector3(0.045, h, w)
			slab_center = Vector3(0, h * 0.5, w * 0.5)
			knob_offset = Vector3(0.045, 1.0, w - 0.08)
			open_deg = 95.0 if d.swing == "+x" else -95.0
		else:
			hinge.position = Vector3(d.from + 0.01, y, d.at)
			slab_size = Vector3(w, h, 0.045)
			slab_center = Vector3(w * 0.5, h * 0.5, 0)
			knob_offset = Vector3(w - 0.08, 1.0, 0.045)
			open_deg = -95.0 if d.swing == "+z" else 95.0
		add(doors, hinge, _pascal(d.id))
		hinge.set("open_angle_deg", open_deg)
		hinge.set("locked", d.get("locked", false))
		hinge.set("locked_message", d.get("msg", "It's locked."))
		hinge.set_meta("door_id", d.id)
		mesh_box(hinge, "Slab", slab_center, slab_size, "door_wood")
		var brass := StandardMaterial3D.new()
		brass.albedo_color = Color(0.55, 0.42, 0.22)
		brass.metallic = 1.0
		brass.roughness = 0.38
		for side in [1.0, -1.0]:
			var knob := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.028
			sm.height = 0.05
			knob.mesh = sm
			knob.material_override = brass
			knob.position = Vector3(knob_offset.x * (side if d.axis == "x" else 1.0), knob_offset.y,
				knob_offset.z * (side if d.axis == "z" else 1.0))
			add(hinge, knob, "Knob" + ("A" if side > 0 else "B"))
		var body := AnimatableBody3D.new()
		body.collision_layer = 3
		body.collision_mask = 0
		add(hinge, body, "Body")
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = slab_size
		cs.shape = bs
		cs.position = slab_center
		add(body, cs, "Shape")


func _build_windows() -> void:
	var wins := Node3D.new()
	add(house,wins, "Windows")
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.albedo_color = Color(0.55, 0.6, 0.62, 0.1)
	glass.metallic_specular = 0.8
	glass.roughness = 0.06
	var i := 0
	for w in WINDOWS:
		var y0: float = level_y(w.lv) + w.sill
		var y1: float = level_y(w.lv) + w.top
		var span: float = w.to - w.from
		var hgt: float = y1 - y0
		var node := Node3D.new()
		add(wins, node, "Window_%d" % i)
		var c: float = (w.from + w.to) * 0.5
		if w.axis == "x":
			node.position = Vector3(w.at, (y0 + y1) * 0.5, c)
			node.rotation.y = PI * 0.5
		else:
			node.position = Vector3(c, (y0 + y1) * 0.5, w.at)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(span, hgt)
		q.mesh = qm
		q.material_override = glass
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add(node, q, "Glass")
		mesh_box(node, "SashTop", Vector3(0, hgt * 0.5 - 0.025, 0), Vector3(span, 0.05, 0.05), "trim_wood")
		mesh_box(node, "SashBottom", Vector3(0, -hgt * 0.5 + 0.025, 0), Vector3(span, 0.05, 0.05), "trim_wood")
		mesh_box(node, "SashLeft", Vector3(-span * 0.5 + 0.025, 0, 0), Vector3(0.05, hgt, 0.05), "trim_wood")
		mesh_box(node, "SashRight", Vector3(span * 0.5 - 0.025, 0, 0), Vector3(0.05, hgt, 0.05), "trim_wood")
		mesh_box(node, "MullionV", Vector3.ZERO, Vector3(0.03, hgt - 0.1, 0.04), "trim_wood")
		mesh_box(node, "MullionH", Vector3.ZERO, Vector3(span - 0.1, 0.03, 0.04), "trim_wood")
		i += 1


func _build_trim() -> void:
	var trim := Node3D.new()
	add(house,trim, "Trim")
	var n := 0
	for r in ROOMS:
		if r.lv == "b" or r.id == "basement_stairs":
			continue
		var rr: Array = r.r
		var y := level_y(r.lv)
		# north/south walls run along x, west/east along z
		var walls := [
			["z", rr[2], rr[0], rr[1], 1.0], ["z", rr[3], rr[0], rr[1], -1.0],
			["x", rr[0], rr[2], rr[3], 1.0], ["x", rr[1], rr[2], rr[3], -1.0]]
		for wall in walls:
			var segs := [[wall[2], wall[3]]]
			for d in DOORS:
				if d.lv != r.lv or d.axis != wall[0] or absf(d.at - wall[1]) > 0.2:
					continue
				var next := []
				for s in segs:
					if d.to <= s[0] or d.from >= s[1]:
						next.append(s)
					else:
						if s[0] < d.from: next.append([s[0], d.from])
						if d.to < s[1]: next.append([d.to, s[1]])
				segs = next
			for s in segs:
				var length: float = s[1] - s[0]
				if length < 0.05:
					continue
				var mid: float = (s[0] + s[1]) * 0.5
				var inset: float = wall[1] + wall[4] * 0.01
				if wall[0] == "z":
					mesh_box(trim, "Base_%d" % n, Vector3(mid, y + 0.06, inset), Vector3(length, 0.12, 0.02), "trim_wood")
				else:
					mesh_box(trim, "Base_%d" % n, Vector3(inset, y + 0.06, mid), Vector3(0.02, 0.12, length), "trim_wood")
				n += 1
	# casings on both faces of every door opening
	for d in DOORS:
		var y := level_y(d.lv)
		var half: float = (EXT_T if d.get("ext", false) else 0.14) * 0.5 + 0.0125
		var top: float = y + d.h + 0.05
		for side in [1.0, -1.0]:
			var off: float = d.at + side * half
			if d.axis == "x":
				mesh_box(trim, "Casing_%s_%d_a" % [d.id, int(side)], Vector3(off, (y + top) * 0.5, d.from - 0.045), Vector3(0.025, top - y, 0.09), "trim_wood")
				mesh_box(trim, "Casing_%s_%d_b" % [d.id, int(side)], Vector3(off, (y + top) * 0.5, d.to + 0.045), Vector3(0.025, top - y, 0.09), "trim_wood")
				mesh_box(trim, "Casing_%s_%d_t" % [d.id, int(side)], Vector3(off, top - 0.05, (d.from + d.to) * 0.5), Vector3(0.025, 0.1, d.to - d.from + 0.18), "trim_wood")
			else:
				mesh_box(trim, "Casing_%s_%d_a" % [d.id, int(side)], Vector3(d.from - 0.045, (y + top) * 0.5, off), Vector3(0.09, top - y, 0.025), "trim_wood")
				mesh_box(trim, "Casing_%s_%d_b" % [d.id, int(side)], Vector3(d.to + 0.045, (y + top) * 0.5, off), Vector3(0.09, top - y, 0.025), "trim_wood")
				mesh_box(trim, "Casing_%s_%d_t" % [d.id, int(side)], Vector3((d.from + d.to) * 0.5, top - 0.05, off), Vector3(d.to - d.from + 0.18, 0.1, 0.025), "trim_wood")
	# window sills on the inside
	var i := 0
	for w in WINDOWS:
		var y0: float = level_y(w.lv) + w.sill
		var inner: float = w.at - signf(w.at) * (EXT_T * 0.5 + 0.03)
		if w.axis == "x":
			mesh_box(trim, "Sill_%d" % i, Vector3(inner, y0 - 0.02, (w.from + w.to) * 0.5), Vector3(0.12, 0.04, w.to - w.from + 0.2), "trim_wood")
		else:
			mesh_box(trim, "Sill_%d" % i, Vector3((w.from + w.to) * 0.5, y0 - 0.02, inner), Vector3(w.to - w.from + 0.2, 0.04, 0.12), "trim_wood")
		i += 1
	# basement posts
	for p in [Vector3(-3.0, 0, -2.0), Vector3(0.0, 0, -2.0), Vector3(-3.0, 0, 0.6)]:
		var post := CSGBox3D.new()
		post.size = Vector3(0.18, 2.35, 0.18)
		post.position = Vector3(p.x, -2.6 + 1.175, p.z)
		post.material = mat("beam_wood")
		post.use_collision = true
		add(trim, post, "Post_%d_%d" % [int(p.x * 10), int(p.z * 10)])
	# rugs (carpet footsteps)
	for rug in [["LivingRug", Vector3(-3.5, 0.0, 2.6), Vector2(3.6, 2.8)], ["BedroomRug", Vector3(-3.4, 2.85, 3.2), Vector2(2.6, 2.2)],
			["HallRunner", Vector3(0.57, 0.0, 0.5), Vector2(0.8, 6.0)]]:
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = rug[2]
		m.mesh = pm
		var rm: ORMMaterial3D = mat("rug").duplicate()
		rm.uv1_scale = Vector3(rug[2].x / 0.6, rug[2].y / 0.6, 1)
		m.material_override = rm
		m.position = rug[1] + Vector3(0, 0.006, 0)
		add(trim, m, rug[0])
		var body := StaticBody3D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		body.set_meta("surface", "carpet")
		add(m, body, "Surface")
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(rug[2].x, 0.02, rug[2].y)
		cs.shape = bs
		add(body, cs, "Shape")
	# kitchen counter run along the north wall (west of the stove)
	var counter := CSGCombiner3D.new()
	counter.use_collision = true
	add(house,counter, "KitchenCounter")
	csg_box(counter, "Body", -5.98, -1.8, 0.0, 0.86, -4.98, -4.38, "counter_body")
	csg_box(counter, "Top", -6.0, -1.78, 0.86, 0.9, -5.0, -4.34, "counter_top")
	csg_box(counter, "Kick", -5.98, -1.8, 0.0, 0.1, -4.38, -4.33, "", CSGShape3D.OPERATION_SUBTRACTION)


func _build_rooms_lights_switches() -> void:
	var rooms := Node3D.new()
	add(house,rooms, "Rooms")
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1, 0.9, 0.7)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1, 0.75, 0.45)
	bulb_mat.emission_energy_multiplier = 4.0
	var socket_scene: PackedScene = load("res://assets/models/pull_chain_light_socket/pull_chain_light_socket.gltf")
	var bulb_scene: PackedScene = load("res://assets/models/lightbulb_01/lightbulb_01.gltf")
	for r in ROOMS:
		var rr: Array = r.r
		var y0 := level_y(r.lv)
		var top := level_top(r.lv) - 0.05
		var area := Area3D.new()
		area.set_script(ROOM_SCRIPT)
		area.monitoring = false
		area.collision_layer = 1 | 16
		area.collision_mask = 0
		area.set("room_id", r.id)
		area.set("reverb", r.reverb)
		area.set("level", r.lv)
		add(rooms, area, _pascal(r.id))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(rr[1] - rr[0], top - y0, rr[3] - rr[2])
		shape.shape = box
		shape.position = Vector3((rr[0] + rr[1]) * 0.5, (y0 + top) * 0.5, (rr[2] + rr[3]) * 0.5)
		add(area, shape, "Shape")
		var kind: String = r.light
		if kind == "none":
			continue
		var spots := []
		if kind == "bulb2":
			spots = [Vector2(-3.0, -2.6), Vector2(2.4, -1.0)]
		elif kind == "chandelier":
			spots = [Vector2(-3.5, 2.6)]
		elif r.has("light_at"):
			for p in r.light_at:
				spots.append(Vector2(p[0], p[1]))
		else:
			spots = [Vector2((rr[0] + rr[1]) * 0.5, (rr[2] + rr[3]) * 0.5)]
		var lights := Node3D.new()
		add(area, lights, "Lights")
		var k := 0
		for s in spots:
			var fixture := Node3D.new()
			fixture.position = Vector3(s.x, top, s.y)
			add(lights, fixture, "Fixture%d" % k)
			if kind != "chandelier":
				var sock := socket_scene.instantiate()
				add(fixture, sock, "Socket")
				var bulb := bulb_scene.instantiate()
				bulb.position = Vector3(0, -0.2, 0)
				bulb.rotation.x = PI
				add(fixture, bulb, "BulbModel")
			if kind != "chandelier":
				var glow := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.022
				sm.height = 0.044
				glow.mesh = sm
				glow.material_override = bulb_mat
				glow.position = Vector3(0, -0.25, 0)
				glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add(fixture, glow, "Glow")
			var light := OmniLight3D.new()
			light.position = Vector3(0, -0.3 if kind != "chandelier" else -0.62, 0)
			light.light_color = Color(1, 0.78, 0.55)
			light.light_energy = 1.3 if r.lv != "b" else 1.0
			light.light_size = 0.04
			light.shadow_enabled = true
			light.shadow_bias = 0.04
			light.omni_range = 7.0
			light.omni_attenuation = 1.3
			light.light_volumetric_fog_energy = 0.4
			add(fixture, light, "Light")
			k += 1
		# wall switch next to the room's first door
		for d in DOORS:
			if d.room != r.id and not (d.lv == r.lv and _door_touches(d, r)):
				continue
			var sw := Node3D.new()
			sw.set_script(SWITCH_SCRIPT)
			sw.set("room_ids", PackedStringArray([r.id] + r.get("switch_also", [])))
			var face_off: float
			var along: float = d.to + 0.18
			if along > (rr[3] if d.axis == "x" else rr[1]) - 0.1:
				along = d.from - 0.18
			if d.axis == "x":
				face_off = rr[0] if absf(d.at - rr[0]) < absf(d.at - rr[1]) else rr[1]
				var inward: float = 1.0 if face_off == rr[0] else -1.0
				sw.position = Vector3(face_off + inward * 0.012, y0 + 1.2, along)
				sw.rotation.y = PI * 0.5 * inward
			else:
				face_off = rr[2] if absf(d.at - rr[2]) < absf(d.at - rr[3]) else rr[3]
				var inward2: float = 1.0 if face_off == rr[2] else -1.0
				sw.position = Vector3(along, y0 + 1.2, face_off + inward2 * 0.012)
				sw.rotation.y = 0.0 if inward2 > 0 else PI
			add(area, sw, "Switch")
			var plate := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.075, 0.12, 0.012)
			plate.mesh = pm
			var plate_mat := StandardMaterial3D.new()
			plate_mat.albedo_color = Color(0.78, 0.74, 0.66)
			plate_mat.roughness = 0.5
			plate.material_override = plate_mat
			add(sw, plate, "Plate")
			var toggle := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.018, 0.03, 0.02)
			toggle.mesh = tm
			toggle.material_override = plate_mat
			toggle.position = Vector3(0, 0, 0.012)
			add(sw, toggle, "Toggle")
			var body := StaticBody3D.new()
			body.collision_layer = 2
			body.collision_mask = 0
			add(sw, body, "Body")
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(0.14, 0.18, 0.06)
			cs.shape = bs
			add(body, cs, "Shape")
			break


func _door_touches(d: Dictionary, r: Dictionary) -> bool:
	var rr: Array = r.r
	if d.axis == "x":
		return (absf(d.at - rr[0]) < 0.2 or absf(d.at - rr[1]) < 0.2) and d.from >= rr[2] - 0.01 and d.to <= rr[3] + 0.01
	return (absf(d.at - rr[2]) < 0.2 or absf(d.at - rr[3]) < 0.2) and d.from >= rr[0] - 0.01 and d.to <= rr[1] + 0.01


func _build_outside() -> void:
	var out := Node3D.new()
	add(house,out, "Outside")
	# concrete foundation band and a gable roof
	var skirt := CSGCombiner3D.new()
	add(out, skirt, "Foundation")
	csg_box(skirt, "Band", -6.26, 6.26, -1.2, 0.0, -5.26, 5.26, "concrete")
	csg_box(skirt, "Hollow", -6.1, 6.1, -1.3, 0.1, -5.1, 5.1, "", CSGShape3D.OPERATION_SUBTRACTION)
	var roof := CSGPolygon3D.new()
	roof.polygon = PackedVector2Array([Vector2(-6.8, 0), Vector2(6.8, 0), Vector2(0, 2.6)])
	roof.depth = 11.2
	roof.position = Vector3(0, 5.75, 5.6)
	roof.material = mat("roof")
	add(out, roof, "Roof")
	# porch (front) and stoop (back)
	var porch := CSGCombiner3D.new()
	porch.use_collision = true
	add(out, porch, "Porch")
	csg_box(porch, "Deck", -0.8, 3.0, -0.6, 0.0, 5.2, 7.4, "porch_deck")
	for i in 3:
		csg_box(porch, "Step%d" % i, 0.2, 1.9, -0.6, -0.2 * (i + 1), 7.4 + i * 0.3, 7.7 + i * 0.3, "porch_deck")
	csg_box(porch, "BackStoop", 0.2, 1.9, -0.6, 0.0, -6.4, -5.2, "porch_deck")
	for i in 3:
		csg_box(porch, "BackStep%d" % i, 0.2, 1.9, -0.6, -0.2 * (i + 1), -6.7 - i * 0.3, -6.4 - i * 0.3, "porch_deck")
	for x in [-0.7, 2.9]:
		csg_box(porch, "Post%d" % int(x * 10), x - 0.06, x + 0.06, 0.0, 2.6, 7.25, 7.37, "trim_wood")
	csg_box(porch, "PorchRoof", -0.9, 3.1, 2.6, 2.72, 5.2, 7.6, "roof")
	porch.set_meta("surface", "porch")
	for c in porch.get_children():
		c.set_meta("surface", "porch")
	# ground with collision; leaves underfoot
	# ground: four slabs around the house footprint, so the basement isn't covered
	var ground := StaticBody3D.new()
	ground.set_meta("surface", "leaves")
	add(out, ground, "Ground")
	var fx0 := OUTER[0] - 0.06
	var fx1 := OUTER[1] + 0.06
	var fz0 := OUTER[2] - 0.06
	var fz1 := OUTER[3] + 0.06
	var e := 80.0
	var pieces := [
		[-e, e, -e, fz0], [-e, e, fz1, e],  # north and south strips (full width)
		[-e, fx0, fz0, fz1], [fx1, e, fz0, fz1],  # west and east beside the house
	]
	var k := 0
	for r in pieces:
		var size := Vector2(r[1] - r[0], r[3] - r[2])
		var center := Vector3((r[0] + r[1]) * 0.5, -0.6, (r[2] + r[3]) * 0.5)
		var gs := CollisionShape3D.new()
		var gb := BoxShape3D.new()
		gb.size = Vector3(size.x, 1, size.y)
		gs.shape = gb
		gs.position = center - Vector3(0, 0.5, 0)
		add(ground, gs, "Shape%d" % k)
		var gm := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = size
		gm.mesh = plane
		gm.material_override = mat("ground_leaves")
		gm.position = center
		add(ground, gm, "Mesh%d" % k)
		k += 1
	# porch light by the front door and the lamp over the back door (both need power)
	for spec in [["PorchLight", Vector3(1.75, 2.3, 5.45), 0.9], ["BackDoorLight", Vector3(1.05, 2.25, -5.45), 1.2]]:
		var pl := OmniLight3D.new()
		pl.position = spec[1]
		pl.light_color = Color(1, 0.8, 0.55)
		pl.light_energy = spec[2]
		pl.omni_range = 6.0
		pl.omni_attenuation = 1.4
		pl.shadow_enabled = true
		pl.light_volumetric_fog_energy = 1.5
		pl.set_script(load("res://scripts/powered_light.gd"))
		add(out, pl, spec[0])
	# invisible yard boundary
	var fence := StaticBody3D.new()
	add(out, fence, "YardLimits")
	for spec in [[Vector3(0, 1, -18), Vector3(40, 4, 0.5)], [Vector3(0, 1, 14), Vector3(40, 4, 0.5)],
			[Vector3(-16, 1, -2), Vector3(0.5, 4, 32)], [Vector3(16, 1, -2), Vector3(0.5, 4, 32)]]:
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = spec[1]
		s.shape = b
		s.position = spec[0]
		add(fence, s, "Wall%d" % fence.get_child_count())


func _build_furniture() -> void:
	var furn := Node3D.new()
	add(house,furn, "Furniture")
	var counts := {}
	for f in FURNITURE:
		var id: String = f[0]
		var ps: PackedScene = load("res://assets/models/%s/%s.gltf" % [id, id])
		if ps == null:
			push_error("missing model " + id)
			continue
		var opts: Dictionary = f[3]
		var inst: Node3D = ps.instantiate()
		inst.position = f[1]
		inst.rotation.y = deg_to_rad(f[2])
		var s: Vector3 = opts.get("scale_v", Vector3.ONE * float(opts.get("scale", 1.0)))
		inst.scale = s
		var name: String = opts.get("name", "")
		if name == "":
			counts[id] = counts.get(id, 0) + 1
			name = "%s_%d" % [_pascal(id), counts[id]]
		add(furn, inst, name)
		if opts.get("no_shadow", false):
			inst.set_meta("no_shadow", true)
		if opts.get("collide", true):
			var box := _aabb(inst, Transform3D.IDENTITY, true)
			var body := StaticBody3D.new()
			add(inst, body, "Collision")
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = (box.size - Vector3(0.04, 0.0, 0.04)).max(Vector3(0.05, 0.05, 0.05))
			cs.shape = bs
			cs.position = box.get_center()
			add(body, cs, "Shape")


func _aabb(node: Node, xf: Transform3D, is_root := false) -> AABB:
	var out := AABB()
	var has := false
	var here := xf
	if node is Node3D and not is_root:
		here = xf * (node as Node3D).transform
	if node is VisualInstance3D:
		out = here * (node as VisualInstance3D).get_aabb()
		has = true
	for c in node.get_children():
		var b := _aabb(c, here)
		if b.size != Vector3.ZERO:
			out = out.merge(b) if has else b
			has = true
	return out


func _pascal(id: String) -> String:
	var parts := id.split("_")
	var s := ""
	for p in parts:
		if p.length() > 0:
			s += p[0].to_upper() + p.substr(1)
	return s
