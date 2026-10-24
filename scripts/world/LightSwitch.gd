extends Area2D
class_name LightSwitch
## Lever that turns linked lights on or off.

@export var target_light_paths: Array[NodePath] = []
@export var starts_on: bool = true

var _on: bool = true
var _visual: Polygon2D


func _ready() -> void:
	_on = starts_on
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-8, -20), Vector2(8, -20), Vector2(6, 10), Vector2(-6, 10)
	])
	_visual.color = Color(0.5, 0.45, 0.3)
	add_child(_visual)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 40)
	cs.shape = rect
	add_child(cs)
	_apply()


func _on_body(body: Node) -> void:
	if body is Player or body.is_in_group("player"):
		_on = not _on
		_apply()


func _apply() -> void:
	_visual.rotation_degrees = -25.0 if _on else 25.0
	for path in target_light_paths:
		var n := get_node_or_null(path)
		if n and n.has_method("set_on"):
			n.set_on(_on)
