extends Node
## Background beds that follow the player: house room tone inside, furnace hum in the
## basement, crickets and owls outside (muffled through the walls when you're indoors).

@export var player_path: NodePath

const FADE_SPEED := 1.6  # linear volume per second

var _beds: Dictionary = {}   # key -> AudioStreamPlayer
var _target: Dictionary = {}  # key -> linear volume
var _player: Node3D
var _check := 0.0
var room: RoomArea = null


func _ready() -> void:
	_player = get_node_or_null(player_path)
	_add("house", "amb_house", &"Ambience")
	_add("basement", "amb_basement", &"Ambience")
	_add("night", "amb_night", &"Ambience")
	_add("night_muffled", "amb_night", &"AmbienceMuffled")
	_add("crickets", "amb_crickets", &"Ambience")


func _add(key: String, sound: String, bus: StringName) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = G.sounds().get_stream(sound)
	p.bus = bus
	p.volume_db = -80.0
	add_child(p)
	if p.stream:
		p.play()
	_beds[key] = p
	_target[key] = 0.0


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0 and _player:
		_check = 0.25
		room = RoomArea.at(get_tree(), _player.get_world_3d(), _player.global_position + Vector3.UP)
		for k in _target:
			_target[k] = 0.0
		if room == null:
			_target["night"] = 0.8
			_target["crickets"] = 0.5
		elif room.level == "b":
			_target["basement"] = 0.85
			_target["house"] = 0.12
		elif room.room_id == "basement_stairs":
			_target["basement"] = 0.45
			_target["house"] = 0.6
		else:
			_target["house"] = 0.8
			_target["night_muffled"] = 0.3
	for k in _beds:
		var p: AudioStreamPlayer = _beds[k]
		var cur := db_to_linear(p.volume_db)
		cur = move_toward(cur, _target[k], FADE_SPEED * delta)
		p.volume_db = linear_to_db(maxf(cur, 0.0001))
