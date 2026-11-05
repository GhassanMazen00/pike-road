extends Node3D
## The Pike house. Wires up looping sounds that live in the scene and per-model tweaks.

@onready var clock_tick: AudioStreamPlayer3D = $ClockTick


func _ready() -> void:
	clock_tick.stream = G.sounds().get_stream("clock_tick")
	if clock_tick.stream:
		clock_tick.play()
	# models whose own light would throw distracting shadows (the chandelier around its bulbs)
	for node in find_children("*", "Node3D", true, false):
		if node.has_meta("no_shadow"):
			for g in node.find_children("*", "GeometryInstance3D", true, false):
				(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
