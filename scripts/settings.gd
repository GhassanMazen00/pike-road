extends Node
## Player-facing options, saved to user://settings.cfg.
## Screen effects are optional and default to subtle.

signal changed

const PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.0022
var invert_y: bool = false
var film_grain: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_grain"):
		film_grain = not film_grain
		save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "invert_y", invert_y)
	cfg.set_value("video", "film_grain", film_grain)
	cfg.save(PATH)
	changed.emit()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	invert_y = cfg.get_value("input", "invert_y", invert_y)
	film_grain = cfg.get_value("video", "film_grain", film_grain)
