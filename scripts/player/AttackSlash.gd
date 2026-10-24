extends Node2D
class_name AttackSlash
## Short-lived ink slash drawn in front of the spirit based on aim.


func play(aim: int, facing: float) -> void:
	scale.x = facing
	rotation_degrees = -55.0 if aim > 0 else (55.0 if aim < 0 else 0.0)
	position = Vector2(22.0 * facing, -18.0 if aim == 0 else (-36.0 if aim > 0 else 4.0))
	var poly := Polygon2D.new()
	poly.color = Color(0.9, 0.9, 0.95, 0.85)
	poly.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(34, -10), Vector2(42, 0), Vector2(34, 10), Vector2(0, 4)
	])
	add_child(poly)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.55, 0.2, 0.35, 0.9)
	for p in poly.polygon:
		edge.add_point(p)
	add_child(edge)
	var tw := create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.18)
	tw.parallel().tween_property(self, "scale", Vector2(facing * 1.35, 1.2), 0.18)
	tw.tween_callback(queue_free)
