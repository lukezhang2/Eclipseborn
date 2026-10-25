extends CanvasLayer
class_name AbilityUnlockOverlay
## Full-screen fade-in ability unlock with sprite preview + instructions.


static func show_double_jump(tree: SceneTree) -> void:
	if tree == null:
		return
	var overlay: CanvasLayer = (load("res://scripts/ui/AbilityUnlockOverlay.gd") as Script).new()
	tree.root.add_child(overlay)
	if overlay.has_method("play_double_jump"):
		overlay.call("play_double_jump")


func play_double_jump() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.intro_cutscene_playing = true
	var p = GameState.player
	if p and p.has_method("set_control_locked"):
		p.set_control_locked(true)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -140
	panel.offset_bottom = 140
	panel.add_theme_constant_override("separation", 12)
	panel.modulate.a = 0.0
	root.add_child(panel)

	var title := Label.new()
	title.text = "Double Jump"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
	panel.add_child(title)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(96, 96)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _preview_tex()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(preview)

	var body := Label.new()
	body.text = "A Shadow Crystal Piece settles into your spirit.\nPress Jump again while airborne."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.82, 0.78, 0.7))
	panel.add_child(body)

	var hint := Label.new()
	hint.text = "Press Jump / Interact / Attack to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	panel.add_child(hint)

	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.72, 0.45)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.55)
	await tw.finished

	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("jump") \
				or Input.is_action_just_pressed("interact") \
				or Input.is_action_just_pressed("attack"):
			break

	var tw2 := create_tween()
	tw2.tween_property(panel, "modulate:a", 0.0, 0.25)
	tw2.parallel().tween_property(dim, "color:a", 0.0, 0.3)
	await tw2.finished
	if p and is_instance_valid(p) and p.has_method("set_control_locked"):
		p.set_control_locked(false)
	GameState.intro_cutscene_playing = false
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Double Jump — press Jump again in the air", 4.0)
	queue_free()


func _preview_tex() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	## Spirit silhouette hopping: ground + midair ghost
	_oval(img, 20, 48, 8, 10, Color(0.75, 0.78, 0.85))
	_oval(img, 44, 28, 8, 10, Color(0.75, 0.78, 0.85, 0.55))
	## Arc
	for i in 8:
		var t := float(i) / 7.0
		var x := int(lerp(22.0, 42.0, t))
		var y := int(lerp(42.0, 22.0, t) - sin(t * PI) * 10.0)
		_oval(img, x, y, 1, 1, Color(0.9, 0.75, 0.4, 0.8))
	return ImageTexture.create_from_image(img)


func _oval(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= 64 or y >= 64:
				continue
			var dx := float(x - cx) / float(maxi(rx, 1))
			var dy := float(y - cy) / float(maxi(ry, 1))
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)
