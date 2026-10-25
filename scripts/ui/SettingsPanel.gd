extends VBoxContainer
class_name SettingsPanel
## Settings screen shared by the title menu and the pause menu.
## Sliders preview live; Save writes them; the back button (or cancel()) drops unsaved changes.

signal closed

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _brightness_slider: HSlider
var _fullscreen_check: CheckButton
var _saved_label: Label


func _init(back_label: String = "Back") -> void:
	add_theme_constant_override("separation", 10)
	visible = false

	var title := Label.new()
	title.text = "Settings"
	UITheme.style_title(title, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

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
	add_child(full_row)

	var save_btn := Button.new()
	save_btn.text = "Save Settings"
	save_btn.pressed.connect(_on_save)
	add_child(save_btn)

	var back_btn := Button.new()
	back_btn.text = back_label
	back_btn.pressed.connect(func() -> void:
		cancel()
		closed.emit()
	)
	add_child(back_btn)

	_saved_label = Label.new()
	_saved_label.add_theme_font_size_override("font_size", 12)
	_saved_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.65))
	_saved_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_saved_label)


## Show the panel with the current settings filled in.
func open() -> void:
	visible = true
	_sync()
	_master_slider.grab_focus()


## Drop unsaved changes and hide. The back button also emits `closed`.
func cancel() -> void:
	Settings.revert()
	visible = false


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
	add_child(row)
	return slider


func _sync() -> void:
	## Update labels without re-firing setters (avoids racing volume to 0% on open).
	var pairs := [
		[_master_slider, Settings.master_volume],
		[_music_slider, Settings.music_volume],
		[_sfx_slider, Settings.sfx_volume],
		[_brightness_slider, Settings.brightness],
	]
	for pair in pairs:
		var slider: HSlider = pair[0]
		var pct := roundf(pair[1] * 100.0)
		slider.set_value_no_signal(pct)
		var value_l := slider.get_parent().get_child(2) as Label
		if value_l:
			value_l.text = "%d%%" % int(pct)
	_fullscreen_check.set_pressed_no_signal(Settings.is_fullscreen())
	_saved_label.text = ""


func _on_save() -> void:
	Settings.save_settings()
	_saved_label.text = "Settings saved"
