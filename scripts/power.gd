extends Node
## House electricity. Room lights and lamps only shine while the power is on.
## Story events cut it (lights out in Part 1) and the fuse box restores it.

signal changed(on: bool)

var on: bool = true


func set_power(value: bool) -> void:
	if value == on:
		return
	on = value
	changed.emit(on)
