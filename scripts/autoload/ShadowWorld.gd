extends Node
## Lantern washes + burn cover share one occlusion model:
## registered ShadowOccluders (geometry) AND physics layers world|boxes|light_block.
## Rebuild is throttled and caches polygons — moving platforms must not nuke FPS.


signal shadows_rebuilt

## Enough rays for a smooth rim; corner angles still catch hard edges.
const RAY_COUNT := 48
const CORNER_EPS := 0.003
const ANGLE_MERGE := 0.006
## Cap umbra casters per light (nearest first).
const UMBRA_MAX_PER_LIGHT := 8
## Max full rebuilds per second while dirty (moving platforms keep dirty=true).
const REBUILD_HZ := 12.0
## Skip lights / occluders far from the camera.
const CULL_MARGIN := 420.0
## Contact-hardening: hard umbra ends here; soft penumbra continues past.
const UMBRA_CONTACT_T := 0.36
## Matches LightSource intensity clamp. At max: fill 50% opaque, outline 100%.
const INTENSITY_MAX := 3.0
const FILL_ALPHA_AT_MAX := 0.5
const OUTLINE_ALPHA_AT_MAX := 1.0
## world(1) + boxes(8) + light-only(128)
const OCCLUDER_MASK := 1 | 8 | 128

var _wash_add_mat: CanvasItemMaterial = null

var lights: Array = []
var occluders: Array = []
var _root: Node2D = null
var _dirty: bool = true
var _visuals: Array = []
var _pool_poly: Array = []
var _pool_line: Array = []
var _pool_fan: Array = []
var _rebuild_cooldown: float = 0.0
## Per-rebuild cache: [{occ, poly, aabb, edges, gameplay, cast_umbra}]
var _occ_cache: Array = []


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
	_rebuild_cooldown = 0.0


func _physics_process(delta: float) -> void:
	_rebuild_cooldown = maxf(0.0, _rebuild_cooldown - delta)
	for light in lights:
		if is_instance_valid(light) and light.has_method("did_move") and light.did_move():
			_dirty = true
	for occ in occluders:
		if is_instance_valid(occ) and occ.has_method("did_move") and occ.did_move():
			_dirty = true
	if _dirty and _rebuild_cooldown <= 0.0:
		rebuild()
		_rebuild_cooldown = 1.0 / REBUILD_HZ


func rebuild() -> void:
	_dirty = false
	_recycle_visuals()
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
	_build_occ_cache()

	var view := _view_rect()
	var space := world.direct_space_state
	for light in lights:
		if not light.has_method("is_on") or not light.is_on():
			continue
		if not _light_in_view(light, view):
			continue
		_draw_occluded_light(light, space, view)

	shadows_rebuilt.emit()


## True if solid cover sits between from→to (gameplay burns + wash rays).
func segment_occluded(from: Vector2, to: Vector2, exclude: Array = []) -> bool:
	if _geometry_segment_blocked(from, to):
		return true
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


func _view_rect() -> Rect2:
	## Approximate camera view in world space (with margin for wash radius).
	var vp := get_viewport()
	if vp == null:
		return Rect2(-99999, -99999, 200000, 200000)
	var canvas := vp.get_canvas_transform()
	var size := vp.get_visible_rect().size
	var tl := canvas.affine_inverse() * Vector2.ZERO
	var br := canvas.affine_inverse() * size
	var r := Rect2(tl, br - tl).abs()
	return r.grow(CULL_MARGIN)


func _light_in_view(light: Node, view: Rect2) -> bool:
	if not light.has_method("get_light_origin"):
		return true
	var origin: Vector2 = light.get_light_origin()
	var radius: float = light.get_radius() if light.has_method("get_radius") else 280.0
	return view.grow(radius).has_point(origin)


func _build_occ_cache() -> void:
	_occ_cache.clear()
	for occ in occluders:
		if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
			continue
		var poly: PackedVector2Array = occ.get_world_polygon()
		if poly.size() < 3:
			continue
		var aabb := _poly_aabb(poly)
		var gameplay := true
		if occ.has_method("blocks_gameplay_light"):
			gameplay = occ.blocks_gameplay_light()
		var is_slab := aabb.size.x > 400.0 and aabb.size.y < 80.0
		var is_huge := aabb.size.x > 520.0 or aabb.size.y > 520.0
		var edges: Array = []
		var n := poly.size()
		for i in n:
			edges.append([poly[i], poly[(i + 1) % n]])
		_occ_cache.append({
			"occ": occ,
			"poly": poly,
			"aabb": aabb,
			"edges": edges,
			"gameplay": gameplay,
			"cast_umbra": gameplay and not is_slab and not is_huge,
		})


