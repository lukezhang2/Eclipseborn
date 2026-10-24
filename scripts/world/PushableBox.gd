extends StaticBody2D
class_name PushableBox
## Moveable crate. Blocks light. Push by walking into it; pull with V nearby.

@export var box_size: Vector2 = Vector2(48, 48)
@export var push_speed: float = 140.0

var _visual: Sprite2D
var _shake_time: float = 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	_build()
	add_to_group("boxes")


func _physics_process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		if _visual:
			_visual.position.x = sin(_shake_time * 60.0) * 3.0
			if _shake_time <= 0.0:
				_visual.position = Vector2.ZERO


func _build() -> void:
	var half := box_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)
	_visual = Sprite2D.new()
	_visual.texture = _make_wood_texture(int(box_size.x), int(box_size.y))
	_visual.centered = true
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_visual)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.05, 0.02, 0.08, 0.95)
	for p in poly:
		edge.add_point(p)
	edge.add_point(poly[0])
	add_child(edge)
	var occ := ShadowOccluder.new()
	occ.local_polygon = poly
	add_child(occ)


func rebuild_visual_for_size(size: Vector2) -> void:
	box_size = size
	for c in get_children():
		c.queue_free()
	_build()


func _make_wood_texture(w: int, h: int) -> ImageTexture:
	w = maxi(w, 8)
	h = maxi(h, 8)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var grain := sin(float(x) * 0.35 + float(y) * 0.02) * 0.04
			var noise := fmod(float(x * 17 + y * 31), 7.0) * 0.008
			var base := Color(0.42 + grain, 0.30 + grain * 0.5, 0.18 + noise, 1.0)
			if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
				base = Color(0.18, 0.1, 0.05, 1.0)
			elif y % 10 == 0:
				base = base.darkened(0.12)
			img.set_pixel(x, y, base)
	for p in [Vector2i(5, 5), Vector2i(w - 6, 5), Vector2i(5, h - 6), Vector2i(w - 6, h - 6)]:
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				img.set_pixel(clampi(p.x + ox, 0, w - 1), clampi(p.y + oy, 0, h - 1), Color(0.55, 0.45, 0.28))
	return ImageTexture.create_from_image(img)


func _clamp_x() -> void:
	position.x = clampf(position.x, GameState.map_min_x + box_size.x * 0.5, GameState.map_max_x - box_size.x * 0.5)


func _can_move(dx: float) -> bool:
	if absf(dx) < 0.001:
		return false
	var space := get_world_2d().direct_space_state
	# Thin probe centered in the crate, raised off the floor so ground never blocks.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(box_size.x * 0.82, maxf(12.0, box_size.y * 0.45))
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position + Vector2(dx, -box_size.y * 0.15))
	params.collision_mask = 1
	params.exclude = [get_rid()]
	return space.intersect_shape(params, 4).is_empty()


func try_push(from_global: Vector2, direction: float, delta: float) -> String:
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 1.1:
		return ""
	var dx_to := my_center.x - from_global.x
	# Must be approaching the box from the correct side (or already overlapping).
	if absf(dx_to) > 6.0 and signf(direction) != 0.0 and signf(dx_to) != signf(direction):
		return ""
	if absf(from_global.x - my_center.x) > box_size.x * 0.5 + 48.0:
		return ""
	var dx := direction * push_speed * delta
	if not _can_move(dx):
		_shake_time = 0.12
		return ""
	global_position.x += dx
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "push"


func try_pull(from_global: Vector2, pull_direction: float, delta: float) -> String:
	var my_center := global_position
	if absf(from_global.y - my_center.y) > box_size.y * 1.15:
		return ""
	if absf(from_global.x - my_center.x) > box_size.x * 0.5 + 60.0:
		return ""
	var dx := pull_direction * push_speed * 0.95 * delta
	if not _can_move(dx):
		return ""
	global_position.x += dx
	_clamp_x()
	ShadowWorld.mark_dirty()
	return "pull"


func pull_stand_x(player_facing_sign: float) -> float:
	return global_position.x - player_facing_sign * (box_size.x * 0.5 + 18.0)
