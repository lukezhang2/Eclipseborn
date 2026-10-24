extends AnimatableBody2D
class_name PushableBox
## Moveable crate that occludes light. Clamped so it cannot leave the map.

@export var box_size: Vector2 = Vector2(48, 48)
@export var push_speed: float = 110.0

var _occluder: ShadowOccluder
var _visual: Polygon2D
var _shake_time: float = 0.0

## Always moveable — immoveable crates were removed.


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4
	_build()
	add_to_group("boxes")


func _physics_process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		_visual.position.x = sin(_shake_time * 60.0) * 3.0
		if _shake_time <= 0.0:
			_visual.position = Vector2.ZERO


func _build() -> void:
	var half := box_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)
	_visual = Polygon2D.new()
	_visual.polygon = poly
	_visual.color = Color(0.42, 0.32, 0.22)
	add_child(_visual)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.05, 0.02, 0.08, 0.95)
	for p in poly:
		edge.add_point(p)
	edge.add_point(poly[0])
	add_child(edge)
	_occluder = ShadowOccluder.new()
	_occluder.local_polygon = poly
	add_child(_occluder)


func _clamp_x() -> void:
	position.x = clampf(position.x, GameState.map_min_x + box_size.x * 0.5, GameState.map_max_x - box_size.x * 0.5)


func try_push(from_global: Vector2, direction: float, delta: float) -> String:
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 0.75:
		return ""
	position.x += direction * push_speed * delta
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "push"


func try_pull(from_global: Vector2, pull_direction: float, delta: float) -> String:
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 0.9:
		return ""
	if absf(from_global.x - my_center.x) > box_size.x * 0.5 + 36.0:
		return ""
	position.x += pull_direction * push_speed * 0.95 * delta
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "pull"