func _geometry_segment_blocked(from: Vector2, to: Vector2) -> bool:
	## Prefer cache when fresh; fall back to live polys (burn queries mid-frame).
	var list: Array = _occ_cache if not _occ_cache.is_empty() else []
	if list.is_empty():
		for occ in occluders:
			if not is_instance_valid(occ) or not occ.has_method("get_world_polygon"):
				continue
			if occ.has_method("blocks_gameplay_light") and not occ.blocks_gameplay_light():
				continue
			var poly: PackedVector2Array = occ.get_world_polygon()
			if poly.size() < 3:
				continue
			if _seg_hits_poly(from, to, poly):
				return true
		return false
	for e in list:
		if not e.get("gameplay", true):
			continue
		if _seg_hits_poly(from, to, e["poly"]):
			return true
	return false


func _seg_hits_poly(from: Vector2, to: Vector2, poly: PackedVector2Array) -> bool:
	var aabb := _poly_aabb(poly)
	var huge := aabb.size.x > 600.0 or aabb.size.y > 600.0
	if not huge and Geometry2D.is_point_in_polygon(to, poly):
		if not Geometry2D.is_point_in_polygon(from, poly):
			return true
	## Broadphase: skip if segment AABB misses poly AABB.
	var seg := Rect2(from, Vector2.ZERO).expand(to)
	if not seg.intersects(aabb):
		return false
	var n := poly.size()
	for i in n:
		var hit: Variant = Geometry2D.segment_intersects_segment(from, to, poly[i], poly[(i + 1) % n])
		if hit is Vector2 and from.distance_to(hit as Vector2) > 3.0:
			return true
	return false


func _poly_aabb(poly: PackedVector2Array) -> Rect2:
	var aabb := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		aabb = aabb.expand(p)
	return aabb


func _collect_ray_angles(origin: Vector2, radius: float, view: Rect2) -> PackedFloat32Array:
	var angles: Array = []
	for i in RAY_COUNT:
		angles.append(TAU * float(i) / float(RAY_COUNT))

	var r2 := radius * radius * 1.25
	var light_aabb := Rect2(origin, Vector2.ZERO).grow(radius)
	if not light_aabb.intersects(view):
		return PackedFloat32Array(angles)

	for e in _occ_cache:
		## Match burn occlusion — decorative BG occluders must not reshape the AoE.
		if not e.get("gameplay", true):
			continue
		var aabb: Rect2 = e["aabb"]
		if aabb.size.x > 600.0 or aabb.size.y > 600.0:
			continue
		if not light_aabb.intersects(aabb):
			continue
		var poly: PackedVector2Array = e["poly"]
		for p in poly:
			if origin.distance_squared_to(p) > r2:
				continue
			var a := (p - origin).angle()
			angles.append(a)
			angles.append(a - CORNER_EPS)
			angles.append(a + CORNER_EPS)

	angles.sort()
	var out := PackedFloat32Array()
	var last := -999.0
	for a in angles:
		var ang: float = fposmod(float(a), TAU)
		if out.is_empty() or absf(ang - last) > ANGLE_MERGE:
			out.append(ang)
			last = ang
	return out


func _cast_ray(space: PhysicsDirectSpaceState2D, origin: Vector2, dir: Vector2, radius: float, exclude: Array) -> Vector2:
	var to := origin + dir * radius
	var best := to
	var best_dist := radius
	var start := origin + dir * 1.5
	var ray_aabb := Rect2(start, Vector2.ZERO).expand(to)

	## Geometry against gameplay occluders only (same set as burns).
	for e in _occ_cache:
		if not e.get("gameplay", true):
			continue
		var aabb: Rect2 = e["aabb"]
		if not ray_aabb.intersects(aabb):
			continue
		for edge in e["edges"]:
			var hit: Variant = Geometry2D.segment_intersects_segment(start, to, edge[0], edge[1])
			if hit is Vector2:
				var d := origin.distance_to(hit as Vector2)
				if d > 2.0 and d < best_dist:
					best_dist = d
					best = hit as Vector2

	## Physics backup (floors / crates / light-only).
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
	## Tiny pullback so the rim sits just outside solid faces (avoids z-fighting).
	return best - dir * 0.35


func _intensity_t(intensity: float) -> float:
	## 0..1 linear over the editor intensity range (max → full opacity budget).
	return clampf(intensity, 0.0, INTENSITY_MAX) / INTENSITY_MAX


func _wash_add_material() -> CanvasItemMaterial:
	## Additive so overlapping lamps sum visually (stronger fill where they meet).
	if _wash_add_mat == null:
		_wash_add_mat = CanvasItemMaterial.new()
		_wash_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _wash_add_mat


