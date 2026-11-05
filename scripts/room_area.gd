class_name RoomArea
extends Area3D
## One room of the house: knows its lights (and whether they're switched on),
## gives sounds inside it the right echo, and tells the game which room the player is in.

const REVERB_BUS := {
	"small": [&"Reverb_Small", 0.55],
	"medium": [&"Reverb_Medium", 0.5],
	"closet": [&"Reverb_Closet", 0.6],
	"tiled": [&"Reverb_Tiled", 0.7],
	"basement": [&"Reverb_Basement", 0.75],
}

@export var room_id: String = ""
@export var reverb: String = "small"
@export var level: String = "g"
@export var lights_on: bool = true

var _lights: Array[Light3D] = []
var _glows: Array[GeometryInstance3D] = []


func _ready() -> void:
	add_to_group("rooms")
	var holder := get_node_or_null("Lights")
	if holder:
		for l in holder.find_children("*", "Light3D", true, false):
			_lights.append(l)
		for g in holder.find_children("Glow", "GeometryInstance3D", true, false):
			_glows.append(g)
	if REVERB_BUS.has(reverb):
		reverb_bus_enabled = true
		reverb_bus_name = REVERB_BUS[reverb][0]
		reverb_bus_amount = REVERB_BUS[reverb][1]
		reverb_bus_uniformity = 0.3
	G.power().changed.connect(func(_on: bool) -> void: _apply())
	_apply()


func has_lights() -> bool:
	return not _lights.is_empty()


func set_lights(on: bool) -> void:
	lights_on = on
	_apply()


func is_lit() -> bool:
	return lights_on and G.power().on and has_lights()


func _apply() -> void:
	var lit: bool = lights_on and G.power().on
	for l in _lights:
		l.visible = lit
	for g in _glows:
		g.visible = lit


static func find(tree: SceneTree, id: String) -> RoomArea:
	for r in tree.get_nodes_in_group("rooms"):
		if r.room_id == id:
			return r
	return null


## The room containing a world position, or null when outside.
static func at(tree: SceneTree, world: World3D, pos: Vector3) -> RoomArea:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = pos
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	for hit in world.direct_space_state.intersect_point(q, 8):
		if hit.collider is RoomArea:
			return hit.collider
	return null
