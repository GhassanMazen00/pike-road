class_name Player
extends CharacterBody3D
## First-person controller: walk, run, mouse look, flashlight (F), interact (E),
## and footsteps that change with the surface under the player.
##
## Footstep sounds are picked up automatically from
## res://assets/audio/footsteps/<surface>/ (any .ogg / .wav files).
## A floor reports its surface with the metadata key "surface" ("wood", "carpet", ...).

const FOOTSTEP_ROOT := "res://assets/audio/footsteps/"
const SURFACE_MASK := 1 | 4  # world + surface layers
const DEFAULT_SURFACE := "wood"

@export_group("Movement")
@export var walk_speed: float = 1.9
@export var run_speed: float = 3.6
@export var acceleration: float = 9.0
@export var deceleration: float = 12.0

@export_group("Feel")
@export var walk_step_distance: float = 0.62
@export var run_step_distance: float = 0.9
@export var bob_height: float = 0.018
@export var flashlight_lag: float = 14.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var flashlight_pivot: Node3D = $FlashlightPivot
@onready var flashlight: SpotLight3D = $FlashlightPivot/Flashlight
@onready var flashlight_click: AudioStreamPlayer = $FlashlightClick
@onready var footstep_player: AudioStreamPlayer3D = $Footsteps
@onready var hud: Hud = $HUD

## Set false during cutscenes or dialogue.
var input_enabled: bool = true

var _pitch: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _step_distance_accum: float = 0.0
var _bob_phase: float = 0.0
var _head_base_height: float = 0.0
var _focused: Node = null
var _footstep_sets: Dictionary = {}  # surface -> Array[AudioStream]
var _last_step: Dictionary = {}  # surface -> last index played


func _ready() -> void:
	_head_base_height = head.position.y
	flashlight_pivot.top_level = true
	flashlight_pivot.global_transform = camera.global_transform
	flashlight.visible = false
	_load_footsteps()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or get_tree().paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.mouse_sensitivity
		var dy: float = event.relative.y * (-1.0 if Settings.invert_y else 1.0)
		rotate_y(-event.relative.x * sens)
		_pitch = clampf(_pitch - dy * sens, deg_to_rad(-85.0), deg_to_rad(85.0))
		head.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("interact"):
		if _focused and _focused.has_method("interact"):
			_focused.interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Vector2.ZERO
	var running := false
	if input_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run") and input_dir.y < 0.0
	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target_speed := run_speed if running else walk_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := acceleration if wish != Vector3.ZERO else deceleration
	horizontal = horizontal.lerp(wish * target_speed, 1.0 - exp(-rate * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	var before := global_position
	move_and_slide()
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()

	_update_steps_and_bob(moved, running, delta)
	_update_focus()


func _process(delta: float) -> void:
	# The flashlight trails the view slightly so it feels hand-held.
	var t := 1.0 - exp(-flashlight_lag * delta)
	var from := Quaternion(flashlight_pivot.global_basis.orthonormalized())
	var to := Quaternion(camera.global_basis.orthonormalized())
	flashlight_pivot.global_basis = Basis(from.slerp(to, t))
	flashlight_pivot.global_position = camera.global_position


func toggle_flashlight() -> void:
	flashlight.visible = not flashlight.visible
	if flashlight_click.stream:
		flashlight_click.pitch_scale = randf_range(0.95, 1.05)
		flashlight_click.play()


func _update_steps_and_bob(moved: float, running: bool, delta: float) -> void:
	var on_floor := is_on_floor()
	var speed := moved / maxf(delta, 0.0001)
	if on_floor and speed > 0.3:
		var stride := run_step_distance if running else walk_step_distance
		_step_distance_accum += moved
		_bob_phase += moved / stride * PI
		if _step_distance_accum >= stride:
			_step_distance_accum -= stride
			_play_footstep(running)
	else:
		_step_distance_accum = minf(_step_distance_accum, walk_step_distance * 0.5)
		_bob_phase = lerpf(_bob_phase, roundf(_bob_phase / PI) * PI, 1.0 - exp(-8.0 * delta))
	var amount := bob_height * (1.4 if running else 1.0)
	head.position.y = _head_base_height - absf(sin(_bob_phase)) * amount


func _play_footstep(running: bool) -> void:
	var surface := _surface_below()
	var sounds: Array = _footstep_sets.get(surface, _footstep_sets.get(DEFAULT_SURFACE, []))
	if sounds.is_empty():
		return
	var index := randi() % sounds.size()
	if sounds.size() > 1 and index == _last_step.get(surface, -1):
		index = (index + 1) % sounds.size()
	_last_step[surface] = index
	footstep_player.stream = sounds[index]
	footstep_player.pitch_scale = randf_range(0.92, 1.06)
	footstep_player.volume_db = randf_range(-2.0, 0.0) + (2.0 if running else -1.0)
	footstep_player.play()


func _surface_below() -> String:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.3, SURFACE_MASK, [get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return DEFAULT_SURFACE
	var node: Object = hit.collider
	while node is Node:
		if node.has_meta("surface"):
			return str(node.get_meta("surface"))
		node = node.get_parent()
	return DEFAULT_SURFACE


func _update_focus() -> void:
	var target: Node = null
	if input_enabled and interact_ray.is_colliding():
		var node: Object = interact_ray.get_collider()
		while node is Node and node != get_tree().current_scene:
			if node.has_method("interact"):
				target = node
				break
			node = node.get_parent()
	if target != _focused:
		_focused = target
	var prompt := ""
	if _focused and _focused.has_method("get_prompt"):
		prompt = _focused.get_prompt()
	hud.set_prompt(prompt)


func _load_footsteps() -> void:
	for entry in ResourceLoader.list_directory(FOOTSTEP_ROOT):
		if not entry.ends_with("/"):
			continue
		var surface := entry.trim_suffix("/")
		var sounds: Array[AudioStream] = []
		var dir := FOOTSTEP_ROOT + entry
		for file in ResourceLoader.list_directory(dir):
			var ext := file.get_extension().to_lower()
			if ext in ["ogg", "wav", "mp3"]:
				var stream := load(dir + file) as AudioStream
				if stream:
					sounds.append(stream)
		if not sounds.is_empty():
			_footstep_sets[surface] = sounds
