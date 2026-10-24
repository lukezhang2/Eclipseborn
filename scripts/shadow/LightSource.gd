extends Node2D
class_name LightSource
## Lantern / lamp. Always draws a visible circumference; shadow fan excludes own body.


@export var light_kind: GameState.LightKind = GameState.LightKind.HEARTH
@export var radius: float = 280.0
@export var shadow_length: float = 320.0
@export var is_enabled: bool = true
@export var pushable: bool = true
@export var push_speed: float = 90.0
@export var show_radius_ring: bool = true

var _last_pos: Vector2 = Vector2.ZERO
var _visual: Node2D
var _glass: Polygon2D
var _ring: Line2D
var _burn_shape: CircleShape2D
var _body: AnimatableBody2D
var _exclude_rids: Array = []


func _ready() -> void:
	_last_pos = global_position
	_build_visual()
	ShadowWorld.register_light(self)
	add_to_group("lights")
	if pushable:
		add_to_group("pushable_lamps")
	call_deferred("_cache_exclude_rids")
	ShadowWorld.mark_dirty()


func _exit_tree() -> void:
	ShadowWorld.unregister_light(self)


func _cache_exclude_rids() -> void:
	_exclude_rids.clear()
	if _body:
		_exclude_rids.append(_body.get_rid())
		for c in _body.get_children():
			if c is CollisionPolygon2D or c is CollisionShape2D:
				_exclude_rids.append(c.get_rid())


func did_move() -> bool:
	if global_position.distance_squared_to(_last_pos) > 0.25:
		_last_pos = global_position
		return true
	return false


func is_on() -> bool:
	return is_enabled


func set_on(value: bool) -> void:
	is_enabled = value
	if _glass:
		_glass.modulate.a = 1.0 if value else 0.35
	if _ring:
		_ring.visible = value and show_radius_ring
	ShadowWorld.mark_dirty()


func set_radius(value: float) -> void:
	radius = clampf(value, 40.0, 900.0)
	shadow_length = maxf(shadow_length, radius)
	if _burn_shape:
		_burn_shape.radius = radius
	_rebuild_ring()
	ShadowWorld.mark_dirty()


func get_light_origin() -> Vector2:
	# Cast from the glass, not the collider interior.
	return global_position + Vector2(0, -8)


func get_exclude_rids() -> Array:
	return _exclude_rids


func get_shadow_length() -> float:
	return shadow_length


func get_light_kind() -> int:
	return light_kind


func get_radius() -> float:
	return radius


func burns() -> bool:
	return light_kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]


func is_safe() -> bool:
	return light_kind in [GameState.LightKind.MOON, GameState.LightKind.CRIMSON]


func color_for_kind() -> Color:
	match light_kind:
		GameState.LightKind.HEARTH:
			return Color(1.0, 0.78, 0.35, 1.0)
		GameState.LightKind.CANDLE:
			return Color(1.0, 0.7, 0.4, 1.0)
		GameState.LightKind.MOON:
			return Color(0.7, 0.85, 1.0, 1.0)
		GameState.LightKind.CRIMSON:
			return Color(0.95, 0.2, 0.25, 1.0)
		GameState.LightKind.SUNSHAFT:
			return Color(1.0, 1.0, 0.95, 1.0)
	return Color.WHITE


func _build_visual() -> void:
	_visual = Node2D.new()
	add_child(_visual)

	var lamp := Polygon2D.new()
	lamp.polygon = PackedVector2Array([
		Vector2(-10, -18), Vector2(10, -18), Vector2(14, 10), Vector2(-14, 10)
	])
	lamp.color = Color(0.35, 0.32, 0.28)
	_visual.add_child(lamp)

	_glass = Polygon2D.new()
	_glass.polygon = PackedVector2Array([
		Vector2(-7, -14), Vector2(7, -14), Vector2(6, 4), Vector2(-6, 4)
	])
	_glass.color = color_for_kind()
	_visual.add_child(_glass)

	## Debug/editor ring only — gameplay wash outline comes from ShadowWorld (behind props).
	_ring = Line2D.new()
	_ring.width = 1.5
	_ring.default_color = Color(color_for_kind().r, color_for_kind().g, color_for_kind().b, 0.35)
	_ring.z_index = -13
	_visual.add_child(_ring)
	_rebuild_ring()
	## Hide the un-occluded full circle in normal play so it doesn't paint over houses.
	if not Engine.is_editor_hint():
		_ring.visible = false
		show_radius_ring = false

	var area := Area2D.new()
	area.collision_layer = 64
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	_burn_shape = CircleShape2D.new()
	_burn_shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = _burn_shape
	cs.position = Vector2(0, -8)
	area.add_child(cs)
	area.name = "BurnArea"
	area.set_meta("light_kind", light_kind)
	area.set_meta("light_source", self)
	add_child(area)

	if pushable:
		## Layer 16 = pushable lamps only. NOT in ShadowWorld occluder mask (1|8),
		## so invisible lamp bodies stop casting "ghost" light cutouts.
		_body = AnimatableBody2D.new()
		_body.collision_layer = 16
		_body.collision_mask = 1
		_body.name = "LampBody"
		var bpoly := CollisionPolygon2D.new()
		bpoly.polygon = PackedVector2Array([
			Vector2(-12, -18), Vector2(12, -18), Vector2(14, 12), Vector2(-14, 12)
		])
		_body.add_child(bpoly)
		add_child(_body)


func _rebuild_ring() -> void:
	if _ring == null:
		return
	_ring.clear_points()
	var col := color_for_kind()
	_ring.default_color = Color(col.r, col.g, col.b, 0.55)
	for i in 48:
		var a := TAU * float(i) / 48.0
		_ring.add_point(Vector2(cos(a), sin(a)) * radius + Vector2(0, -8))
	_ring.add_point(_ring.get_point_position(0))
	## Gameplay uses ShadowWorld's occluded outline; this ring is opt-in debug only.
	_ring.visible = is_enabled and show_radius_ring


func try_push(direction: float, delta: float) -> void:
	if not pushable:
		return
	position.x += direction * push_speed * delta
	position.x = clampf(position.x, GameState.map_min_x + 20.0, GameState.map_max_x - 20.0)
	ShadowWorld.mark_dirty()
