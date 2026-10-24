extends RefCounted
class_name SpiritSprites
## Small shadow spirit: soft ovals, fill #11011c, outline #000000. Weapon for attacks.


const FILL := Color("11011c")
const OUTLINE := Color("000000")
const EYE := Color(0.95, 0.95, 0.93, 1.0)
const WEAPON := Color(0.75, 0.78, 0.85, 1.0)


static func build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var anims := {
		"idle": [_draw(0, 0, 0, false, 0, 0), _draw(0, -1, 0, false, 0, 0), _draw(0, 0, 1, false, 0, 0), _draw(0, 1, 0, false, 0, 0)],
		"walk": [_draw(0, 0, 0, false, 0, 1), _draw(0, 0, 0, false, 0, 2), _draw(0, 0, 0, false, 0, 3), _draw(0, 0, 0, false, 0, 4)],
		"run": [_draw(1, 0, 0, false, 0, 1, true), _draw(1, 0, 0, false, 0, 2, true), _draw(1, 0, 0, false, 0, 3, true), _draw(1, 0, 0, false, 0, 4, true)],
		"jump": [_draw(0, -2, 0, true, 0, 0)],
		"fall": [_draw(0, 2, 0, true, 0, 0)],
		"push": [_draw(2, 0, 0, false, 0, 0, false, true)],
		"pull": [_draw(-2, 0, 0, false, 0, 0, false, true)],
		"bump": [_draw(-1, 0, 0, false, 0, 0)],
		"crouch": [_draw_crouch(0)],
		"crouch_walk": [_draw_crouch(1), _draw_crouch(2)],
		"attack_east": _attack(0),
		"attack_west": _attack(0),  # flipped by sprite scale
		"attack_north": _attack(1),
		"attack_south": _attack(-1),
		"attack_forward": _attack(0),
		"attack_up": _attack(1),
		"attack_down": _attack(-1),
		"shade_drain": [_draw(0, 0, 0, false, 0, 0, false, false, Color(0.55, 0.45, 0.7))],
		"light_burn": [_draw(0, 0, 0, false, 0, 0, false, false, Color(0.7, 0.35, 0.25))],
	}
	for anim_name in anims.keys():
		if frames.has_animation(anim_name):
			frames.clear(anim_name)
		else:
			frames.add_animation(anim_name)
		var loop: bool = anim_name in ["idle", "walk", "run", "crouch", "crouch_walk", "shade_drain", "light_burn"]
		frames.set_animation_loop(anim_name, loop)
		frames.set_animation_speed(anim_name, 10.0 if anim_name in ["walk", "run"] else 7.0)
		if anim_name.begins_with("attack"):
			frames.set_animation_speed(anim_name, 16.0)
			frames.set_animation_loop(anim_name, false)
		for img in anims[anim_name]:
			frames.add_frame(anim_name, ImageTexture.create_from_image(img))
	return frames


static func _attack(aim: int) -> Array:
	return [_draw(0, 0, aim, false, 1, 0), _draw(0, 0, aim, false, 2, 0), _draw(0, 0, aim, false, 3, 0)]


