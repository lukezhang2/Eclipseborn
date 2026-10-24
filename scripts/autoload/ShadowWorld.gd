extends Node
## Builds walkable / wall shadow collision from lights + occluders every frame when dirty.

const PhysicsLayers := {
	"WORLD": 1,
	"PLAYER": 2,
	"SHADOW": 4,
	"BOXES": 8,
}

signal shadows_rebuilt

var lights: Array = []
var occluders: Array = []
var _root: Node2D = null
var _dirty: bool = true
var _bodies: Array = []


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
	_clear_bodies()
	_root = root
	_dirty = true


func _physics_process(_delta: float) -> void:
	# Rebuild when anything moved, or periodically while lamps/boxes slide.
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
	_clear_bodies()
	if _root == null or not is_instance_valid(_root):
		return

	# Drop invalid refs.
	lights = lights.filter(func(n): return is_instance_valid(n))
	occluders = occluders.filter(func(n): return is_instance_valid(n))

	for light in lights:
		if not light.is_on():
			continue
		for occ in occluders:
			_build_shadow_for(light, occ)

	shadows_rebuilt.emit()


func _clear_bodies() -> void:
	for b in _bodies:
		if is_instance_valid(b):
			b.queue_free()
	_bodies.clear()


func _build_shadow_for(light: Node, occ: Node) -> void:
	var poly: PackedVector2Array = occ.get_world_polygon()
	if poly.size() < 3:
		return
	var light_pos: Vector2 = light.get_light_origin()
	var max_len: float = light.get_shadow_length()
	var kind: int = light.get_light_kind()

	# Crimson: solid wall from silhouette, not a floor.
	# Others: floor/bridge slab under the extruded umbra.
	var silhouette := _silhouette_edges(poly, light_pos)
	if silhouette.is_empty():
		return

	var shadow_poly := PackedVector2Array()
	for edge in silhouette:
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		var da := (a - light_pos).normalized() * max_len
		var db := (b - light_pos).normalized() * max_len
		# Quad: a, b, b+db, a+da
		var quad := PackedVector2Array([a, b, b + db, a + da])
		if kind == GameState.LightKind.CRIMSON:
			_add_collision_polygon(quad, true)
		else:
			# Walkable top: take the farthest horizontal strip as a platform thickness.
			_add_floor_from_quad(quad, light_pos)

	# Also paint a visual ink polygon for non-crimson shadows.
	if kind != GameState.LightKind.CRIMSON:
		for edge in silhouette:
			var a: Vector2 = edge[0]
			var b: Vector2 = edge[1]
			var da := (a - light_pos).normalized() * max_len
			var db := (b - light_pos).normalized() * max_len
			_add_visual_ink(PackedVector2Array([a, b, b + db, a + da]))


func _silhouette_edges(poly: PackedVector2Array, light_pos: Vector2) -> Array:
	var edges: Array = []
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var mid := (a + b) * 0.5
		var edge_dir := (b - a).normalized()
		var normal := Vector2(-edge_dir.y, edge_dir.x)
		# Face away from light = silhouette.
		if normal.dot((mid - light_pos).normalized()) > 0.0:
			edges.append([a, b])
	return edges


func _add_floor_from_quad(quad: PackedVector2Array, light_pos: Vector2) -> void:
	# Build a thin walkable ledge along the top of the shadow region (lowest Y? or farthest from light).
	# For side-view: use the two points farthest from the light as the outer edge, thicken upward into a platform.
	var pts := Array(quad)
	pts.sort_custom(func(a, b): return a.distance_squared_to(light_pos) > b.distance_squared_to(light_pos))
	if pts.size() < 2:
		return
	var p0: Vector2 = pts[0]
	var p1: Vector2 = pts[1]
	# Prefer nearly-horizontal platforms.
	if absf(p0.y - p1.y) > absf(p0.x - p1.x) * 2.0:
		# Vertical-ish shadow: treat as wall (non-crimson already handled separately).
		# Still add a short foothold at the bottom-most of the two far points.
		var left := p0 if p0.x < p1.x else p1
		var right := p1 if p0.x < p1.x else p0
		var y := maxf(left.y, right.y)
		var floor_poly := PackedVector2Array([
			Vector2(left.x, y - 10.0),
			Vector2(right.x, y - 10.0),
			Vector2(right.x, y + 6.0),
			Vector2(left.x, y + 6.0),
		])
		_add_collision_polygon(floor_poly, false)
		return

	var left := p0 if p0.x < p1.x else p1
	var right := p1 if p0.x < p1.x else p0
	var avg_y := (left.y + right.y) * 0.5
	var thickness := 14.0
	var floor_poly := PackedVector2Array([
		Vector2(left.x, avg_y - thickness),
		Vector2(right.x, avg_y - thickness),
		Vector2(right.x, avg_y + 4.0),
		Vector2(left.x, avg_y + 4.0),
	])
	_add_collision_polygon(floor_poly, false)


func _add_collision_polygon(poly: PackedVector2Array, is_wall: bool) -> void:
	if poly.size() < 3 or _root == null:
		return
	var body := StaticBody2D.new()
	body.collision_layer = PhysicsLayers.SHADOW
	body.collision_mask = 0
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	body.add_child(cs)
	if is_wall:
		body.set_meta("shadow_wall", true)
	_root.add_child(body)
	_bodies.append(body)


func _add_visual_ink(poly: PackedVector2Array) -> void:
	if _root == null or poly.size() < 3:
		return
	var poly_node := Polygon2D.new()
	poly_node.polygon = poly
	poly_node.color = Color(0.12, 0.08, 0.18, 0.55)
	# Faint purple edge via modulate; actual outline drawn with Line2D.
	_root.add_child(poly_node)
	_bodies.append(poly_node)  # tracked for cleanup (Node, not only StaticBody2D)
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.45, 0.25, 0.65, 0.7)
	for p in poly:
		line.add_point(p)
	if poly.size() > 0:
		line.add_point(poly[0])
	_root.add_child(line)
	_bodies.append(line)
