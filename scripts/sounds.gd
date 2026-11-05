extends Node
## Sound library. Game code asks for a sound by name; this finds the best file:
## the licensed recordings in assets/audio/licensed/ (fetched by tools/fetch_licensed_audio.py),
## otherwise a free fallback in assets/audio/, otherwise nothing (silent).

const LICENSED := "res://assets/audio/licensed/"
const FREE := "res://assets/audio/"

## name -> list of candidate base paths (no extension). A trailing "_" means "every take with this prefix".
const LIBRARY := {
	"switch": ["licensed/sfx/breaker_switch"],
	"breaker": ["licensed/sfx/breaker_switch"],
	"door_open": ["licensed/sfx/door_open_creak", "sfx/door_open"],
	"door_close": ["licensed/sfx/door_close", "sfx/door_close"],
	"door_close_creak": ["licensed/sfx/door_close_creak"],
	"door_slam": ["licensed/sfx/door_slam_scary"],
	"door_locked": ["licensed/sfx/door_locked_rattle", "sfx/door_locked"],
	"door_knob": ["licensed/sfx/door_knob"],
	"deadbolt": ["licensed/sfx/deadbolt"],
	"door_bang": ["licensed/sfx/door_bang"],
	"door_rattle_violent": ["licensed/sfx/door_rattle_violent"],
	"knock": ["licensed/sfx/knock_"],
	"pound": ["licensed/sfx/pound_"],
	"drawer_open": ["licensed/sfx/drawer_open_"],
	"drawer_close": ["licensed/sfx/drawer_close_"],
	"hinge_creak": ["licensed/sfx/hinge_creak_"],
	"cabinet_close": ["licensed/sfx/cabinet_close_"],
	"doorknob_creak": ["licensed/sfx/doorknob_creak_"],
	"creak": ["licensed/sfx/creak_floor_", "licensed/sfx/creak_wood_"],
	"fridge_open": ["licensed/sfx/fridge_open"],
	"microwave_door": ["licensed/sfx/microwave_door"],
	"microwave_beep": ["licensed/sfx/microwave_beep_"],
	"cupboard_open": ["licensed/sfx/cupboard_open"],
	"doormat": ["licensed/sfx/doormat_scrape"],
	"heartbeat": ["licensed/sfx/heartbeat_panic"],
	"scream": ["licensed/sfx/scream_muffled"],
	"tv_static": ["licensed/sfx/tv_static"],
	"clock_tick": ["licensed/sfx/clock_tick_a", "ambience/clock_tick"],
	"amb_house": ["licensed/ambience/room_tone_house", "ambience/room_tone"],
	"amb_basement": ["licensed/ambience/room_tone_basement"],
	"amb_night": ["licensed/ambience/night_outside"],
	"amb_crickets": ["licensed/ambience/crickets_quiet"],
	"amb_forest": ["licensed/ambience/forest_creaks"],
	"flashlight_click": ["sfx/flashlight_click", "licensed/sfx/breaker_switch"],
}

## Footstep surfaces that borrow another surface's recordings.
const SURFACE_ALIAS := {
	"linoleum": "wood", "porch": "wood", "concrete": "dirt", "grass": "leaves", "gravel": "dirt",
}

var _cache: Dictionary = {}


func get_stream(name: String) -> AudioStream:
	var all := get_all(name)
	return all[0] if not all.is_empty() else null


## A random take (never the same one twice in a row when there are several).
func pick(name: String) -> AudioStream:
	var all := get_all(name)
	if all.is_empty():
		return null
	if all.size() == 1:
		return all[0]
	var key := "_last_" + name
	var i := randi() % all.size()
	if i == _cache.get(key, -1):
		i = (i + 1) % all.size()
	_cache[key] = i
	return all[i]


func get_all(name: String) -> Array:
	if _cache.has(name):
		return _cache[name]
	var found: Array = []
	for base in LIBRARY.get(name, []):
		found = _load(FREE + base)
		if not found.is_empty():
			break
	_cache[name] = found
	return found


## Footstep takes for a surface ("wood", "carpet", "stairs", "dirt", "leaves", ...).
func footsteps(surface: String) -> Array:
	var key := "steps_" + surface
	if _cache.has(key):
		return _cache[key]
	var list: Array = []
	for s in [surface, SURFACE_ALIAS.get(surface, ""), "wood"]:
		if s == "":
			continue
		list = _load_dir(LICENSED + "footsteps/" + s)
		if list.is_empty():
			list = _load_dir(FREE + "footsteps/" + s)
		if not list.is_empty():
			break
	_cache[key] = list
	return list


func _load(base: String) -> Array:
	var out: Array = []
	if base.ends_with("_"):
		var dir := base.get_base_dir()
		var prefix := base.get_file()
		for f in ResourceLoader.list_directory(dir):
			if f.begins_with(prefix) and f.get_extension().to_lower() in ["wav", "ogg", "mp3"]:
				var s := load(dir.path_join(f)) as AudioStream
				if s:
					out.append(s)
		return out
	for ext in ["wav", "ogg", "mp3"]:
		var path := "%s.%s" % [base, ext]
		if ResourceLoader.exists(path):
			out.append(load(path))
			return out
	return out


func _load_dir(dir: String) -> Array:
	var out: Array = []
	for f in ResourceLoader.list_directory(dir):
		if f.get_extension().to_lower() in ["wav", "ogg", "mp3"]:
			var s := load(dir.path_join(f)) as AudioStream
			if s:
				out.append(s)
	return out
