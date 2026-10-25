extends Node
## Lantern washes + burn cover share one occlusion model:
## registered ShadowOccluders (geometry) AND physics layers world|boxes|light_block.


signal shadows_rebuilt

const RAY_COUNT := 96
const CORNER_EPS := 0.003
## world(1) + boxes(8) + light-only(128)
const OCCLUDER_MASK := 1 | 8 | 128

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


## True if solid cover sits between from→to (gameplay burns + wash rays).
func segment_occluded(from: Vector2, to: Vector2, exclude: Array = []) -> bool:
	## Geometry first — same polygons that paint umbra / hard cuts.
	if _geometry_segment_blocked(from, to):
		return true
	## Physics backup (floors, crates, light-only StaticBodies).
	if _root == null or not is_instance_valid(_root):
		return false
	var world := _root.get_world_2d()
	if world == null:
		return false
	var space := world.direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = OCCLUDER_MASK
	q.exclude = exclude
	q.hit_from_inside = true
	var hit := space.intersect_ray(q)
	return not hit.is_empty()


func is_point_in_light(origin: Vector2, radius: float, point: Vector2, exclude: Array = []) -> bool:
	if point.distance_to(origin) > radius:
		return false
	return not segment_occluded(origin, point, exclude)


func _geometry_segment_blocked(from: Vector2, to: Vector2) -> bool:
	for occ in occluders:
		if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		## BG murals etc. — visual wash only; never grant free shade to the player.
		if occ.has_method("blocks_gameplay_light") and not occ.blocks_gameplay_light():
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		## Skip huge floor/ceiling slabs for "point behind facade" tests — still edge-test them.
		var aabb := _poly_aabb(poly)
		var huge := aabb.size.x > 600.0 or aabb.size.y > 600.0
		## Player (or probe) inside a non-huge occluder = covered (standing in house shade).
		if not huge and Geometry2D.is_point_in_polygon(to, poly):
			if not Geometry2D.is_point_in_polygon(from, poly):
				return true
		var n := poly.size()
		for i in n:
			var a := poly[i]
			var b := poly[(i + 1) % n]
			var hit: Variant = Geometry2D.segment_intersects_segment(from, to, a, b)
			## Ignore hits extremely close to the light origin (emitter inside a prop).
			if hit is Vector2 and from.distance_to(hit as Vector2) > 3.0:
				return true
	return false


func _poly_aabb(poly: PackedVector2Array) -> Rect2:
	var aabb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		aabb = aabb.expand(p)
	return aabb


func _collect_ray_angles(origin: Vector2, radius: float) -> Array:
	var angles: Array = []
	for i in RAY_COUNT:
		angles.append(TAU * float(i) / float(RAY_COUNT))

	var r2 := radius * radius * 1.4
	for occ in occluders:
		if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		var aabb := _poly_aabb(poly)
		if aabb.size.x > 600.0 or aabb.size.y > 600.0:
			continue
		for p in poly:
			if origin.distance_squared_to(p) > r2:
				continue
			var a := (p - origin).angle()
			angles.append(a)
			angles.append(a - CORNER_EPS)
			angles.append(a + CORNER_EPS)

	angles.sort()
	var unique: Array = []
	var last := -999.0
	for a in angles:
		var ang: float = fposmod(float(a), TAU)
		if unique.is_empty() or absf(ang - last) > 0.0004:
			unique.append(ang)
			last = ang
	if unique.size() >= 2 and absf(float(unique[0]) + TAU - float(unique[unique.size() - 1])) < 0.0005:
		unique.pop_back()
	return unique


func _cast_ray(space: PhysicsDirectSpaceState2D, origin: Vector2, dir: Vector2, radius: float, exclude: Array) -> Vector2:
	var to := origin + dir * radius
	var best := to
	var best_dist := radius

	## Geometry against every occluder edge / interior.
	for occ in occluders:
		if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		var n := poly.size()
		for i in n:
			var a := poly[i]
			var b := poly[(i + 1) % n]
			var hit: Variant = Geometry2D.segment_intersects_segment(origin + dir * 1.5, to, a, b)
			if hit is Vector2:
				var d := origin.distance_to(hit as Vector2)
				if d > 2.0 and d < best_dist:
					best_dist = d
					best = hit as Vector2

	## Physics backup.
	var q := PhysicsRayQueryParameters2D.create(origin + dir * 1.25, to)
	q.collision_mask = OCCLUDER_MASK
	q.hit_from_inside = true
	q.exclude = exclude
	var ph := space.intersect_ray(q)
	if not ph.is_empty():
		var hit_pos: Vector2 = ph.position
		var d := origin.distance_to(hit_pos)
		if d > 2.0 and d < best_dist:
			best_dist = d
			best = hit_pos

	if best_dist >= radius - 0.01:
		return to
	return best - dir * 0.6


