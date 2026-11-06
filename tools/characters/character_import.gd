@tool
extends EditorScenePostImport
## Runs when Godot imports a cast character (assets/characters/cast/*.glb).
## - Hair, eyebrows and eyelashes: alpha cut-out with alpha-to-coverage, so hair draws
##   correctly instead of sorting badly or vanishing.
## - Clothing tints from the character's spec (tools/characters/cast/<name>.json, "tint")
##   are applied as albedo color, multiplied with the texture.

const HAIR_HINTS := ["hair", "braid", "ponytail", "bob", "long0", "short0", "eyebrow", "eyelash", "afro", "updo"]


func _post_import(scene: Node) -> Object:
	print("character_import: ", get_source_file())
	var name := get_source_file().get_file().get_basename()
	var tint := {}
	var spec_path := "res://tools/characters/cast/%s.json" % name
	if FileAccess.file_exists(spec_path):
		var spec = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
		if spec is Dictionary:
			tint = spec.get("tint", {})
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		var lname := String(mi.name).to_lower()
		var is_hair := HAIR_HINTS.any(func(h: String) -> bool: return lname.contains(h))
		for s in mesh.get_surface_count():
			var m := mesh.surface_get_material(s) as BaseMaterial3D
			if m == null:
				continue
			m = m.duplicate()
			if is_hair:
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.35
				m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			else:
				# opaque cloth and skin: never blend (avoids sorting holes)
				if m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and not lname.contains("high-poly"):
					m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			for key in tint:
				if lname.contains(String(key).to_lower()):
					var c: Array = tint[key]
					var target := Color(c[0], c[1], c[2])
					var recolored := _recolor(m.albedo_texture, target)
					if recolored:
						m.albedo_texture = recolored
						m.albedo_color = Color.WHITE
					else:
						m.albedo_color = target
			mesh.surface_set_material(s, m)
	return scene


## A tint is the color the garment should average out to. Rebuild the texture: keep only its
## light-and-dark detail (grayscale, softened so dark textures don't turn noise into confetti),
## re-centered on the target color. Works for any garment color, dark or bright.
func _recolor(tex: Texture2D, target: Color) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	var size := mini(img.get_width(), 512)
	img.resize(size, size, Image.INTERPOLATE_BILINEAR)
	var lum := PackedFloat32Array()
	lum.resize(size * size)
	var sum := 0.0
	var n := 0
	for y in size:
		for x in size:
			var p := img.get_pixel(x, y)
			var l := p.r * 0.299 + p.g * 0.587 + p.b * 0.114
			lum[y * size + x] = l
			if p.a > 0.5:
				sum += l
				n += 1
	var avg := maxf(sum / maxi(n, 1), 0.01)
	for y in size:
		for x in size:
			var a := img.get_pixel(x, y).a
			# detail = relative brightness, compressed toward 1 so amplified noise stays calm
			var d := clampf(1.0 + (lum[y * size + x] / avg - 1.0) * 0.6, 0.35, 1.6)
			img.set_pixel(x, y, Color(clampf(target.r * d, 0, 1), clampf(target.g * d, 0, 1), clampf(target.b * d, 0, 1), a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
