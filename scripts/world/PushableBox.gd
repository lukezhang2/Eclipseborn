extends StaticBody2D
class_name PushableBox
## Moveable crate. Blocks light. Push by walking into it; pull with V nearby.

@export var box_size: Vector2 = Vector2(58, 58)
@export var push_speed: float = 120.0

var _visual: WorldArt
var _shake_time: float = 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	_build()
	add_to_group("boxes")


func _physics_process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		if _visual:
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
	# Dark-oak X-brace crate with iron corners.
	_visual = WorldArt.new()
	_visual.kind = WorldArt.Kind.CRATE
	_visual.style = 7
	_visual.size = box_size
	add_child(_visual)
	var occ := ShadowOccluder.new()
	occ.local_polygon = poly
	add_child(occ)


func rebuild_visual_for_size(size: Vector2) -> void:
	box_size = size
	for c in get_children():
		c.queue_free()
	_build()


func _clamp_x() -> void:
	position.x = clampf(position.x, GameState.map_min_x + box_size.x * 0.5, GameState.map_max_x - box_size.x * 0.5)


func _can_move(dx: float) -> bool:
	if absf(dx) < 0.001:
		return false
	var space := get_world_2d().direct_space_state
	# Thin probe centered in the crate, raised off the floor so ground never blocks.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(box_size.x * 0.82, maxf(12.0, box_size.y * 0.45))
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position + Vector2(dx, -box_size.y * 0.15))
	params.collision_mask = 1
	params.exclude = [get_rid()]
	return space.intersect_shape(params, 4).is_empty()


func try_push(from_global: Vector2, direction: float, delta: float) -> String:
	var my_center := global_position
	# Reject standing on top — player feet should be beside the crate, not above the lid.
	var player_feet_y := from_global.y
	var lid_y := my_center.y - box_size.y * 0.35
	if player_feet_y < lid_y:
		return ""
	if absf(from_global.y - my_center.y) > box_size.y * 0.85:
		return ""
	var dx_to := my_center.x - from_global.x
	if direction == 0.0 or signf(dx_to) != signf(direction):
		return ""
	# Must be close to the contacted face (no remote / on-top shove).
	if absf(dx_to) > box_size.x * 0.5 + 20.0:
		return ""
	var dx := direction * push_speed * delta
	if not _can_move(dx):
		_shake_time = 0.12
		return ""
	global_position.x += dx
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "push"


func try_pull(from_global: Vector2, pull_direction: float, delta: float, max_speed: float = -1.0) -> String:
	## Pull the crate toward the player, never closing past a stand-off gap (stops
	## self-acceleration from ramming and wall-wedging when the player backs up).
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 1.15:
		return ""
	if absf(from_global.x - my_center.x) > box_size.x * 0.5 + 60.0:
		return ""
	if pull_direction == 0.0:
		return ""
	## Must move toward the player (close the gap), not shove past them.
	var toward_player := signf(from_global.x - my_center.x)
	if toward_player == 0.0 or signf(pull_direction) != toward_player:
		return ""

	var gap := absf(my_center.x - from_global.x)
	## Half-crate + ~player body half-width + small cushion.
	var min_gap := box_size.x * 0.5 + 22.0
	if gap <= min_gap + 0.5:
		return ""

	var speed := push_speed * 0.95
	if max_speed > 0.0:
		speed = minf(speed, max_speed)
	var dx := pull_direction * speed * delta
	## Cap so this step cannot close past min_gap (no overlap / eject boost).
	var max_close := gap - min_gap
	if absf(dx) > max_close:
		dx = signf(dx) * max_close
	if absf(dx) < 0.001:
		return ""
	if not _can_move(dx):
		return ""
	global_position.x += dx
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "pull"


func pull_stand_x(player_facing_sign: float) -> float:
	return global_position.x - player_facing_sign * (box_size.x * 0.5 + 18.0)
