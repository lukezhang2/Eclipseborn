extends Control
## Black glass holds 1.5s, branching cracks grow, then shards fly off into the gear title.


var _gear_spinning: bool = true
var _done: bool = false
var _gears: GearBackdrop
var _black: ColorRect
var _shards: Node2D
var _cracks: Node2D

## Crack look: 0 original, 1 glass shatter, 2 ember fissure, 3 shadow ink, 4 clockwork.
## GameState meta "preview_crack_style" overrides it (review tool only).
const CRACK_STYLE := 4
const CRACK_LOOKS := [
	{"core": Color(0.88, 0.92, 1.0), "glow": Color(0, 0, 0, 0), "edge": Color(0.7, 0.78, 0.9, 0.55), "wiggle": 0.35, "impact": "star", "sparks": Color(0, 0, 0, 0)},
	{"core": Color(0.95, 0.97, 1.0), "glow": Color(0.6, 0.8, 1.0, 0.35), "edge": Color(0.8, 0.88, 1.0, 0.7), "wiggle": 0.3, "impact": "rings", "sparks": Color(0.85, 0.92, 1.0)},
	{"core": Color(1.0, 0.82, 0.45), "glow": Color(0.95, 0.35, 0.12, 0.45), "edge": Color(1.0, 0.55, 0.2, 0.85), "wiggle": 0.4, "impact": "flash", "sparks": Color(1.0, 0.6, 0.2)},
	{"core": Color(0.78, 0.66, 1.0), "glow": Color(0.42, 0.3, 0.6, 0.55), "edge": Color(0.56, 0.42, 0.79, 0.8), "wiggle": 0.14, "impact": "blot", "sparks": Color(0.6, 0.45, 0.9)},
	{"core": Color(1.0, 0.86, 0.55), "glow": Color(0.69, 0.55, 0.34, 0.4), "edge": Color(0.88, 0.75, 0.5, 0.75), "wiggle": 0.25, "impact": "gear", "sparks": Color(0.95, 0.75, 0.4)},
]
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

	# The real, fully styled title menu sits behind the glass from the start, so the shatter
	# reveals it directly (a plain placeholder label used to flash first).
	_title_ui = preload("res://scenes/ui/TitleMenu.tscn").instantiate()
	_title_ui.set_meta("embedded_boot", true)
	add_child(_title_ui)
	_style_embedded_title()
	_title_ui.process_mode = Node.PROCESS_MODE_DISABLED  # No keyboard focus/input until revealed.

	_black = ColorRect.new()
	_black.color = Color(0.01, 0.01, 0.015, 1)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Blocks clicks on the title menu underneath until the intro finishes.
	_black.mouse_filter = Control.MOUSE_FILTER_STOP
	_black.name = "Black"
	add_child(_black)

	_cracks = Node2D.new()
	_cracks.name = "Cracks"
	add_child(_cracks)

	_shards = Node2D.new()
	_shards.name = "Shards"
	add_child(_shards)

	var skip := Label.new()
	skip.name = "SkipHint"
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


func _look() -> Dictionary:
	var i := int(GameState.get_meta("preview_crack_style", CRACK_STYLE)) if GameState.has_meta("preview_crack_style") else CRACK_STYLE
	return CRACK_LOOKS[clampi(i, 0, CRACK_LOOKS.size() - 1)]


func _grow_realistic_cracks() -> void:
	## Branching lightning-style cracks from impact center, with secondary forks.
	var center := Vector2(640, 360)
	var look := _look()
	_draw_impact(center, look)
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
		var core: Color = look["core"]
		line.default_color = Color(core, 0.0)
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
			ang += randf_range(-float(look["wiggle"]), float(look["wiggle"]))
			pt = pt + Vector2(cos(ang), sin(ang)) * step
			# Keep roughly on screen
			pt.x = clampf(pt.x, 20, 1260)
			pt.y = clampf(pt.y, 20, 700)
			line.add_point(pt)
			remaining -= step
		# Dark edge + soft glow under the bright core so cracks read on black glass.
		var glow_col: Color = look["glow"]
		if glow_col.a > 0.0:
			var glow := line.duplicate() as Line2D
			glow.width = line.width * 5.0
			glow.default_color = Color(glow_col, 0.0)
			_cracks.add_child(glow)
			create_tween().tween_property(glow, "default_color:a", glow_col.a, 0.18)
		_cracks.add_child(line)
		# Fade crack in quickly for glass shatter feel
		create_tween().tween_property(line, "default_color:a", 0.95, 0.12)
		await get_tree().create_timer(0.045).timeout
		if _done:
			return
	_burst_sparks(center, look)
	await get_tree().create_timer(0.15).timeout


