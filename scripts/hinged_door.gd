class_name HingedDoor
extends Node3D
## A door that swings on this node's origin (place the node on the hinge line).
## Put the door mesh and an AnimatableBody3D (layers world + interactable) under it.
## Sounds come from the Sounds library by name unless a stream is set directly.

signal opened
signal closed
signal knocked_locked

@export var open_angle_deg: float = -100.0
@export var open_time: float = 1.0
@export var locked: bool = false
@export_multiline var locked_message: String = "It's locked."
@export var open_sound_name: String = "door_knob"
@export var close_sound_name: String = "door_close"
@export var locked_sound_name: String = "door_locked"
## Chance (0..1) of an extra hinge creak when opened by the player.
@export var creak_chance: float = 0.35
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var locked_sound: AudioStream

var is_open: bool = false
var _closed_y: float
var _tween: Tween
var _audio: AudioStreamPlayer3D
var _creak: AudioStreamPlayer3D


func _ready() -> void:
	_closed_y = rotation.y
	_audio = _make_player()
	_creak = _make_player()
	if has_meta("door_id") and get_meta("door_id") == "front_door":
		open_sound_name = "door_open"
		creak_chance = 0.0


func _make_player() -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.bus = &"SFX"
	p.unit_size = 4.0
	p.position = Vector3(0, 1.0, 0)
	add_child(p)
	return p


func get_prompt() -> String:
	if _tween and _tween.is_running():
		return ""
	return "[E]  Close" if is_open else "[E]  Open"


func interact(player: Node) -> void:
	if _tween and _tween.is_running():
		return
	if locked:
		_play(_audio, locked_sound if locked_sound else G.sounds().pick(locked_sound_name))
		knocked_locked.emit()
		if player and player.get("hud") and locked_message != "":
			player.hud.say("", locked_message, 2.5)
		return
	if is_open:
		close()
	else:
		open()


## slow = true is for the door opening by itself (story events): long creak, no knob.
func open(slow: bool = false) -> void:
	is_open = true
	if slow:
		_play(_audio, G.sounds().get_stream("door_open"), 0.85)
	else:
		_play(_audio, open_sound if open_sound else G.sounds().pick(open_sound_name))
		if randf() < creak_chance:
			_play(_creak, G.sounds().pick("hinge_creak"), randf_range(0.9, 1.1), -8.0)
	_swing(_closed_y + deg_to_rad(open_angle_deg), open_time * (2.6 if slow else 1.0), Tween.EASE_OUT)
	_tween.finished.connect(_on_opened)


func close(slam: bool = false) -> void:
	is_open = false
	_swing(_closed_y, open_time * (0.35 if slam else 0.8), Tween.EASE_IN)
	_tween.finished.connect(_on_closed.bind(slam))


func _on_opened() -> void:
	opened.emit()


func _on_closed(slam: bool) -> void:
	if slam:
		_play(_audio, G.sounds().get_stream("door_slam"))
	else:
		_play(_audio, close_sound if close_sound else G.sounds().pick(close_sound_name))
	closed.emit()


func _swing(target_y: float, time: float, ease_type: Tween.EaseType) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "rotation:y", target_y, time).set_trans(Tween.TRANS_SINE).set_ease(ease_type)


func _play(p: AudioStreamPlayer3D, stream: AudioStream, pitch: float = 1.0, db: float = 0.0) -> void:
	if stream == null:
		return
	p.stream = stream
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.volume_db = db
	p.play()
