extends Area2D
class_name Checkpoint
## Dark save hearth. Restores / stores respawn. (Was the cryptic "…" three-dot marker.)

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
	# Trapezoid hearth base
	var hearth := Polygon2D.new()
	hearth.polygon = PackedVector2Array([
		Vector2(-28, 0), Vector2(28, 0), Vector2(22, -18), Vector2(-22, -18)
	])
	hearth.color = Color(0.14, 0.11, 0.1)
	add_child(hearth)
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([
		Vector2(-24, -18), Vector2(24, -18), Vector2(18, -26), Vector2(-18, -26)
	])
	lip.color = Color(0.22, 0.18, 0.16)
	add_child(lip)
	# Ember glow (not three mystery dots)
	var ember := Polygon2D.new()
	ember.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(5, -16), Vector2(-5, -16)
	])
	ember.color = Color(0.55, 0.25, 0.12, 0.7)
	add_child(ember)
	var label := Label.new()
	label.text = "Rest"
	label.position = Vector2(-16, -44)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	add_child(label)


func _on_body_entered(body: Node) -> void:
	if body is Player or body.is_in_group("player"):
		GameState.set_checkpoint(global_position, checkpoint_id)
		_lit_once = true