static func _draw(
	lean: int = 0,
	bob: int = 0,
	look: int = 0,
	air: bool = false,
	slash: int = 0,
	leg: int = 0,
	running: bool = false,
	shove: bool = false,
	tint: Color = Color.WHITE
) -> Image:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := FILL * tint
	fill.a = 1.0
	var cx := 24 + lean
	var base := 52 + bob

	# Soft cloak / body (tall oval) — Hollow Knight–ish small silhouette, no mask
	var body_top := base - 28
	_oval(img, cx, body_top + 10, 9, 14, fill, true)
	_oval(img, cx, body_top + 10, 9, 14, OUTLINE, false)

	# Head (rounder, slightly separate)
	var hy := body_top - 2
	if look > 0:
		hy -= 1
	elif look < 0:
		hy += 2
	_oval(img, cx, hy, 8, 8, fill, true)
	_oval(img, cx, hy, 8, 8, OUTLINE, false)
	# Horn-like flame wisps (not a mask) — tiny twin tufts
	_oval(img, cx - 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx + 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx - 4, hy - 7, 2, 3, OUTLINE, false)
	_oval(img, cx + 4, hy - 7, 2, 3, OUTLINE, false)
	# Eyes
	var ey := hy - 1 + (1 if look < 0 else (-1 if look > 0 else 0))
	_oval(img, cx - 3, ey, 2, 2, EYE, true)
	_oval(img, cx + 3, ey, 2, 2, EYE, true)

	# Legs — tapered ovals, not squares
	var llx := cx - 4
	var lrx := cx + 4
	var lly := base - 2
	var lry := base - 2
	match leg:
		1:
			llx -= 2
			lry -= 3
		2:
			lrx += 2
			lly -= 3
		3:
			llx -= 1
			lry -= 2
		4:
			lrx += 1
			lly -= 2
	if air:
		llx -= 1
		lrx += 2
		lly -= 2
		lry -= 4
	if running:
		llx -= 2
		lrx += 3
	_oval(img, llx, lly - 5, 3, 6, fill, true)
	_oval(img, lrx, lry - 5, 3, 6, fill, true)
	_oval(img, llx, lly - 5, 3, 6, OUTLINE, false)
	_oval(img, lrx, lry - 5, 3, 6, OUTLINE, false)

	# Arms / weapon
	var arm_x := cx + (8 if shove else 6)
	var arm_y := body_top + 8
	if slash > 0:
		_draw_weapon(img, cx, hy, look, slash)
	else:
		_oval(img, cx - 8, arm_y, 3, 5, fill, true)
		_oval(img, arm_x, arm_y + ( -3 if look > 0 else (3 if look < 0 else 0)), 3, 5, fill, true)
		_oval(img, cx - 8, arm_y, 3, 5, OUTLINE, false)
		_oval(img, arm_x, arm_y + ( -3 if look > 0 else (3 if look < 0 else 0)), 3, 5, OUTLINE, false)

	return img


static func _draw_weapon(img: Image, cx: int, hy: int, look: int, phase: int) -> void:
	## Short needle/blade — faces cardinal aim.
	var tip := Vector2(cx + 6 + phase * 4, hy + 4)
	var butt := Vector2(cx + 2, hy + 6)
	if look > 0:
		tip = Vector2(cx + 2, hy - 6 - phase * 3)
		butt = Vector2(cx + 1, hy + 2)
	elif look < 0:
		tip = Vector2(cx + 3, hy + 14 + phase * 3)
		butt = Vector2(cx + 2, hy + 4)
	_line_thick(img, butt, tip, WEAPON, 2)
	_line_thick(img, butt, tip, OUTLINE, 1)


static func _draw_crouch(leg: int) -> Image:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := 24
	var base := 54
	_oval(img, cx, base - 14, 10, 10, FILL, true)
	_oval(img, cx, base - 14, 10, 10, OUTLINE, false)
	_oval(img, cx, base - 24, 7, 7, FILL, true)
	_oval(img, cx, base - 24, 7, 7, OUTLINE, false)
	_oval(img, cx - 3, base - 25, 2, 2, EYE, true)
	_oval(img, cx + 3, base - 25, 2, 2, EYE, true)
	var ox := 1 if leg == 1 else (-1 if leg == 2 else 0)
	_oval(img, cx - 5 + ox, base - 4, 3, 4, FILL, true)
	_oval(img, cx + 5 - ox, base - 4, 3, 4, FILL, true)
	_oval(img, cx - 5 + ox, base - 4, 3, 4, OUTLINE, false)
	_oval(img, cx + 5 - ox, base - 4, 3, 4, OUTLINE, false)
	return img


static func _oval(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color, filled: bool) -> void:
	for y in range(cy - ry - 1, cy + ry + 2):
		for x in range(cx - rx - 1, cx + rx + 2):
			var dx := float(x - cx) / float(maxi(rx, 1))
			var dy := float(y - cy) / float(maxi(ry, 1))
			var d := dx * dx + dy * dy
			if filled:
				if d <= 1.0:
					_plot(img, x, y, col)
			else:
				if d <= 1.05 and d >= 0.72:
					_plot(img, x, y, col)


static func _line_thick(img: Image, a: Vector2, b: Vector2, col: Color, thick: int) -> void:
	var steps := int(a.distance_to(b)) + 1
	for i in steps:
		var p := a.lerp(b, float(i) / float(maxi(steps, 1)))
		for oy in range(-thick, thick + 1):
			for ox in range(-thick, thick + 1):
				if ox * ox + oy * oy <= thick * thick:
					_plot(img, int(p.x) + ox, int(p.y) + oy, col)


static func _plot(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)
