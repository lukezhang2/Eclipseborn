extends RefCounted
class_name SpiritSprites
## Builds pixel sprites for the shadow spirit: head, body, legs, face, and attack poses.


static func build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var anims := {
		"idle": _idle_frames(),
		"walk": _walk_frames(),
		"run": _run_frames(),
		"jump": [_draw_pose(0, 0, -2, true, false, 0)],
		"fall": [_draw_pose(0, 0, 3, true, false, 0)],
		"push": [_draw_pose(2, 1, 0, false, true, 0)],
		"pull": [_draw_pose(-2, 1, 0, false, true, 0)],
		"bump": [_draw_pose(-1, 0, 0, false, false, 0)],
		"crouch": [_draw_crouch(0)],
		"crouch_walk": [_draw_crouch(1), _draw_crouch(2), _draw_crouch(1), _draw_crouch(0)],
		"attack_forward": _attack_frames(0),
		"attack_up": _attack_frames(1),
		"attack_down": _attack_frames(-1),
		"shade_drain": [_draw_pose(0, 0, 0, false, false, 0, Color(0.75, 0.75, 0.85))],
		"light_burn": [_draw_pose(0, 0, 0, false, false, 0, Color(1.0, 0.65, 0.45))],
	}
	for anim_name in anims.keys():
		if frames.has_animation(anim_name):
			frames.clear(anim_name)
		else:
			frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim_name in ["idle", "walk", "run", "shade_drain", "light_burn"])
		frames.set_animation_speed(anim_name, 8.0 if anim_name in ["walk", "run"] else 6.0)
		if anim_name.begins_with("attack"):
			frames.set_animation_speed(anim_name, 14.0)
			frames.set_animation_loop(anim_name, false)
		for img in anims[anim_name]:
			frames.add_frame(anim_name, ImageTexture.create_from_image(img))
	return frames


static func _idle_frames() -> Array:
	return [
		_draw_pose(0, 0, 0, false, false, 0),
		_draw_pose(0, 0, -1, false, false, 0),
		_draw_pose(0, 0, 0, false, false, 1),
		_draw_pose(0, 0, 1, false, false, 0),
	]


static func _walk_frames() -> Array:
	return [
		_draw_pose(0, 0, 0, false, false, 0, Color.WHITE, 1),
		_draw_pose(0, 0, 0, false, false, 0, Color.WHITE, 2),
		_draw_pose(0, 0, 0, false, false, 0, Color.WHITE, 3),
		_draw_pose(0, 0, 0, false, false, 0, Color.WHITE, 4),
	]


static func _run_frames() -> Array:
	return [
		_draw_pose(1, 0, 0, false, false, 0, Color.WHITE, 1, true),
		_draw_pose(1, 0, 0, false, false, 0, Color.WHITE, 2, true),
		_draw_pose(1, 0, 0, false, false, 0, Color.WHITE, 3, true),
		_draw_pose(1, 0, 0, false, false, 0, Color.WHITE, 4, true),
	]


static func _attack_frames(aim: int) -> Array:
	return [
		_draw_pose(0, 0, 0, false, false, aim, Color.WHITE, 0, false, 1),
		_draw_pose(0, 0, 0, false, false, aim, Color.WHITE, 0, false, 2),
		_draw_pose(0, 0, 0, false, false, aim, Color.WHITE, 0, false, 3),
	]


static func _draw_crouch(leg_phase: int = 0) -> Image:
	## Shorter pose: knees bent, head lower.
	var w := 48
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color(0.05, 0.04, 0.08, 1.0)
	var edge := Color(0.45, 0.14, 0.1, 0.9)
	var eye := Color(0.95, 0.95, 0.92, 1.0)
	var cx := 24
	var base_y := 56
	var leg_l := cx - 6 + (1 if leg_phase == 1 else 0)
	var leg_r := cx + 5 - (1 if leg_phase == 2 else 0)
	_fill_rect(img, leg_l - 2, base_y - 10, 4, 10, body)
	_fill_rect(img, leg_r - 2, base_y - 10, 4, 10, body)
	_fill_rect(img, cx - 8, base_y - 22, 16, 12, body)
	_fill_rect(img, cx - 9, base_y - 21, 1, 10, edge)
	_fill_rect(img, cx + 8, base_y - 21, 1, 10, edge)
	_fill_rect(img, cx - 11, base_y - 20, 4, 8, body)
	_fill_rect(img, cx + 7, base_y - 20, 4, 8, body)
	var head_y := base_y - 32
	_fill_rect(img, cx - 7, head_y, 14, 12, body)
	_fill_rect(img, cx - 6, head_y - 2, 12, 3, edge)
	_fill_rect(img, cx - 5, head_y + 6, 3, 3, eye)
	_fill_rect(img, cx + 2, head_y + 6, 3, 3, eye)
	return img