func _draw_occluded_light(light: Node, space: PhysicsDirectSpaceState2D, view: Rect2) -> void:
	var origin: Vector2 = light.get_light_origin()
	var radius: float = maxf(light.get_radius(), 8.0)
	var kind: int = light.get_light_kind()
	var intensity: float = 1.0
	if light.has_method("get_intensity"):
		intensity = clampf(float(light.get_intensity()), 0.0, INTENSITY_MAX)
	var t := _intensity_t(intensity)
	var fill_a := FILL_ALPHA_AT_MAX * t
	var outline_a := OUTLINE_ALPHA_AT_MAX * t

	## One yellow/gold wash (no red soft shell). Additive so overlaps still stack.
	var rgb := Color(1.0, 0.86, 0.38)
	match kind:
		GameState.LightKind.MOON:
			rgb = Color(0.7, 0.88, 1.0)
		GameState.LightKind.CRIMSON:
			rgb = Color(0.95, 0.35, 0.38)
		GameState.LightKind.SUNSHAFT:
			rgb = Color(1.0, 1.0, 0.9)
		GameState.LightKind.CANDLE:
			rgb = Color(1.0, 0.84, 0.42)

	var exclude: Array = []
	if light.has_method("get_exclude_rids"):
		exclude = light.get_exclude_rids()

	var angles := _collect_ray_angles(origin, radius, view)
	var pts := PackedVector2Array()
	for i in angles.size():
		var dir := Vector2.from_angle(angles[i])
		pts.append(_cast_ray(space, origin, dir, radius, exclude))

	if pts.size() < 3:
		pts = PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			pts.append(origin + Vector2.from_angle(a) * mini(radius, 64.0))

	## z −3: above floors (−4), below houses (−1) so facades are not painted over.
	_add_wash_fan(origin, pts, Color(rgb.r, rgb.g, rgb.b, fill_a), -3, true)

	var ring := _take_line()
	ring.width = 2.6
	ring.default_color = Color(rgb.r, rgb.g, rgb.b, outline_a)
	ring.z_index = -3
	ring.material = null
	ring.clear_points()
	for p in pts:
		ring.add_point(p)
	if pts.size() > 0:
		ring.add_point(pts[0])
	_root.add_child(ring)
	_visuals.append(ring)

	_draw_umbrae_for_light(light, origin, radius, space, exclude)


func _draw_umbrae_for_light(
	light: Node,
	light_pos: Vector2,
	radius: float,
	space: PhysicsDirectSpaceState2D,
	exclude: Array
) -> void:
	## Rank nearby umbra casters by distance — skip the rest.
	var candidates: Array = []
	var r2 := radius * radius * 1.3
	for e in _occ_cache:
		if not e.get("cast_umbra", false):
			continue
		var aabb: Rect2 = e["aabb"]
		var c := aabb.get_center()
		var d2 := light_pos.distance_squared_to(c)
		if d2 > r2 and not aabb.grow(radius * 0.15).has_point(light_pos):
			## Still allow if any corner is near.
			var near := false
			for p in e["poly"]:
				if light_pos.distance_squared_to(p) <= r2:
					near = true
					break
			if not near:
				continue
		candidates.append({"e": e, "d2": d2})
	candidates.sort_custom(func(a, b): return a["d2"] < b["d2"])
	if candidates.size() > UMBRA_MAX_PER_LIGHT:
		candidates = candidates.slice(0, UMBRA_MAX_PER_LIGHT)

	var max_len: float = light.get_shadow_length() if light.has_method("get_shadow_length") else radius
	max_len = mini(max_len, radius * 0.95)
	## Soft ink only — loud umbra wedges read as purple “glitches” behind washes.
	var ink_a := 0.16
	if light.has_method("get_intensity"):
		ink_a = clampf(0.1 + float(light.get_intensity()) * 0.04, 0.1, 0.22)

	for c in candidates:
		_draw_umbra_wedge(c["e"], light_pos, max_len, ink_a, space, exclude)


func _add_wash_fan(
	origin: Vector2,
	rim: PackedVector2Array,
	color: Color,
	z: int,
	additive: bool = false
) -> void:
	if rim.size() < 2 or color.a < 0.01:
		return
	var fan := _take_fan()
	fan.z_index = z
	fan.material = _wash_add_material() if additive else null
	fan.set_fan(origin, rim, color)
	_root.add_child(fan)
	_visuals.append(fan)


func _take_fan() -> LightWashFan:
	while not _pool_fan.is_empty():
		var n: Node = _pool_fan.pop_back()
		if is_instance_valid(n) and n is LightWashFan:
			var f := n as LightWashFan
			f.visible = true
			return f
	return LightWashFan.new()


func _clip_shadow_extent(
	space: PhysicsDirectSpaceState2D,
	from: Vector2,
	dir: Vector2,
	max_len: float,
	exclude: Array
) -> Vector2:
	## Physics-only clip — floors/walls/crates already on OCCLUDER_MASK. Avoids O(n²) edge tests.
	var dir_n := dir.normalized()
	if dir_n.length_squared() < 0.0001:
		return from
	var start := from + dir_n * 1.25
	var to := from + dir_n * max_len
	var q := PhysicsRayQueryParameters2D.create(start, to)
	q.collision_mask = OCCLUDER_MASK
	q.hit_from_inside = true
	q.exclude = exclude
	var ph := space.intersect_ray(q)
	if ph.is_empty():
		return to
	var d := from.distance_to(ph.position as Vector2)
	return from + dir_n * maxf(d - 0.8, 0.0)


