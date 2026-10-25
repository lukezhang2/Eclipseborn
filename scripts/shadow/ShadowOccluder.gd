extends Node2D
class_name ShadowOccluder
## Any shape that blocks light and casts walkable / wall shadows.
## blocks_gameplay=false → visual wash/umbra only (BG murals); does not shade the player.

@export var local_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24)
])
@export var blocks_gameplay: bool = true

var _last_pos: Vector2 = Vector2.ZERO
var _last_rot: float = 0.0


func _ready() -> void:
	_last_pos = global_position
	_last_rot = global_rotation
	ShadowWorld.register_occluder(self)
	add_to_group("occluders")


func _exit_tree() -> void:
	ShadowWorld.unregister_occluder(self)


func blocks_gameplay_light() -> bool:
	return blocks_gameplay


func did_move() -> bool:
	if global_position.distance_squared_to(_last_pos) > 0.25 \
			or absf(global_rotation - _last_rot) > 0.01:
		_last_pos = global_position
		_last_rot = global_rotation
		return true
	return false


func get_world_polygon() -> PackedVector2Array:
	var out := PackedVector2Array()
	var xform := global_transform
	for p in local_polygon:
		out.append(xform * p)
	return out
