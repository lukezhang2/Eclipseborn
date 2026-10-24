extends Node
## Inverted light model: the map is shadow (solid floors). Lights cast burning light.
## Occluders block light, creating safe pockets. No extruded shadow platforms.

signal shadows_rebuilt

var lights: Array = []
var occluders: Array = []
var _root: Node2D = null
var _dirty: bool = true
var _visuals: Array = []


func register_light(light: Node) -> void:
	if not lights.has(light):
		lights.append(light)
	_dirty = true


func unregister_light(light: Node) -> void:
	lights.erase(light)
	_dirty = true


func register_occluder(occ: Node) -> void:
	if not occluders.has(occ):
		occluders.append(occ)
	_dirty = true


func unregister_occluder(occ: Node) -> void:
	occluders.erase(occ)
	_dirty = true


func mark_dirty() -> void:
	_dirty = true


func set_world_root(root: Node2D) -> void:
	_clear_visuals()
	_root = root
	_dirty = true


func _physics_process(_delta: float) -> void:
	for light in lights:
		if is_instance_valid(light) and light.has_method("did_move") and light.did_move():
			_dirty = true
	for occ in occluders:
		if is_instance_valid(occ) and occ.has_method("did_move") and occ.did_move():
			_dirty = true
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_clear_visuals()
	if _root == null or not is_instance_valid(_root):
		return
	lights = lights.filter(func(n): return is_instance_valid(n))
	occluders = occluders.filter(func(n): return is_instance_valid(n))

	# Soft ambient shadow wash over the playfield (the world is dark).
	var wash := Polygon2D.new()
	wash.color = Color(0.08, 0.05, 0.12, 0.22)
	wash.polygon = PackedVector2Array([
		Vector2(-200, -200), Vector2(5000, -200), Vector2(5000, 900), Vector2(-200, 900)
	])
	wash.z_index = -15
	_root.add_child(wash)
	_visuals.append(wash)

	for light in lights:
		if not light.is_on():
			continue
		_draw_light_disc(light)
		for occ in occluders:
			_draw_safe_umbra(light, occ)

	shadows_rebuilt.emit()


func _draw_light_disc(light: Node) -> void:
	## Clear danger volume — bright core + warm ring so players see where they cannot stand.
	var origin: Vector2 = light.get_light_origin()
	var radius: float = light.get_radius()
	var kind: int = light.get_light_kind()
	var burns := kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]
	var core := Color(1.0, 0.72, 0.28, 0.28 if burns else 0.1)
	var rim := Color(1.0, 0.45, 0.12, 0.42 if burns else 0.12)
	match kind:
		GameState.LightKind.MOON:
			core = Color(0.65, 0.85, 1.0, 0.12)
			rim = Color(0.5, 0.7, 1.0, 0.18)
		GameState.LightKind.CRIMSON:
			core = Color(0.95, 0.2, 0.25, 0.22)
			rim = Color(0.8, 0.1, 0.15, 0.35)
		GameState.LightKind.SUNSHAFT:
			core = Color(1.0, 1.0, 0.85, 0.32)
			rim = Color(1.0, 0.9, 0.5, 0.45)
	# Soft fill
	var fill := Polygon2D.new()
	fill.color = core
	fill.z_index = -12
	fill.polygon = _circle_pts(origin, radius, 28)
	_root.add_child(fill)
	_visuals.append(fill)
	# Danger ring (outer edge)
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = rim
	ring.z_index = -11
	for p in _circle_pts(origin, radius, 36):
		ring.add_point(p)
	ring.add_point(ring.get_point_position(0))
	_root.add_child(ring)
	_visuals.append(ring)
	if burns:
		var warn := Label.new()
		warn.text = "!"
		warn.position = origin + Vector2(-6, -radius * 0.15)
		warn.z_index = -10
		warn.add_theme_font_size_override("font_size", 18)
		warn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2, 0.65))
		_root.add_child(warn)
		_visuals.append(warn)


func _circle_pts(origin: Vector2, radius: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(origin + Vector2(cos(a), sin(a)) * radius)
	return pts


func _draw_safe_umbra(light: Node, occ: Node) -> void:
	## Soft safe pocket only — no hard extruded box-shadow wedges.
	## Skip box occluders entirely (boxes still block light via physics ray).
	if occ.get_parent() != null and occ.get_parent().is_in_group("boxes"):
		return
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var light_pos: Vector2 = light.get_light_origin()
	var max_len: float = light.get_shadow_length() * 0.55
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var mid := (a + b) * 0.5
		var edge_dir := (b - a).normalized()
		var normal := Vector2(-edge_dir.y, edge_dir.x)
		if normal.dot((mid - light_pos).normalized()) <= 0.0:
			continue
		var da := (a - light_pos).normalized() * max_len
		var db := (b - light_pos).normalized() * max_len
		var ink := Polygon2D.new()
		ink.color = Color(0.05, 0.03, 0.08, 0.28)
		ink.z_index = -11
		ink.polygon = PackedVector2Array([a, b, b + db, a + da])
		_root.add_child(ink)
		_visuals.append(ink)


func _clear_visuals() -> void:
	for v in _visuals:
		if is_instance_valid(v):
			v.queue_free()
	_visuals.clear()
