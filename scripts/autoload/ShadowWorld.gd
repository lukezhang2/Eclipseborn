extends Node
## Hard-cut lantern washes. Rays exclude each lamp's own body so the radius never collapses.


signal shadows_rebuilt

const RAY_COUNT := 72
const OCCLUDER_MASK := 1 | 8

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
	if not _root.is_inside_tree():
		_dirty = true
		return
	var world := _root.get_world_2d()
	if world == null:
		_dirty = true
		return

	lights = lights.filter(func(n): return is_instance_valid(n))
	occluders = occluders.filter(func(n): return is_instance_valid(n))

	for light in lights:
		if not light.has_method("is_on") or not light.is_on():
			continue
		_draw_occluded_light(light, world.direct_space_state)

	shadows_rebuilt.emit()


func _draw_occluded_light(light: Node, space: PhysicsDirectSpaceState2D) -> void:
	var origin: Vector2 = light.get_light_origin()
	var radius: float = maxf(light.get_radius(), 8.0)
	var kind: int = light.get_light_kind()
	var burns := kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]
	var core := Color(1.0, 0.72, 0.28, 0.34 if burns else 0.14)
	match kind:
		GameState.LightKind.MOON:
			core = Color(0.65, 0.85, 1.0, 0.16)
		GameState.LightKind.CRIMSON:
			core = Color(0.95, 0.2, 0.25, 0.28)
		GameState.LightKind.SUNSHAFT:
			core = Color(1.0, 1.0, 0.85, 0.38)
		GameState.LightKind.CANDLE:
			core = Color(1.0, 0.7, 0.4, 0.3)

	var exclude: Array = []
	if light.has_method("get_exclude_rids"):
		exclude = light.get_exclude_rids()

	var pts := PackedVector2Array()
	pts.append(origin)
	for i in RAY_COUNT:
		var a := TAU * float(i) / float(RAY_COUNT)
		var dir := Vector2(cos(a), sin(a))
		# Nudge off the origin so we never start inside our own collider.
		var from := origin + dir * 2.0
		var to := origin + dir * radius
		var q := PhysicsRayQueryParameters2D.create(from, to)
		q.collision_mask = OCCLUDER_MASK
		q.hit_from_inside = false
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			pts.append(to)
		else:
			pts.append(hit.position - dir * 0.75)

	# Degenerate guard — always show at least a small disc.
	if pts.size() < 4:
		pts = PackedVector2Array([origin])
		for i in 24:
			var a := TAU * float(i) / 24.0
			pts.append(origin + Vector2(cos(a), sin(a)) * mini(radius, 40.0))

	var fill := Polygon2D.new()
	fill.color = core
	fill.z_index = -12
	fill.polygon = pts
	_root.add_child(fill)
	_visuals.append(fill)

	var ring := Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(core.r, core.g, core.b, mini(0.75, core.a + 0.3))
	ring.z_index = -11
	for i in range(1, pts.size()):
		ring.add_point(pts[i])
	if pts.size() > 1:
		ring.add_point(pts[1])
	_root.add_child(ring)
	_visuals.append(ring)

	for occ in occluders:
		_draw_umbra_wedge(light, occ, origin, radius)


func _draw_umbra_wedge(light: Node, occ: Node, light_pos: Vector2, radius: float) -> void:
	if not occ.has_method("get_world_polygon"):
		return
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var aabb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		aabb = aabb.expand(p)
	if aabb.size.x > 280.0 or aabb.size.y > 320.0:
		return
	var near := false
	for p in poly:
		if p.distance_to(light_pos) <= radius * 1.15:
			near = true
			break
	if not near:
		return
	var max_len: float = light.get_shadow_length() if light.has_method("get_shadow_length") else radius
	max_len = mini(max_len, radius * 1.05)
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var mid := (a + b) * 0.5
		var edge_dir := (b - a).normalized()
		var normal := Vector2(-edge_dir.y, edge_dir.x)
		if absf(normal.x) > absf(normal.y) and aabb.size.x > aabb.size.y:
			continue
		if normal.dot((mid - light_pos).normalized()) <= 0.15:
			continue
		var da := (a - light_pos).normalized() * max_len
		var db := (b - light_pos).normalized() * max_len
		var ink := Polygon2D.new()
		ink.color = Color(0.04, 0.02, 0.07, 0.4)
		ink.z_index = -11
		ink.polygon = PackedVector2Array([a, b, b + db, a + da])
		_root.add_child(ink)
		_visuals.append(ink)


func is_point_in_light(origin: Vector2, radius: float, point: Vector2, exclude: Array = []) -> bool:
	if point.distance_to(origin) > radius:
		return false
	var space := _root.get_world_2d().direct_space_state if _root else null
	if space == null:
		return true
	var q := PhysicsRayQueryParameters2D.create(origin, point)
	q.collision_mask = OCCLUDER_MASK
	q.exclude = exclude
	q.hit_from_inside = false
	var hit := space.intersect_ray(q)
	return hit.is_empty()


func _clear_visuals() -> void:
	for v in _visuals:
		if is_instance_valid(v):
			v.queue_free()
	_visuals.clear()
