extends Control
## Black glass holds 1.5s, branching cracks grow, then shards fly off into the gear title.


var _gear_spinning: bool = true
var _done: bool = false
var _gears: GearBackdrop
var _black: ColorRect
var _shards: Node2D
var _cracks: Node2D
var _title_ui: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_scene()
	_animate()


func _build_scene() -> void:
	_gears = GearBackdrop.new()
	_gears.name = "Gears"
	_gears.z_index = -5
	add_child(_gears)
	_gears.build()

	var title := Label.new()
	title.text = "ECLIPSEBORN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -260
	title.offset_right = 260
	title.offset_top = -130
	title.offset_bottom = -60
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1))
	title.name = "RevealTitle"
	add_child(title)

	_black = ColorRect.new()
	_black.color = Color(0.01, 0.01, 0.015, 1)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.name = "Black"
	add_child(_black)

	_cracks = Node2D.new()
	_cracks.name = "Cracks"
	add_child(_cracks)

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


func _animate() -> void:
	await get_tree().create_timer(1.5).timeout
	if _done:
		return
	AudioManager.play_boot_crack()
	await _grow_realistic_cracks()
	if _done:
		return
	AudioManager.play_boot_gears()
	_spawn_shards_from_cracks()
	if _black:
		create_tween().tween_property(_black, "modulate:a", 0.0, 0.2)

	for shard in _shards.get_children():
		if not shard is Node2D:
			continue
		var dir: Vector2 = shard.get_meta("dir", Vector2.RIGHT)
		var target: Vector2 = (shard as Node2D).position + dir * 1700.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", target, randf_range(0.9, 1.5)).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "rotation_degrees", randf_range(-160, 160), 1.2)
		tw.tween_property(shard, "modulate:a", 0.0, 1.35)

	if _cracks:
		create_tween().tween_property(_cracks, "modulate:a", 0.0, 0.5)

	await get_tree().create_timer(1.55).timeout
	_finish()


func _grow_realistic_cracks() -> void:
	## Branching lightning-style cracks from impact center, with secondary forks.
	var center := Vector2(640, 360)
	var branches: Array = []
	# Primary spokes
	for i in 7:
		var ang := -PI * 0.15 + i * (TAU / 7.0) + randf_range(-0.08, 0.08)
		branches.append({"from": center, "ang": ang, "len": randf_range(280, 420), "w": 3.2})
	# Secondary forks
	for i in 9:
		var ang := randf() * TAU
		var start := center + Vector2(cos(ang), sin(ang)) * randf_range(60, 160)
		branches.append({"from": start, "ang": ang + randf_range(-0.4, 0.4), "len": randf_range(90, 200), "w": 1.8})

	for b in branches:
		var line := Line2D.new()
		line.width = float(b["w"])
		line.default_color = Color(0.88, 0.92, 1.0, 0.0)
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		var from: Vector2 = b["from"]
		var ang: float = b["ang"]
		var remaining: float = b["len"]
		var pt := from
		line.add_point(pt)
		# Jagged polyline
		while remaining > 8.0:
			var step := mini(remaining, randf_range(18, 42))
			ang += randf_range(-0.35, 0.35)
			pt = pt + Vector2(cos(ang), sin(ang)) * step
			# Keep roughly on screen
			pt.x = clampf(pt.x, 20, 1260)
			pt.y = clampf(pt.y, 20, 700)
			line.add_point(pt)
			remaining -= step
		_cracks.add_child(line)
		# Fade crack in quickly for glass shatter feel
		create_tween().tween_property(line, "default_color:a", 0.95, 0.12)
		await get_tree().create_timer(0.045).timeout
		if _done:
			return
	# Inner impact star
	var star := Line2D.new()
	star.width = 2.0
	star.default_color = Color(1, 1, 1, 0.9)
	for i in 8:
		var a := i * TAU / 8.0
		star.add_point(center)
		star.add_point(center + Vector2(cos(a), sin(a)) * 28.0)
	_cracks.add_child(star)
	await get_tree().create_timer(0.15).timeout


func _spawn_shards_from_cracks() -> void:
	## Irregular shards that still cover the viewport (overlap), then fly outward.
	var center := Vector2(640, 360)
	var cols := 7
	var rows := 5
	var cell_w := 1280.0 / float(cols)
	var cell_h := 720.0 / float(rows)
	for row in rows:
		for col in cols:
			var holder := Node2D.new()
			var cx := (float(col) + 0.5) * cell_w + randf_range(-8, 8)
			var cy := (float(row) + 0.5) * cell_h + randf_range(-8, 8)
			holder.position = Vector2(cx, cy)
			var shard := Polygon2D.new()
			shard.color = Color(0.015, 0.015, 0.02, 1.0)
			# Irregular pentagon with overlap so no gaps while covering
			var pts := PackedVector2Array()
			var hw := cell_w * 0.62
			var hh := cell_h * 0.62
			for k in 5:
				var a := -PI * 0.5 + k * TAU / 5.0 + randf_range(-0.15, 0.15)
				pts.append(Vector2(cos(a) * hw, sin(a) * hh))
			shard.polygon = pts
			holder.add_child(shard)
			var edge := Line2D.new()
			edge.width = 1.2
			edge.default_color = Color(0.7, 0.78, 0.9, 0.55)
			for p in pts:
				edge.add_point(p)
			edge.add_point(pts[0])
			holder.add_child(edge)
			var dir := (Vector2(cx, cy) - center).normalized()
			if dir.length() < 0.05:
				dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			holder.set_meta("dir", dir)
			_shards.add_child(holder)


func _finish() -> void:
	if _done:
		return
	_done = true
	_gear_spinning = true
	if _black:
		_black.visible = false
	if _shards:
		_shards.visible = false
	if _cracks:
		_cracks.visible = false
	_show_title_ui()


func _show_title_ui() -> void:
	var reveal := get_node_or_null("RevealTitle")
	if reveal:
		reveal.queue_free()
	_title_ui = preload("res://scenes/ui/TitleMenu.tscn").instantiate()
	_title_ui.set_meta("embedded_boot", true)
	add_child(_title_ui)
	await get_tree().process_frame
	var bg := _title_ui.get_node_or_null("BG")
	if bg:
		bg.visible = false
	var steam := _title_ui.get_node_or_null("Steam")
	if steam:
		steam.modulate.a = 0.2