static func _draw_pose(
	lean: int = 0,
	_arm_shift: int = 0,
	bob: int = 0,
	air: bool = false,
	push: bool = false,
	look: int = 0,
	tint: Color = Color.WHITE,
	leg_phase: int = 0,
	running: bool = false,
	slash_phase: int = 0
) -> Image:
	var w := 48
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var body := Color(0.05, 0.04, 0.08, 1.0) * tint
	body.a = 1.0
	var edge := Color(0.45, 0.14, 0.1, 0.9) * tint
	edge.a = 0.9
	var eye := Color(0.95, 0.95, 0.92, 1.0)
	var cx := 24 + lean
	var base_y := 54 + bob

	# Legs
	var leg_l := Vector2i(cx - 5, base_y)
	var leg_r := Vector2i(cx + 4, base_y)
	match leg_phase:
		1:
			leg_l.y -= 2
			leg_r.x += 2
		2:
			leg_l.x -= 2
			leg_r.y -= 3
		3:
			leg_l.y -= 1
			leg_r.x += 1
		4:
			leg_l.x += 1
			leg_r.y -= 2
	if air:
		leg_l = Vector2i(cx - 4, base_y - 2)
		leg_r = Vector2i(cx + 5, base_y - 4)
	if running:
		leg_l.x -= 2
		leg_r.x += 3

	_fill_rect(img, leg_l.x - 2, leg_l.y - 14, 4, 14, body)
	_fill_rect(img, leg_r.x - 2, leg_r.y - 14, 4, 14, body)
	_fill_rect(img, leg_l.x - 3, leg_l.y - 2, 5, 3, edge)
	_fill_rect(img, leg_r.x - 2, leg_r.y - 2, 5, 3, edge)

	# Torso
	var torso_top := base_y - 30
	_fill_rect(img, cx - 7, torso_top, 14, 18, body)
	_fill_rect(img, cx - 8, torso_top + 2, 16, 14, body)
	# Ember rim
	_fill_rect(img, cx - 8, torso_top, 1, 18, edge)
	_fill_rect(img, cx + 7, torso_top, 1, 18, edge)

	# Arms
	var arm_y := torso_top + 4
	var arm_fwd := 10 if push else 6
	if slash_phase > 0:
		arm_fwd = 8 + slash_phase * 3
	var arm_up := 0
	if look > 0:
		arm_up = -6 - slash_phase * 2
	elif look < 0:
		arm_up = 4 + slash_phase * 2
	_fill_rect(img, cx - 11, arm_y, 4, 12, body)
	_fill_rect(img, cx + arm_fwd - 2, arm_y + arm_up, 4, 11, body)

	# Head
	var head_y := torso_top - 12
	_fill_rect(img, cx - 7, head_y, 14, 13, body)
	_fill_rect(img, cx - 6, head_y - 2, 12, 3, edge)  # flame hair tuft
	_fill_rect(img, cx - 2, head_y - 5, 4, 4, edge)

	# Face / eyes — tilt with look
	var eye_y := head_y + 5 + ( -1 if look > 0 else (2 if look < 0 else 0))
	_fill_rect(img, cx - 5, eye_y, 3, 3, eye)
	_fill_rect(img, cx + 2, eye_y, 3, 3, eye)
	# Tiny mouth
	_fill_rect(img, cx - 2, head_y + 10, 4, 1, Color(0.2, 0.15, 0.2, 0.8))

	# Attack slash overlay on sprite (extra ink arc)
	if slash_phase > 0:
		var slash_col := Color(0.85, 0.85, 0.95, 0.85)
		if look > 0:
			for i in range(4 + slash_phase * 2):
				_plot(img, cx + 8 + i, head_y - 2 - i, slash_col)
				_plot(img, cx + 9 + i, head_y - 1 - i, slash_col)
		elif look < 0:
			for i in range(4 + slash_phase * 2):
				_plot(img, cx + 8 + i, base_y - 18 + i, slash_col)
				_plot(img, cx + 9 + i, base_y - 17 + i, slash_col)
		else:
			for i in range(5 + slash_phase * 2):
				_plot(img, cx + 10 + i, arm_y + 2 + int(sin(i * 0.8) * 2), slash_col)
				_plot(img, cx + 10 + i, arm_y + 3 + int(sin(i * 0.8) * 2), slash_col)

	return img


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			_plot(img, px, py, c)


static func _plot(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)
