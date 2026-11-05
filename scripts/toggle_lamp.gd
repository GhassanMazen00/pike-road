class_name ToggleLamp
extends Node3D
## A lamp you can switch on and off with E.
## Every Light3D under this node is switched, and `glow_material` (the bulb/shade)
## has its emission turned on and off with it.

@export var is_on: bool = true
@export var glow_material: StandardMaterial3D
@export var switch_sound: AudioStream
## Nodes shown only while the lamp is on (a bulb mesh, for example).
@export var visible_when_on: Array[NodePath] = []
## Nodes always hidden, matched by name anywhere under the lamp (for example a model's flame mesh).
@export var always_hidden: PackedStringArray = []

var _lights: Array[Light3D] = []
var _energy: Dictionary = {}
var _glow_energy: float = 1.0
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	for node in find_children("*", "Light3D", true, false):
		_lights.append(node)
		_energy[node] = node.light_energy
	if glow_material:
		_glow_energy = glow_material.emission_energy_multiplier
	for pattern in always_hidden:
		for node in find_children(pattern, "Node3D", true, false):
			node.visible = false
	# The lamp's own body would throw hard rings of shadow onto the ceiling from its own bulb.
	for node in find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.unit_size = 3.0
	_audio.volume_db = -6.0
	_audio.position = Vector3(0, 0.4, 0)
	add_child(_audio)
	if switch_sound == null:
		switch_sound = G.sounds().get_stream("switch")
	G.power().changed.connect(func(_on: bool) -> void: _apply())
	_apply()


func get_prompt() -> String:
	return "[E]  Turn off lamp" if is_on else "[E]  Turn on lamp"


func interact(_player: Node) -> void:
	set_on(not is_on)


func set_on(on: bool) -> void:
	is_on = on
	if switch_sound:
		_audio.stream = switch_sound
		_audio.pitch_scale = randf_range(1.8, 2.0)
		_audio.play()
	_apply()


func _apply() -> void:
	var lit: bool = is_on and G.power().on
	for light in _lights:
		light.visible = lit
	for path in visible_when_on:
		var node := get_node_or_null(path) as Node3D
		if node:
			node.visible = lit
	if glow_material:
		glow_material.emission_energy_multiplier = _glow_energy if lit else 0.0
