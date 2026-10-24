extends Node2D
class_name LightSource
## A lamp / candle / moon shaft / crimson pane / sunshaft.

@export var light_kind: GameState.LightKind = GameState.LightKind.HEARTH
@export var radius: float = 420.0
@export var shadow_length: float = 520.0
@export var is_enabled: bool = true
@export var pushable: bool = true
@export var push_speed: float = 90.0

var _last_pos: Vector2 = Vector2.ZERO
var _visual: Node2D
var _point_light: PointLight2D


func _ready() -> void:
	_last_pos = global_position
	_build_visual()
	ShadowWorld.register_light(self)
	add_to_group("lights")
	add_to_group("pushable_lamps")


func _exit_tree() -> void:
	ShadowWorld.unregister_light(self)


func _physics_process(_delta: float) -> void:
	pass


func did_move() -> bool:
	if global_position.distance_squared_to(_last_pos) > 0.25:
		_last_pos = global_position
		return true
	return false


func is_on() -> bool:
	return is_enabled


func set_on(value: bool) -> void:
	is_enabled = value
	if _point_light:
		_point_light.enabled = value
	ShadowWorld.mark_dirty()


func get_light_origin() -> Vector2:
	return global_position


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

	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([
		Vector2(-7, -14), Vector2(7, -14), Vector2(6, 4), Vector2(-6, 4)
	])
	glass.color = color_for_kind()
	_visual.add_child(glass)

	_point_light = PointLight2D.new()
	_point_light.color = color_for_kind()
	_point_light.energy = 1.2
	_point_light.texture_scale = radius / 128.0
	_point_light.texture = _make_light_texture()
	_point_light.enabled = is_enabled
	add_child(_point_light)

	# Sensor area so the player can detect exposure.
	var area := Area2D.new()
	area.collision_layer = 64  # light_sensor
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	area.add_child(cs)
	area.name = "BurnArea"
	area.set_meta("light_kind", light_kind)
	area.set_meta("light_source", self)
	add_child(area)

	# Physics body so the spirit can walk into the lamp and slide it.
	if pushable:
		var body := AnimatableBody2D.new()
		body.collision_layer = 8
		body.collision_mask = 1
		body.name = "LampBody"
		var bpoly := CollisionPolygon2D.new()
		bpoly.polygon = PackedVector2Array([
			Vector2(-12, -18), Vector2(12, -18), Vector2(14, 12), Vector2(-14, 12)
		])
		body.add_child(bpoly)
		add_child(body)


func _make_light_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	for y in 128:
		for x in 128:
			var d := Vector2(x, y).distance_to(center) / 64.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func try_push(direction: float, delta: float) -> void:
	if not pushable:
		return
	position.x += direction * push_speed * delta
	ShadowWorld.mark_dirty()
