class_name HingedDoor
extends Node3D
## A door that swings on this node's origin (place the node on the hinge line).
## Put the door mesh and an AnimatableBody3D (layers world + interactable) under it.

signal opened
signal closed

@export var open_angle_deg: float = -100.0
@export var open_time: float = 1.0
@export var locked: bool = false
@export_multiline var locked_message: String = "It's locked."
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var locked_sound: AudioStream

var is_open: bool = false
var _closed_y: float
var _tween: Tween
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	_closed_y = rotation.y
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"Master"
	_audio.unit_size = 4.0
	_audio.position = Vector3(0, 1.0, 0)
	add_child(_audio)


func get_prompt() -> String:
	if _tween and _tween.is_running():
		return ""
	return "[E]  Close" if is_open else "[E]  Open"


func interact(player: Node) -> void:
	if _tween and _tween.is_running():
		return
	if locked:
		_play(locked_sound)
		if player and player.get("hud") and locked_message != "":
			player.hud.say("", locked_message, 2.5)
		return
	if is_open:
		close()
	else:
		open()


## slow = true is for the door opening by itself (story events).
func open(slow: bool = false) -> void:
	is_open = true
	_play(open_sound, 0.85 if slow else 1.0)
	_swing(_closed_y + deg_to_rad(open_angle_deg), open_time * (2.6 if slow else 1.0), Tween.EASE_OUT)
	_tween.finished.connect(_on_opened)


func close() -> void:
	is_open = false
	_swing(_closed_y, open_time * 0.8, Tween.EASE_IN)
	_tween.finished.connect(_on_closed)


func _on_opened() -> void:
	opened.emit()


func _on_closed() -> void:
	_play(close_sound)
	closed.emit()


func _swing(target_y: float, time: float, ease_type: Tween.EaseType) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "rotation:y", target_y, time).set_trans(Tween.TRANS_SINE).set_ease(ease_type)


func _play(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	_audio.stream = stream
	_audio.pitch_scale = pitch * randf_range(0.97, 1.03)
	_audio.play()
