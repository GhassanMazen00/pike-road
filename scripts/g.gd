class_name G
## Safe access to the game's global services (autoloads), looked up at run time.
## Using these instead of the bare autoload names keeps scripts compiling no matter
## which order things load in (tools, tests, or other autoloads).


static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func sounds() -> Node:
	return tree().root.get_node(^"Sounds")


static func power() -> Node:
	return tree().root.get_node(^"Power")


static func settings() -> Node:
	return tree().root.get_node(^"Settings")


static func game() -> Node:
	return tree().root.get_node_or_null(^"Game")
