class_name LightSwitch
extends Node3D
## Wall switch: E toggles the lights of its room(s). Does nothing useful with the power out.

@export var room_ids: PackedStringArray = []

var _audio: AudioStreamPlayer3D


func _ready() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.unit_size = 2.0
	_audio.volume_db = -8.0
	add_child(_audio)
	_audio.stream = G.sounds().get_stream("switch")
	_update_toggle.call_deferred()


func get_prompt() -> String:
	var r := _first()
	if r == null:
		return ""
	return "[E]  Lights off" if r.lights_on else "[E]  Lights on"


func interact(_player: Node) -> void:
	var r := _first()
	if r == null:
		return
	var on := not r.lights_on
	for id in room_ids:
		var room := RoomArea.find(get_tree(), id)
		if room:
			room.set_lights(on)
	if _audio.stream:
		_audio.pitch_scale = randf_range(1.5, 1.7)
		_audio.play()
	_update_toggle()


func _first() -> RoomArea:
	if room_ids.is_empty():
		return null
	return RoomArea.find(get_tree(), room_ids[0])


func _update_toggle() -> void:
	var r := _first()
	var t := get_node_or_null("Toggle") as Node3D
	if r and t:
		t.rotation.x = -0.35 if r.lights_on else 0.35
