extends Node3D
## Living room (milestone 1). Hooks up optional sound files by name, so recorded
## sounds dropped into assets/audio/ start working without editing the scene.
## See DOWNLOADS.md for which file goes where.

const AUDIO_EXTS := ["ogg", "wav", "mp3"]


func _ready() -> void:
	_loop_into($Ambience/RoomTone, "res://assets/audio/ambience/room_tone")
	_loop_into($Furniture/GrandfatherClock/Tick, "res://assets/audio/ambience/clock_tick")
	var door: HingedDoor = $House/FrontDoor
	door.open_sound = _find("res://assets/audio/sfx/door_open")
	door.close_sound = _find("res://assets/audio/sfx/door_close")
	var hall_door: HingedDoor = $House/HallDoor
	hall_door.locked_sound = _find("res://assets/audio/sfx/door_locked")
	var lamp: ToggleLamp = $OilLamp
	lamp.switch_sound = _find("res://assets/audio/sfx/lamp_switch")
	var click: AudioStreamPlayer = $Player/FlashlightClick
	click.stream = _find("res://assets/audio/sfx/flashlight_click")


## Returns the first of base.ogg / base.wav / base.mp3 that exists, or null.
func _find(base: String) -> AudioStream:
	for ext in AUDIO_EXTS:
		var path := "%s.%s" % [base, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _loop_into(player: Node, base: String) -> void:
	var stream := _find(base)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	else:
		# WAV: restart when it ends (set loop in the import dock for a gapless loop).
		player.finished.connect(player.play)
	player.stream = stream
	player.play()