func _add_ink_poly(pts: PackedVector2Array, alpha: float, z: int = -4) -> void:
	if pts.size() < 3 or alpha < 0.02:
		return
	var ink := _take_poly()
	ink.color = Color(0.03, 0.015, 0.06, clampf(alpha, 0.0, 0.35))
	ink.z_index = z
	ink.polygon = pts
	_root.add_child(ink)
	_visuals.append(ink)


func _draw_umbra_wedge(
	entry: Dictionary,
	light_pos: Vector2,
	max_len: float,
	ink_a: float,
	space: PhysicsDirectSpaceState2D,
	exclude: Array
) -> void:
	## Real shadows: sharp + dark at contact, softer/fainter with distance (penumbra).
	## Uses the same two physics clips per edge — no extra raycasts.
	var poly: PackedVector2Array = entry["poly"]
	var n := poly.size()
	var aabb: Rect2 = entry["aabb"]
	if aabb.get_area() < 280.0:
		return
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
		var far_a := _clip_shadow_extent(space, a, da, max_len, exclude)
		var far_b := _clip_shadow_extent(space, b, db, max_len, exclude)
		var len_a := far_a.distance_to(a)
		var len_b := far_b.distance_to(b)
		if len_a < 4.0 and len_b < 4.0:
			continue
		if far_a.distance_to(light_pos) < mid.distance_to(light_pos) - 2.0:
			continue
		if far_b.distance_to(light_pos) < mid.distance_to(light_pos) - 2.0:
			continue

		## Farther from the lamp → thinner ink (inverse-ish falloff).
		var dist_fade := clampf(1.15 - mid.distance_to(light_pos) / maxf(max_len, 1.0), 0.4, 1.0)
		var base_a := ink_a * dist_fade

		## Contact hardening: hard umbra near the occluder…
		var ca := a.lerp(far_a, UMBRA_CONTACT_T)
		var cb := b.lerp(far_b, UMBRA_CONTACT_T)
		_add_ink_poly(PackedVector2Array([a, b, cb, ca]), base_a * 0.85, -4)

		## …then a softer, slightly wider penumbra that grows with cast length.
		var cast_len := (len_a + len_b) * 0.5
		var spread := clampf(cast_len * 0.045, 2.0, 16.0)
		var side := far_a - far_b
		if side.length_squared() < 1.0:
			side = edge_dir
		else:
			side = side.normalized()
		var pa := far_a + side * spread
		var pb := far_b - side * spread
		_add_ink_poly(PackedVector2Array([ca, cb, pb, pa]), base_a * 0.22, -4)


func _take_poly() -> Polygon2D:
	while not _pool_poly.is_empty():
		var n: Node = _pool_poly.pop_back()
		if is_instance_valid(n) and n is Polygon2D:
			var p := n as Polygon2D
			p.visible = true
			return p
	return Polygon2D.new()


func _take_line() -> Line2D:
	while not _pool_line.is_empty():
		var n: Node = _pool_line.pop_back()
		if is_instance_valid(n) and n is Line2D:
			var l := n as Line2D
			l.visible = true
			return l
	return Line2D.new()


func _recycle_visuals() -> void:
	for v in _visuals:
		if not is_instance_valid(v):
			continue
		var parent: Node = v.get_parent()
		if parent:
			parent.remove_child(v)
		v.visible = false
		if v is LightWashFan:
			if _pool_fan.size() < 48:
				_pool_fan.append(v)
			else:
				v.queue_free()
		elif v is Polygon2D:
			(v as Polygon2D).polygon = PackedVector2Array()
			if _pool_poly.size() < 120:
				_pool_poly.append(v)
			else:
				v.queue_free()
		elif v is Line2D:
			(v as Line2D).clear_points()
			if _pool_line.size() < 40:
				_pool_line.append(v)
			else:
				v.queue_free()
		else:
			v.queue_free()
	_visuals.clear()


func _clear_visuals() -> void:
	for v in _visuals:
		if is_instance_valid(v):
			v.queue_free()
	_visuals.clear()
	for v in _pool_poly:
		if is_instance_valid(v):
			v.queue_free()
	_pool_poly.clear()
	for v in _pool_line:
		if is_instance_valid(v):
			v.queue_free()
	_pool_line.clear()
	for v in _pool_fan:
		if is_instance_valid(v):
			v.queue_free()
	_pool_fan.clear()
	_occ_cache.clear()
