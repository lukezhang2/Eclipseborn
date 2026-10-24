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
	var origin: Vector2 = light.get_light_origin()
	var radius: float = light.get_radius()
	var kind: int = light.get_light_kind()
	var col := Color(1.0, 0.75, 0.35, 0.18)
	match kind:
		GameState.LightKind.CANDLE:
			col = Color(1.0, 0.65, 0.3, 0.16)
		GameState.LightKind.MOON:
			col = Color(0.65, 0.8, 1.0, 0.12)
		GameState.LightKind.CRIMSON:
			col = Color(0.9, 0.15, 0.2, 0.2)
		GameState.LightKind.SUNSHAFT:
			col = Color(1.0, 1.0, 0.9, 0.22)
	var poly := Polygon2D.new()
	poly.color = col
	poly.z_index = -12
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(origin + Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	_root.add_child(poly)
	_visuals.append(poly)


func _draw_safe_umbra(light: Node, occ: Node) -> void:
	## Visual ink wedge behind an occluder = safe shadow pocket inside light.
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var light_pos: Vector2 = light.get_light_origin()
	var max_len: float = light.get_shadow_length()
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
		ink.color = Color(0.07, 0.04, 0.1, 0.45)
		ink.z_index = -11
		ink.polygon = PackedVector2Array([a, b, b + db, a + da])
		_root.add_child(ink)
		_visuals.append(ink)
		var edge := Line2D.new()
		edge.width = 1.5
		edge.default_color = Color(0.35, 0.2, 0.5, 0.5)
		edge.z_index = -10
		for p in ink.polygon:
			edge.add_point(p)
		edge.add_point(ink.polygon[0])
		_root.add_child(edge)
		_visuals.append(edge)


func _clear_visuals() -> void:
	for v in _visuals:
		if is_instance_valid(v):
			v.queue_free()
	_visuals.clear()
