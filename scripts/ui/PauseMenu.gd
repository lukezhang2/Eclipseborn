extends CanvasLayer
## Esc menu during play. Pauses in single player. Includes Controls rebind and Settings.

@onready var root: Control = $Root
@onready var main_box: VBoxContainer = $Root/Center/Main
@onready var controls_box: VBoxContainer = $Root/Center/Controls
@onready var controls_list: VBoxContainer = $Root/Center/Controls/List

var settings_box: VBoxContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _brightness_slider: HSlider
var _fullscreen_check: CheckButton
var _saved_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	controls_box.visible = false
	_build_settings()
	InputMapManager.bindings_changed.connect(_build_controls)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if root.visible and controls_box.visible:
			_show_main()
			get_viewport().set_input_as_handled()
			return
		if root.visible and settings_box.visible:
			Settings.revert()
			_show_main()
			get_viewport().set_input_as_handled()
			return
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if root.visible:
		close()
	else:
		open()


func open() -> void:
	root.visible = true
	_show_main()
	GameState.set_paused(true)


func close() -> void:
	root.visible = false
	InputMapManager.cancel_rebind()
	GameState.set_paused(false)


func _show_main() -> void:
	main_box.visible = true
	controls_box.visible = false
	settings_box.visible = false


func _show_controls() -> void:
	main_box.visible = false
	controls_box.visible = true
	_build_controls()


func _show_settings() -> void:
	main_box.visible = false
	settings_box.visible = true
	_saved_label.text = ""
	_sync_settings_ui()
	_master_slider.grab_focus()


func _build_settings() -> void:
	settings_box = VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 10)
	settings_box.visible = false
	$Root/Center.add_child(settings_box)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(title)

	_master_slider = _add_slider("Master Volume", 0, 100, Settings.set_master_volume)
	_music_slider = _add_slider("Music", 0, 100, Settings.set_music_volume)
	_sfx_slider = _add_slider("Sound Effects", 0, 100, Settings.set_sfx_volume)
	_brightness_slider = _add_slider("Brightness",
		Settings.MIN_BRIGHTNESS * 100, Settings.MAX_BRIGHTNESS * 100, Settings.set_brightness)

	var full_row := HBoxContainer.new()
	var full_l := Label.new()
	full_l.text = "Fullscreen"
	full_l.custom_minimum_size.x = 160
	full_row.add_child(full_l)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.toggled.connect(Settings.set_fullscreen)
	full_row.add_child(_fullscreen_check)
	settings_box.add_child(full_row)

	var save_btn := Button.new()
	save_btn.text = "Save Settings"
	save_btn.pressed.connect(_on_save_settings)
	settings_box.add_child(save_btn)

	var back_btn := Button.new()
	back_btn.text = "Back to Game"
	back_btn.pressed.connect(_on_settings_back_to_game)
	settings_box.add_child(back_btn)

	_saved_label = Label.new()
	_saved_label.add_theme_font_size_override("font_size", 12)
	_saved_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.65))
	_saved_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(_saved_label)


## Slider shows whole percents; the setter gets the value as a fraction (70% → 0.7).
func _add_slider(label: String, min_v: float, max_v: float, setter: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var name_l := Label.new()
	name_l.text = label
	name_l.custom_minimum_size.x = 160
	row.add_child(name_l)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 1
	slider.custom_minimum_size = Vector2(200, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_l := Label.new()
	value_l.custom_minimum_size.x = 48
	value_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_l)
	slider.value_changed.connect(func(v: float) -> void:
		value_l.text = "%d%%" % int(v)
		setter.call(v / 100.0)
		_saved_label.text = ""
	)
	settings_box.add_child(row)
	return slider


func _sync_settings_ui() -> void:
	var pairs := [
		[_master_slider, Settings.master_volume],
		[_music_slider, Settings.music_volume],
		[_sfx_slider, Settings.sfx_volume],
		[_brightness_slider, Settings.brightness],
	]
	for pair in pairs:
		var slider: HSlider = pair[0]
		slider.set_value_no_signal(roundf(pair[1] * 100))
		slider.value_changed.emit(slider.value)  # Refresh the % label.
	_fullscreen_check.set_pressed_no_signal(Settings.is_fullscreen())
	_saved_label.text = ""


func _on_save_settings() -> void:
	Settings.save_settings()
	_saved_label.text = "Settings saved"


func _on_settings_back_to_game() -> void:
	Settings.revert()
	close()


func _build_controls() -> void:
	for c in controls_list.get_children():
		c.queue_free()
	for action in InputMapManager.ACTIONS:
		var row := HBoxContainer.new()
		var name_l := Label.new()
		name_l.text = InputMapManager.get_action_display(action)
		name_l.custom_minimum_size.x = 160
		row.add_child(name_l)
		var key_btn := Button.new()
		key_btn.text = InputMapManager.get_binding_text(action)
		key_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		key_btn.pressed.connect(_on_rebind.bind(action, key_btn))
		row.add_child(key_btn)
		controls_list.add_child(row)


func _on_rebind(action: String, btn: Button) -> void:
	btn.text = "Press a key…"
	InputMapManager.begin_rebind(action)
	await InputMapManager.bindings_changed
	btn.text = InputMapManager.get_binding_text(action)


func _on_resume() -> void:
	close()


func _on_controls() -> void:
	_show_controls()


func _on_settings() -> void:
	_show_settings()


func _on_back() -> void:
	_show_main()


func _on_title() -> void:
	SaveManager.autosave()
	close()
	get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
