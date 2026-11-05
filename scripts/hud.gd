class_name Hud
extends CanvasLayer
## Crosshair, interaction prompt, subtitles (one speaker per line) and the pause menu.

const SCREEN_FX_SHADER := preload("res://ui/screen_fx.gdshader")

var _screen_fx: ColorRect
var _crosshair: Control
var _prompt: Label
var _subtitle: Label
var _subtitle_queue: Array = []
var _subtitle_timer: Timer
var _pause_menu: Control
var _grain_check: CheckButton
var _sens_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_screen_fx()
	_build_crosshair()
	_build_prompt()
	_build_subtitle()
	_build_pause_menu()
	G.settings().changed.connect(_apply_settings)
	_apply_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""
	_crosshair.modulate.a = 0.85 if text != "" else 0.35


## Queue a subtitle. Lines play one after another, never two at once.
func say(speaker: String, text: String, seconds: float = 0.0) -> void:
	if seconds <= 0.0:
		seconds = clampf(1.2 + text.length() * 0.055, 2.0, 7.0)
	_subtitle_queue.append([speaker, text, seconds])
	if _subtitle_timer.is_stopped():
		_next_subtitle()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


func _next_subtitle() -> void:
	if _subtitle_queue.is_empty():
		_subtitle.visible = false
		return
	var line: Array = _subtitle_queue.pop_front()
	_subtitle.text = ("%s: %s" % [line[0], line[1]]) if line[0] != "" else line[1]
	_subtitle.visible = true
	_subtitle_timer.start(line[2])


func _apply_settings() -> void:
	_screen_fx.visible = G.settings().film_grain
	_grain_check.set_pressed_no_signal(G.settings().film_grain)
	_sens_slider.set_value_no_signal(G.settings().mouse_sensitivity * 1000.0)


func _build_screen_fx() -> void:
	_screen_fx = ColorRect.new()
	_screen_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SCREEN_FX_SHADER
	_screen_fx.material = mat
	add_child(_screen_fx)


func _build_crosshair() -> void:
	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1)
	_crosshair.size = Vector2(4, 4)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = -_crosshair.size * 0.5
	_crosshair.modulate.a = 0.35
	add_child(_crosshair)


func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.offset_top = 28
	_prompt.offset_bottom = 60
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85, 0.9))
	_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_prompt.visible = false
	add_child(_prompt)


func _build_subtitle() -> void:
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.offset_left = -560
	_subtitle.offset_right = 560
	_subtitle.offset_top = -150
	_subtitle.offset_bottom = -70
	_subtitle.add_theme_font_size_override("font_size", 26)
	_subtitle.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_subtitle.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle.visible = false
	add_child(_subtitle)
	_subtitle_timer = Timer.new()
	_subtitle_timer.one_shot = true
	_subtitle_timer.timeout.connect(_next_subtitle)
	add_child(_subtitle_timer)


func _build_pause_menu() -> void:
	_pause_menu = ColorRect.new()
	(_pause_menu as ColorRect).color = Color(0, 0, 0, 0.7)
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.visible = false
	add_child(_pause_menu)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = -140
	box.offset_bottom = 140
	box.add_theme_constant_override("separation", 14)
	_pause_menu.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(set_paused.bind(false))
	box.add_child(resume)

	_grain_check = CheckButton.new()
	_grain_check.text = "Film grain and vignette (F2)"
	_grain_check.toggled.connect(_on_grain_toggled)
	box.add_child(_grain_check)

	var sens_label := Label.new()
	sens_label.text = "Mouse sensitivity"
	box.add_child(sens_label)
	_sens_slider = HSlider.new()
	_sens_slider.min_value = 0.5
	_sens_slider.max_value = 6.0
	_sens_slider.step = 0.1
	_sens_slider.value_changed.connect(_on_sensitivity_changed)
	box.add_child(_sens_slider)

	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)


func _on_grain_toggled(on: bool) -> void:
	G.settings().film_grain = on
	G.settings().save()


func _on_sensitivity_changed(value: float) -> void:
	G.settings().mouse_sensitivity = value / 1000.0
	G.settings().save()
