extends Control
## Black glass holds 1.5s, cracks, tessellated shards fly off revealing gear title.


var _gear_spinning: bool = true
var _done: bool = false
var _gears: GearBackdrop
var _black: ColorRect
var _shards: Node2D
var _title_ui: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_scene()
	_animate()


func _build_scene() -> void:
	# Gear backdrop is the permanent Eclipseborn background.
	_gears = GearBackdrop.new()
	_gears.name = "Gears"
	_gears.z_index = -5
	add_child(_gears)
	_gears.build()

	# Title label under the glass (revealed with gears).
	var title := Label.new()
	title.text = "ECLIPSEBORN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -240
	title.offset_right = 240
	title.offset_top = -120
	title.offset_bottom = -60
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 1))
	title.name = "RevealTitle"
	add_child(title)

	_black = ColorRect.new()
	_black.color = Color(0.01, 0.01, 0.015, 1)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.name = "Black"
	add_child(_black)

	_shards = Node2D.new()
	_shards.name = "Shards"
	add_child(_shards)

	var skip := Label.new()
	skip.text = "Space / Esc to skip"
	skip.position = Vector2(40, 680)
	skip.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.7))
	add_child(skip)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		_finish()


func _process(delta: float) -> void:
	# GearBackdrop spins itself; keep flag for skip path.
	if not _gear_spinning and _gears:
		_gears.set_process(false)


func _animate() -> void:
	# Hold solid black for 1.5s, then crack.
	await get_tree().create_timer(1.5).timeout
	if _done:
		return
	AudioManager.play_boot_crack()
	_build_tessellated_shards()
	await get_tree().create_timer(0.35).timeout
	if _done:
		return
	AudioManager.play_boot_gears()

	# Fade the solid black under shards; shards cover screen already.
	if _black:
		create_tween().tween_property(_black, "modulate:a", 0.0, 0.25)

	for shard in _shards.get_children():
		if shard.name == "CrackLines":
			create_tween().tween_property(shard, "modulate:a", 0.0, 0.4)
			continue
		if not shard is Node2D:
			continue
		var dir: Vector2 = shard.get_meta("dir", Vector2.RIGHT)
		var target: Vector2 = (shard as Node2D).position + dir * 1600.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", target, randf_range(1.0, 1.55)).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "rotation_degrees", randf_range(-100, 100), 1.3)
		tw.tween_property(shard, "modulate:a", 0.0, 1.4)

	await get_tree().create_timer(1.6).timeout
	_finish()


func _build_tessellated_shards() -> void:
	## Grid of black cells that tile the full 1280x720 viewport — no gaps/overlaps.
	var cols := 8
	var rows := 5
	var cell_w := 1280.0 / float(cols)
	var cell_h := 720.0 / float(rows)
	var center := Vector2(640, 360)
	for row in rows:
		for col in cols:
			var holder := Node2D.new()
			var cx := (float(col) + 0.5) * cell_w
			var cy := (float(row) + 0.5) * cell_h
			holder.position = Vector2(cx, cy)
			var shard := Polygon2D.new()
			shard.color = Color(0.02, 0.02, 0.03, 1.0)
			var hw := cell_w * 0.5
			var hh := cell_h * 0.5
			# Slight irregular edge on the outward side only — still covers via overlap of 1px.
			shard.polygon = PackedVector2Array([
				Vector2(-hw - 0.5, -hh - 0.5),
				Vector2(hw + 0.5, -hh - 0.5),
				Vector2(hw + 0.5, hh + 0.5),
				Vector2(-hw - 0.5, hh + 0.5),
			])
			holder.add_child(shard)
			var edge := Line2D.new()
			edge.width = 1.5
			edge.default_color = Color(0.75, 0.8, 0.9, 0.7)
			for p in shard.polygon:
				edge.add_point(p)
			edge.add_point(shard.polygon[0])
			holder.add_child(edge)
			var dir := (Vector2(cx, cy) - center).normalized()
			if dir.length() < 0.1:
				dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			holder.set_meta("dir", dir)
			_shards.add_child(holder)

	var cracks := Line2D.new()
	cracks.name = "CrackLines"
	cracks.width = 3.0
	cracks.default_color = Color(0.85, 0.88, 0.95, 0.95)
	cracks.add_point(center)
	cracks.add_point(Vector2(200, 100))
	cracks.add_point(center)
	cracks.add_point(Vector2(1100, 80))
	cracks.add_point(center)
	cracks.add_point(Vector2(150, 600))
	cracks.add_point(center)
	cracks.add_point(Vector2(1180, 640))
	cracks.add_point(center)
	cracks.add_point(Vector2(640, 40))
	cracks.add_point(center)
	cracks.add_point(Vector2(640, 700))
	_shards.add_child(cracks)


func _finish() -> void:
	if _done:
		return
	_done = true
	_gear_spinning = true
	if _black:
		_black.visible = false
	if _shards:
		_shards.visible = false
	_show_title_ui()


func _show_title_ui() -> void:
	# Keep gears; mount TitleMenu UI in-place (no scene wipe).
	var reveal := get_node_or_null("RevealTitle")
	if reveal:
		reveal.queue_free()
	_title_ui = preload("res://scenes/ui/TitleMenu.tscn").instantiate()
	_title_ui.set_meta("embedded_boot", true)
	# Hide TitleMenu's own solid BG so gears show through.
	add_child(_title_ui)
	await get_tree().process_frame
	var bg := _title_ui.get_node_or_null("BG")
	if bg:
		bg.visible = false
	var steam := _title_ui.get_node_or_null("Steam")
	if steam:
		steam.modulate.a = 0.35
