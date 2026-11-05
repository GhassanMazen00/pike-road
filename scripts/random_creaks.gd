extends Node3D
## Plays a random house creak every so often from one of the Marker3D children
## (only ones near enough to the listener to be heard, so creaks feel like "this house").

@export var min_interval: float = 12.0
@export var max_interval: float = 35.0
@export var volume_db: float = -6.0
@export var max_distance: float = 12.0

var _spots: Array[Node3D] = []
var _audio: AudioStreamPlayer3D
var _timer: Timer


func _ready() -> void:
	for child in get_children():
		if child is Marker3D:
			_spots.append(child)
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.unit_size = 5.0
	add_child(_audio)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_creak)
	add_child(_timer)
	_timer.start(randf_range(5.0, 12.0))


func _creak() -> void:
	_timer.start(randf_range(min_interval, max_interval))
	var stream: AudioStream = G.sounds().pick("creak")
	if stream == null or _spots.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	var near := _spots.filter(func(s: Node3D) -> bool:
		return cam == null or s.global_position.distance_to(cam.global_position) < max_distance)
	if near.is_empty():
		return
	_audio.global_position = near.pick_random().global_position
	_audio.stream = stream
	_audio.volume_db = volume_db + randf_range(-5.0, 0.0)
	_audio.pitch_scale = randf_range(0.88, 1.05)
	_audio.play()
