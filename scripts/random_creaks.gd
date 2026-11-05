extends Node3D
## Plays a random house creak every so often from one of the Marker3D children.
## Sounds are picked up from `folder` automatically.

@export_dir var folder: String = "res://assets/audio/ambience/creaks"
@export var min_interval: float = 14.0
@export var max_interval: float = 40.0
@export var volume_db: float = -4.0

var _sounds: Array[AudioStream] = []
var _spots: Array[Node3D] = []
var _audio: AudioStreamPlayer3D
var _timer: Timer
var _last: int = -1


func _ready() -> void:
	for file in ResourceLoader.list_directory(folder):
		if file.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
			var stream := load(folder.path_join(file)) as AudioStream
			if stream:
				_sounds.append(stream)
	for child in get_children():
		if child is Marker3D:
			_spots.append(child)
	_audio = AudioStreamPlayer3D.new()
	_audio.unit_size = 6.0
	add_child(_audio)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_creak)
	add_child(_timer)
	if not _sounds.is_empty():
		_timer.start(randf_range(4.0, 10.0))


func _creak() -> void:
	var i := randi() % _sounds.size()
	if _sounds.size() > 1 and i == _last:
		i = (i + 1) % _sounds.size()
	_last = i
	if not _spots.is_empty():
		_audio.global_position = _spots.pick_random().global_position
	_audio.stream = _sounds[i]
	_audio.volume_db = volume_db + randf_range(-4.0, 0.0)
	_audio.pitch_scale = randf_range(0.9, 1.05)
	_audio.play()
	_timer.start(randf_range(min_interval, max_interval))
