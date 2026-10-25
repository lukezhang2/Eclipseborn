extends Interactable
class_name LightSwitch
## Lever that turns linked lights on or off. Press Interact (E) nearby to flip it.

@export var target_light_paths: Array[NodePath] = []
@export var starts_on: bool = true

var _on: bool = true
var _visual: Polygon2D


func _ready() -> void:
	verb = "Flip"
	super()
	_on = starts_on
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-8, -20), Vector2(8, -20), Vector2(6, 10), Vector2(-6, 10)
	])
	_visual.color = Color(0.5, 0.45, 0.3)
	add_child(_visual)
	_apply()


func interact() -> void:
	_on = not _on
	_apply()


func _apply() -> void:
	_visual.rotation_degrees = -25.0 if _on else 25.0
	for path in target_light_paths:
		var n := get_node_or_null(path)
		if n and n.has_method("set_on"):
			n.set_on(_on)
