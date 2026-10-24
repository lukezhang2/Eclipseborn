extends AnimatableBody2D
class_name PushableBox
## Moveable or immoveable crate that occludes light.

@export var moveable: bool = true
@export var box_size: Vector2 = Vector2(48, 48)
@export var push_speed: float = 110.0

var _occluder: ShadowOccluder
var _visual: Polygon2D
var _shake_time: float = 0.0
var _base_pos: Vector2


func _ready() -> void:
	collision_layer = 8  # boxes
	collision_mask = 1 | 4  # world + shadow ground
	_build()
	_base_pos = position
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
	if moveable:
		_visual.color = Color(0.42, 0.32, 0.22)  # wood
	else:
		_visual.color = Color(0.35, 0.38, 0.42)  # riveted iron
	add_child(_visual)

	# Rivets / edge
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.15, 0.12, 0.1, 0.9)
	for p in poly:
		edge.add_point(p)
	edge.add_point(poly[0])
	add_child(edge)

	_occluder = ShadowOccluder.new()
	_occluder.local_polygon = poly
	add_child(_occluder)


func try_push(from_global: Vector2, direction: float, delta: float) -> String:
	## Returns "push", "bump", or "".
	if not moveable:
		_shake_time = 0.18
		return "bump"
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 0.75:
		return ""
	position.x += direction * push_speed * delta
	ShadowWorld.mark_dirty()
	return "push"


func try_pull(from_global: Vector2, pull_direction: float, delta: float) -> String:
	## Pull the box toward / with the player while V is held.
	## pull_direction is the player's move direction (box follows).
	if not moveable:
		_shake_time = 0.18
		return "bump"
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 0.9:
		return ""
	var dist_x := absf(from_global.x - my_center.x)
	if dist_x > box_size.x * 0.5 + 36.0:
		return ""
	# Player must be on one side; pull moves the box the same way the player walks.
	position.x += pull_direction * push_speed * 0.95 * delta
	ShadowWorld.mark_dirty()
	return "pull"
