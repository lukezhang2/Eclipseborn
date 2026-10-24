extends Node2D
class_name AttackSlash
## Cardinal ink slash — tapered brush stroke inspired by, not copying, a white swoosh.


func play(aim_dir: Vector2) -> void:
	## aim_dir is unit cardinal: (1,0), (-1,0), (0,-1), (0,1)
	var poly := Polygon2D.new()
	poly.color = Color(0.92, 0.93, 0.97, 0.92)
	# Local shape: thin tail at -x, bulbous head at +x, slight top notch.
	poly.polygon = PackedVector2Array([
		Vector2(-6, -1),
		Vector2(10, -5),
		Vector2(28, -7),
		Vector2(36, -4),
		Vector2(40, 0),
		Vector2(36, 5),
		Vector2(22, 4),
		Vector2(8, 2),
		Vector2(-4, 1),
	])
	add_child(poly)
	var edge := Line2D.new()
	edge.width = 1.5
	edge.default_color = Color(0, 0, 0, 0.85)
	for p in poly.polygon:
		edge.add_point(p)
	edge.add_point(poly.polygon[0])
	add_child(edge)

	if absf(aim_dir.x) > absf(aim_dir.y):
		# East / West
		rotation = 0.0
		scale.x = signf(aim_dir.x)
		position = Vector2(26.0 * signf(aim_dir.x), -16.0)
	elif aim_dir.y < 0.0:
		rotation = -PI * 0.5
		scale.x = 1.0
		position = Vector2(0, -42)
	else:
		rotation = PI * 0.5
		scale.x = 1.0
		position = Vector2(0, 6)

	var tw := create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.16)
	tw.parallel().tween_property(self, "scale", scale * Vector2(1.25, 1.1), 0.16)
	tw.tween_callback(queue_free)
