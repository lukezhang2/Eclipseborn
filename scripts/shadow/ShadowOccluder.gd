extends Node2D
class_name ShadowOccluder
## Any shape that blocks light and casts walkable / wall shadows.

@export var local_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24)
])

var _last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_last_pos = global_position
	ShadowWorld.register_occluder(self)
	add_to_group("occluders")


func _exit_tree() -> void:
	ShadowWorld.unregister_occluder(self)


func did_move() -> bool:
	if global_position.distance_squared_to(_last_pos) > 0.25:
		_last_pos = global_position
		return true
	return false


func get_world_polygon() -> PackedVector2Array:
	var out := PackedVector2Array()
	var xform := global_transform
	for p in local_polygon:
		out.append(xform * p)
	return out