func _draw_occluded_light(light: Node, space: PhysicsDirectSpaceState2D) -> void:
	var origin: Vector2 = light.get_light_origin()
	var radius: float = maxf(light.get_radius(), 8.0)
	var kind: int = light.get_light_kind()
	var intensity: float = 1.0
	if light.has_method("get_intensity"):
		intensity = clampf(float(light.get_intensity()), 0.15, 3.0)
	var burns := kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]
	var base_a := (0.34 if burns else 0.14) * intensity
	var core := Color(1.0, 0.72, 0.28, mini(0.72, base_a))
	match kind:
		GameState.LightKind.MOON:
			core = Color(0.65, 0.85, 1.0, mini(0.4, 0.16 * intensity))
		GameState.LightKind.CRIMSON:
			core = Color(0.95, 0.2, 0.25, mini(0.55, 0.28 * intensity))
		GameState.LightKind.SUNSHAFT:
			core = Color(1.0, 1.0, 0.85, mini(0.75, 0.38 * intensity))
		GameState.LightKind.CANDLE:
			core = Color(1.0, 0.7, 0.4, mini(0.65, 0.3 * intensity))

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
		for i in 48:
			var a := TAU * float(i) / 48.0
			pts.append(origin + Vector2.from_angle(a) * mini(radius, 64.0))

	var fill := Polygon2D.new()
	fill.color = core
	fill.z_index = -12
	fill.polygon = pts
	_root.add_child(fill)
	_visuals.append(fill)

	## Hotter core when intensity is high.
	if intensity > 1.05:
		var hot := Polygon2D.new()
		var hot_pts := PackedVector2Array([origin])
		var hot_r := radius * clampf(0.22 + (intensity - 1.0) * 0.12, 0.22, 0.45)
		for i in 24:
			var a := TAU * float(i) / 24.0
			hot_pts.append(_cast_ray(space, origin, Vector2.from_angle(a), hot_r, exclude))
		hot.color = Color(1.0, 0.92, 0.55, mini(0.55, 0.18 * (intensity - 0.5)))
		hot.z_index = -12
		hot.polygon = hot_pts
		_root.add_child(hot)
		_visuals.append(hot)

	var ring := Line2D.new()
	ring.width = 1.5 + intensity * 0.75
	ring.default_color = Color(core.r, core.g, core.b, mini(0.9, core.a + 0.25 + intensity * 0.08))
	ring.z_index = -11
	for i in range(1, pts.size()):
		ring.add_point(pts[i])
	if pts.size() > 1:
		ring.add_point(pts[1])
	_root.add_child(ring)
	_visuals.append(ring)

	for occ in occluders:
		_draw_umbra_wedge(light, occ, origin, radius, space, exclude)


func _clip_shadow_extent(
	space: PhysicsDirectSpaceState2D,
	from: Vector2,
	dir: Vector2,
	max_len: float,
	skip_occ: Node,
	exclude: Array
) -> Vector2:
	## Stop cast shadows at floors / walls / other props — never punch through solids.
	var dir_n := dir.normalized()
	if dir_n.length_squared() < 0.0001:
		return from
	var best_d := max_len
	var start := from + dir_n * 1.25
	var to := from + dir_n * max_len

	for occ in occluders:
		if occ == skip_occ or not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		var n := poly.size()
		for i in n:
			var a := poly[i]
			var b := poly[(i + 1) % n]
			var hit: Variant = Geometry2D.segment_intersects_segment(start, to, a, b)
			if hit is Vector2:
				var d := from.distance_to(hit as Vector2)
				if d > 2.0 and d < best_d:
					best_d = d

	var q := PhysicsRayQueryParameters2D.create(start, to)
	q.collision_mask = OCCLUDER_MASK
	q.hit_from_inside = true
	q.exclude = exclude
	var ph := space.intersect_ray(q)
	if not ph.is_empty():
		var d := from.distance_to(ph.position as Vector2)
		if d > 2.0 and d < best_d:
			best_d = d

	return from + dir_n * maxf(best_d - 0.8, 0.0)


func _draw_umbra_wedge(
	light: Node,
	occ: Node,
	light_pos: Vector2,
	radius: float,
	space: PhysicsDirectSpaceState2D,
	exclude: Array
) -> void:
	if not occ.has_method("get_world_polygon"):
		return
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var aabb := _poly_aabb(poly)
	## Floor/ceiling slabs receive shadows but do not cast endless umbra fans.
	var is_slab := aabb.size.x > 400.0 and aabb.size.y < 80.0
	var is_huge := aabb.size.x > 520.0 or aabb.size.y > 520.0
	if is_slab or is_huge:
		return
	var near := false
	for p in poly:
		if p.distance_to(light_pos) <= radius * 1.15:
			near = true
			break
	if not near:
		return
	var max_len: float = light.get_shadow_length() if light.has_method("get_shadow_length") else radius
	max_len = mini(max_len, radius * 0.95)
	var ink_a := 0.42
	if light.has_method("get_intensity"):
		ink_a = clampf(0.32 + float(light.get_intensity()) * 0.1, 0.32, 0.55)
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
		if normal.dot(to_mid.normalized()) <= 0.15:
			continue
		var da := (a - light_pos).normalized()
		var db := (b - light_pos).normalized()
		var far_a := _clip_shadow_extent(space, a, da, max_len, occ, exclude)
		var far_b := _clip_shadow_extent(space, b, db, max_len, occ, exclude)
		## Degenerate if both tips collapsed onto the edge.
		if far_a.distance_to(a) < 4.0 and far_b.distance_to(b) < 4.0:
			continue
		if far_a.distance_to(light_pos) < mid.distance_to(light_pos) - 2.0:
			continue
		if far_b.distance_to(light_pos) < mid.distance_to(light_pos) - 2.0:
			continue
		var ink := Polygon2D.new()
		ink.color = Color(0.04, 0.02, 0.07, ink_a)
		ink.z_index = -11
		ink.polygon = PackedVector2Array([a, b, far_b, far_a])
		_root.add_child(ink)
		_visuals.append(ink)


func _clear_visuals() -> void:
	for v in _visuals:
		if is_instance_valid(v):
			v.queue_free()
	_visuals.clear()
