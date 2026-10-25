extends Control
## End-of-demo screen after descending the village tower shaft.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.set_paused(false)
	GameState.intro_cutscene_playing = false
	theme = UITheme.get_theme()
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.07, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var gears := GearBackdrop.new()
	gears.name = "GearBackdrop"
	gears.z_index = -1
	add_child(gears)
	gears.build()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	UITheme.add_plate(panel, Vector2(48, 36))

	var title := Label.new()
	title.text = "Demo Complete"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, 42)
	panel.add_child(title)

	var body := Label.new()
	body.text = "You brought down the Wickwright and descended the shaft.\nThanks for playing this Eclipseborn demo."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62))
	panel.add_child(body)

	var hint := Label.new()
	hint.text = "More of the tower waits beyond this build."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.56, 0.48))
	panel.add_child(hint)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	panel.add_child(btn_row)

	var title_btn := Button.new()
	title_btn.text = "Return to Title"
	title_btn.custom_minimum_size = Vector2(200, 40)
	title_btn.pressed.connect(_go_title)
	btn_row.add_child(title_btn)

	var ver := Label.new()
	ver.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45, 0.8))
	panel.add_child(ver)


func _go_title() -> void:
	GameState.set_paused(false)
	ZoneTransition.go(get_tree(), "res://scenes/ui/TitleMenu.tscn", "Returning…")
