extends Node
## Hard-cut lantern washes. Corner-aware rays so silhouettes stay closed (no random pie gaps).


signal shadows_rebuilt

const RAY_COUNT := 96
const CORNER_EPS := 0.0015 ## radians — rays just past each occluder vertex
## 1 = world, 8 = crates, 128 = LightOnlyBlocker — never player-collidable.
const OCCLUDER_MASK := 1 | 8 | 128 ## keep in sync with PieceSpecs.LIGHT_BLOCK_PHYSICS_LAYER

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


func _collect_ray_angles(origin: Vector2, radius: float) -> Array:
	## Uniform fan + rays aimed at nearby occluder corners (and epsilon offsets).
	var angles: Array = []
	for i in RAY_COUNT:
		angles.append(TAU * float(i) / float(RAY_COUNT))

	var r2 := radius * radius * 1.21
	for occ in occluders:
		if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		## Skip huge floors/walls — they only need the uniform fan.
		var aabb := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			aabb = aabb.expand(p)
		if aabb.size.x > 400.0 or aabb.size.y > 400.0:
			continue
		for p in poly:
			if origin.distance_squared_to(p) > r2:
				continue
			var a := (p - origin).angle()
			angles.append(a)
			angles.append(a - CORNER_EPS)
			angles.append(a + CORNER_EPS)

	angles.sort()
	## Deduplicate near-identical angles.
	var unique: Array = []
	var last := -999.0
	for a in angles:
		var ang: float = fposmod(float(a), TAU)
		if unique.is_empty() or absf(ang - last) > 0.0004:
			unique.append(ang)
			last = ang
	if unique.size() >= 2 and absf(float(unique[0]) + TAU - float(unique[unique.size() - 1])) < 0.0004:
		unique.pop_back()
	return unique


func _cast_ray(space: PhysicsDirectSpaceState2D, origin: Vector2, dir: Vector2, radius: float, exclude: Array) -> Vector2:
	## dir must be normalized.
	var from := origin + dir * 1.5
	var to := origin + dir * radius
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = OCCLUDER_MASK
	q.hit_from_inside = false
	q.exclude = exclude
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return to
	var hit_pos: Vector2 = hit.position
	var dist := origin.distance_to(hit_pos)
	if dist < 2.0:
		## Almost inside geometry — tiny stub, not a hole to the far radius.
		return origin + dir * 2.0
	return hit_pos - dir * 0.5


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

	var angles := _collect_ray_angles(origin, radius)
	var pts := PackedVector2Array()
	pts.append(origin)
	for a in angles:
		var dir := Vector2.from_angle(float(a))
		pts.append(_cast_ray(space, origin, dir, radius, exclude))

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
	## Soft shadow behind small occluders. Ray fan already hard-cuts the wash.
	if not occ.has_method("get_world_polygon"):
		return
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var aabb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		aabb = aabb.expand(p)
	if aabb.size.x > 220.0 or aabb.size.y > 220.0:
		return
	var near := false
	for p in poly:
		if p.distance_to(light_pos) <= radius * 1.05:
			near = true
			break
	if not near:
		return
	var max_len: float = light.get_shadow_length() if light.has_method("get_shadow_length") else radius
	max_len = mini(max_len, radius * 0.95)
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var mid := (a + b) * 0.5
		var to_mid := mid - light_pos
		if to_mid.length_squared() < 4.0:
			continue
		var edge_dir := (b - a).normalized()
		var normal := Vector2(-edge_dir.y, edge_dir.x)
		## Only faces pointing away from the light (back side).
		if normal.dot(to_mid.normalized()) <= 0.35:
			continue
		var da := (a - light_pos).normalized() * max_len
		var db := (b - light_pos).normalized() * max_len
		var far_a := a + da
		var far_b := b + db
		## Reject wedges that fold back toward the lamp (gap artifacts).
		if far_a.distance_to(light_pos) < mid.distance_to(light_pos):
			continue
		if far_b.distance_to(light_pos) < mid.distance_to(light_pos):
			continue
		var ink := Polygon2D.new()
		ink.color = Color(0.04, 0.02, 0.07, 0.32)
		ink.z_index = -11
		ink.polygon = PackedVector2Array([a, b, far_b, far_a])
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
