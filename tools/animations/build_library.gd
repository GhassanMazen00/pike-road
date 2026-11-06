extends SceneTree
## Packs the Mixamo animations (assets/animations/mixamo/*.fbx, downloaded "without skin" on the
## X Bot) into one AnimationLibrary our MPFB cast can play directly, since both use Mixamo bone names.
##
##   godot --headless --path . --script res://tools/animations/build_library.gd
##
## - keeps only tracks for bones our rig has (MPFB's mixamo rig has 52 of X Bot's 65)
## - loops idles, walks, runs and other cycles; one-shots stay one-shot
## - saves res://assets/animations/mixamo_library.res
## Characters play it with an AnimationPlayer whose root is the node that holds "Skeleton3D".
## Hips height differs per character, so set Skeleton3D.motion_scale = character hips / XBOT_HIPS.

const SRC := "res://assets/animations/mixamo/"
const OUT := "res://assets/animations/mixamo_library.res"
const RIG := "res://assets/characters/cast/walt.glb"
const ONE_SHOTS := ["sit_to_stand", "standing_greeting", "reaching_out", "opening_door", "zombie_attack",
	"mutant_swiping", "zombie_scream", "honking_horn", "left_turn", "right_turn", "drinking", "waving"]


func _init() -> void:
	var rig: Node = load(RIG).instantiate()
	var rig_skel: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
	var keep := {}
	for i in rig_skel.get_bone_count():
		keep[rig_skel.get_bone_name(i)] = true
	rig.free()

	var lib := AnimationLibrary.new()
	var xbot_hips := 0.0
	for file in ResourceLoader.list_directory(SRC):
		if file.get_extension().to_lower() != "fbx":
			continue
		var name := file.get_basename()
		var scene: Node = load(SRC + file).instantiate()
		var players := scene.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			print("no animation in ", file)
			scene.free()
			continue
		if xbot_hips == 0.0:
			var sk: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
			xbot_hips = sk.get_bone_rest(sk.find_bone("mixamorig_Hips")).origin.y
		var ap: AnimationPlayer = players[0]
		var src: Animation = null
		for l in ap.get_animation_library_list():
			for a in ap.get_animation_library(l).get_animation_list():
				src = ap.get_animation_library(l).get_animation(a)
		var anim: Animation = src.duplicate(true)
		for t in range(anim.get_track_count() - 1, -1, -1):
			var bone := String(anim.track_get_path(t).get_concatenated_subnames())
			if not keep.has(bone):
				anim.remove_track(t)
		anim.loop_mode = Animation.LOOP_NONE if name in ONE_SHOTS else Animation.LOOP_LINEAR
		lib.add_animation(name, anim)
		print("%-22s %5.2fs  %d tracks  %s" % [name, anim.length, anim.get_track_count(), "once" if name in ONE_SHOTS else "loop"])
		scene.free()
	lib.set_meta("xbot_hips_height", xbot_hips)
	var err := ResourceSaver.save(lib, OUT)
	print("saved ", OUT, " (", lib.get_animation_list().size(), " animations, X Bot hips ", xbot_hips, ") err=", err)
	quit()
