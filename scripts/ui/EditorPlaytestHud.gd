extends CanvasLayer
## Exit playtest overlay — returns to the level editor.


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var btn := Button.new()
	btn.text = "Exit Playtest"
	btn.position = Vector2(24, 24)
	btn.custom_minimum_size = Vector2(160, 36)
	btn.pressed.connect(_exit)
	root.add_child(btn)
	var hint := Label.new()
	hint.text = "Playtesting editor overlay — not a real save run"
	hint.position = Vector2(200, 30)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	root.add_child(hint)


func _exit() -> void:
	GameState.editor_playtesting = false
	GameState.pending_spawn = Vector2.ZERO
	GameState.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/editor/LevelEditor.tscn")
