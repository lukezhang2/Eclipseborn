extends Node2D
## Draws the live CollisionShape2D volumes in world space (not a separate fake overlay).


var _debug_on: bool = false


func _draw() -> void:
	if not _debug_on:
		return
	var tree := get_tree()
	if tree == null:
		return
	for hb in tree.get_nodes_in_group("hurtboxes"):
		if hb is Area2D:
			_draw_area(hb as Area2D, Color(0.2, 1.0, 0.35, 0.35), Color(0.2, 1.0, 0.4, 0.9))
	for node in tree.get_nodes_in_group("hitboxes"):
		if node is Area2D and (node as Area2D).monitoring:
			_draw_area(node as Area2D, Color(1.0, 0.25, 0.2, 0.4), Color(1.0, 0.35, 0.3, 1.0))
	var p = GameState.player
	if p and is_instance_valid(p):
		var cs := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.shape is CapsuleShape2D:
			var cap := cs.shape as CapsuleShape2D
			var o := cs.global_position
			var half_cyl := cap.height * 0.5
			draw_circle(o + Vector2(0, -half_cyl), cap.radius, Color(0.3, 0.6, 1.0, 0.3))
			draw_circle(o + Vector2(0, half_cyl), cap.radius, Color(0.3, 0.6, 1.0, 0.3))
			draw_rect(
				Rect2(o - Vector2(cap.radius, half_cyl), Vector2(cap.radius * 2.0, cap.height)),
				Color(0.3, 0.6, 1.0, 0.22),
				true
			)


func _draw_area(area: Area2D, fill: Color, edge: Color) -> void:
	for child in area.get_children():
		if not child is CollisionShape2D:
			continue
		var cs := child as CollisionShape2D
		if cs.disabled or cs.shape == null:
			continue
		# Use the shape's global transform so rotation/scale match gameplay.
		var xf := cs.global_transform
		if cs.shape is RectangleShape2D:
			var r := (cs.shape as RectangleShape2D).size
			var half := r * 0.5
			var pts := PackedVector2Array([
				xf * Vector2(-half.x, -half.y),
				xf * Vector2(half.x, -half.y),
				xf * Vector2(half.x, half.y),
				xf * Vector2(-half.x, half.y),
			])
			draw_colored_polygon(pts, fill)
			for i in 4:
				draw_line(pts[i], pts[(i + 1) % 4], edge, 2.0)
		elif cs.shape is CircleShape2D:
			var rad := (cs.shape as CircleShape2D).radius
			var origin := xf.origin
			draw_circle(origin, rad, fill)
			draw_arc(origin, rad, 0, TAU, 24, edge, 2.0)
		elif cs.shape is CapsuleShape2D:
			var cap := cs.shape as CapsuleShape2D
			var o := xf.origin
			draw_circle(o + Vector2(0, -cap.height * 0.5), cap.radius, fill)
			draw_circle(o + Vector2(0, cap.height * 0.5), cap.radius, fill)