## The mark where the glass is struck: star, fracture rings, flash, ink blot or brass gear.
func _draw_impact(center: Vector2, look: Dictionary) -> void:
	var core: Color = look["core"]
	match str(look["impact"]):
		"star":
			var star := Line2D.new()
			star.width = 2.0
			star.default_color = Color(1, 1, 1, 0.9)
			for i in 8:
				var a := i * TAU / 8.0
				star.add_point(center)
				star.add_point(center + Vector2(cos(a), sin(a)) * 28.0)
			_cracks.add_child(star)
		"rings":
			for k in 3:
				var ring := Line2D.new()
				ring.width = 1.6
				ring.default_color = Color(core, 0.0)
				var rad := 40.0 + k * 55.0
				for i in 25:
					var a := TAU * i / 24.0
					ring.add_point(center + Vector2(cos(a), sin(a)) * rad * randf_range(0.92, 1.08))
				_cracks.add_child(ring)
				create_tween().tween_property(ring, "default_color:a", 0.7, 0.3).set_delay(0.25 + k * 0.12)
			_flash(center, Color(0.8, 0.9, 1.0), 90.0)
		"flash":
			_flash(center, Color(1.0, 0.6, 0.25), 140.0)
		"blot":
			var blot := Polygon2D.new()
			var pts := PackedVector2Array()
			for i in 18:
				var a := TAU * i / 18.0
				pts.append(center + Vector2(cos(a), sin(a)) * randf_range(16, 30))
			blot.polygon = pts
			blot.color = Color(0.3, 0.2, 0.45, 0.0)
			_cracks.add_child(blot)
			create_tween().tween_property(blot, "color:a", 0.9, 0.3)
		"gear":
			var gear := Line2D.new()
			gear.width = 3.0
			gear.default_color = Color(core, 0.0)
			for i in 41:
				var a := TAU * i / 40.0
				var r := 34.0 if (i / 2) % 2 == 0 else 44.0
				gear.add_point(center + Vector2(cos(a), sin(a)) * r)
			_cracks.add_child(gear)
			create_tween().tween_property(gear, "default_color:a", 0.95, 0.15)
			var hub := Line2D.new()
			hub.width = 2.0
			hub.default_color = Color(core, 0.8)
			for i in 17:
				var a := TAU * i / 16.0
				hub.add_point(center + Vector2(cos(a), sin(a)) * 12.0)
			_cracks.add_child(hub)


func _flash(center: Vector2, col: Color, rad: float) -> void:
	var f := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * rad)
	f.polygon = pts
	f.position = center
	f.color = Color(col, 0.55)
	f.scale = Vector2(0.2, 0.2)
	_cracks.add_child(f)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(f, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "color:a", 0.0, 0.6)


func _burst_sparks(center: Vector2, look: Dictionary) -> void:
	var col: Color = look["sparks"]
	if col.a <= 0.0:
		return
	var p := CPUParticles2D.new()
	p.position = center
	p.amount = 60
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.9
	p.spread = 180.0
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 420.0
	p.gravity = Vector2(0, 380)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(col, 1.0), Color(col, 0.0)])
	p.color_ramp = ramp
	_cracks.add_child(p)
	p.emitting = true


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
			edge.default_color = _look()["edge"]
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
		_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shards:
		_shards.visible = false
	if _cracks:
		_cracks.visible = false
	var skip := get_node_or_null("SkipHint")
	if skip:
		skip.queue_free()
	if _title_ui:
		_title_ui.process_mode = Node.PROCESS_MODE_INHERIT


## The boot screen keeps its own gear backdrop, so hide the menu's BG and dim its steam.
func _style_embedded_title() -> void:
	var bg := _title_ui.get_node_or_null("BG")
	if bg:
		bg.visible = false
	var steam := _title_ui.get_node_or_null("Steam")
	if steam:
		steam.modulate.a = 0.2
