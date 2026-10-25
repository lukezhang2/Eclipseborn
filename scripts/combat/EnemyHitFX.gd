extends RefCounted
class_name EnemyHitFX
## Shared punchy hit flash for enemy sprites / polygons.


static func play(visual: CanvasItem, body: Node2D = null, from: Node = null) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	## Brief knockback away from the attacker.
	if body and is_instance_valid(body) and from is Node2D and is_instance_valid(from):
		var away := signf(body.global_position.x - (from as Node2D).global_position.x)
		if away == 0.0:
			away = 1.0
		if body is CharacterBody2D:
			(body as CharacterBody2D).velocity.x = away * 160.0
			(body as CharacterBody2D).velocity.y = minf((body as CharacterBody2D).velocity.y, -40.0)
		else:
			body.global_position.x += away * 6.0

	var base_scale: Vector2 = visual.scale
	## White → crimson flash reads clearly on dark shade enemies.
	visual.modulate = Color(2.2, 2.2, 2.2, 1.0)
	var tw := visual.create_tween()
	tw.tween_property(visual, "modulate", Color(1.7, 0.25, 0.3, 1.0), 0.05)
	tw.tween_property(visual, "modulate", Color(1.35, 0.55, 0.55, 1.0), 0.07)
	tw.tween_property(visual, "modulate", Color.WHITE, 0.12)
	## Scale punch — pop out then settle.
	visual.scale = base_scale * Vector2(1.22, 0.82)
	var tw2 := visual.create_tween()
	tw2.tween_property(visual, "scale", base_scale * Vector2(0.92, 1.12), 0.06)
	tw2.tween_property(visual, "scale", base_scale, 0.1)
