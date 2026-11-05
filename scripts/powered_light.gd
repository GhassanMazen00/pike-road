extends Light3D
## A light that is only on while the house has power (porch light, yard lamp).

@export var enabled: bool = true


func _ready() -> void:
	G.power().changed.connect(func(_on: bool) -> void: _apply())
	_apply()


func set_enabled(on: bool) -> void:
	enabled = on
	_apply()


func _apply() -> void:
	visible = enabled and G.power().on
