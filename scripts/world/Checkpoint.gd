extends Area2D
class_name Checkpoint
## Dark save spot (unlit fireplace). Restores health + shade.

@export var checkpoint_id: String = "default"

var _lit_once: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	_build_visual()
	add_to_group("checkpoints")


func _build_visual() -> void:
	var hearth := Polygon2D.new()
	hearth.polygon = PackedVector2Array([
		Vector2(-28, 0), Vector2(28, 0), Vector2(22, -18), Vector2(-22, -18)
	])
	hearth.color = Color(0.12, 0.1, 0.1)
	add_child(hearth)
	var label := Label.new()
	label.text = "…"
	label.position = Vector2(-6, -36)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	add_child(label)


func _on_body_entered(body: Node) -> void:
	if body is Player or body.is_in_group("player"):
		GameState.set_checkpoint(global_position, checkpoint_id)
		_lit_once = true
