extends RefCounted
class_name SpiritSprites
## Small shadow spirit: soft ovals, fill #11011c, outline #000000.
## Run = walk frames faster. Damage adds head-dissipate wisps without canceling locomotion.


const FILL := Color("11011c")
const OUTLINE := Color("000000")
const EYE := Color(0.95, 0.95, 0.93, 1.0)
const WEAPON := Color(0.75, 0.78, 0.85, 1.0)
const SHADE_WISP := Color(0.55, 0.35, 0.85, 0.85)
const BURN_WISP := Color(0.95, 0.45, 0.2, 0.9)


static func build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var bases := {
		"idle": [
			_draw(0, 0, 0, false, 0, 0),
			_draw(0, -1, 0, false, 0, 0),
			_draw(0, 0, 1, false, 0, 0),
			_draw(0, 1, 0, false, 0, 0),
		],
		"walk": [
			_draw(0, 0, 0, false, 0, 1),
			_draw(0, 0, 0, false, 0, 2),
			_draw(0, 0, 0, false, 0, 3),
			_draw(0, 0, 0, false, 0, 4),
		],
		"jump": [_draw(0, -2, 0, true, 0, 0)],
		## Soft flail — arms rise a little, not a big windmill.
		"fall": [_draw_fall(0), _draw_fall(1)],
		"push": [_draw(2, 0, 0, false, 0, 0, false, true), _draw(3, 0, 0, false, 0, 1, false, true)],
		"pull": [_draw_pull(0), _draw_pull(1), _draw_pull(2)],
		"bump": [_draw(-1, 0, 0, false, 0, 0)],
		"crouch": [_draw_crouch(0)],
		"crouch_walk": [_draw_crouch(1), _draw_crouch(2)],
		"attack_east": _attack(0),
		"attack_west": _attack(0),
		"attack_north": _attack(1),
		"attack_south": _attack(-1),
	}
	# Run shares walk frames (registered separately for speed).
	bases["run"] = bases["walk"].duplicate()

	for anim_name in bases.keys():
		var looping: bool = anim_name in ["idle", "walk", "run", "crouch", "crouch_walk", "pull", "push", "fall"]
		_add_anim(frames, anim_name, bases[anim_name], _speed_for(anim_name), looping)

	# Layered shade/burn variants for locomotion bases.
	var loco := ["idle", "walk", "run", "jump", "fall", "crouch", "crouch_walk", "push", "pull"]
	for base_name in loco:
		var src: Array = bases[base_name]
		var shade_imgs: Array = []
		var burn_imgs: Array = []
		for i in src.size():
			var phase := i % 4
			shade_imgs.append(_with_dissipate(src[i], "shade", phase))
			burn_imgs.append(_with_dissipate(src[i], "burn", phase))
		_add_anim(frames, base_name + "_shade", shade_imgs, _speed_for(base_name), true)
		_add_anim(frames, base_name + "_burn", burn_imgs, _speed_for(base_name), true)

	# Legacy names kept for any leftover references.
	_add_anim(frames, "shade_drain", [_with_dissipate(bases["idle"][0], "shade", 0)], 7.0, true)
	_add_anim(frames, "light_burn", [_with_dissipate(bases["idle"][0], "burn", 0)], 7.0, true)
	return frames


static func _speed_for(anim_name: String) -> float:
	var base := anim_name.replace("_shade", "").replace("_burn", "")
	match base:
		"idle":
			return 4.2
		"walk", "crouch_walk":
			return 10.0
		"run":
			return 18.0
		"pull", "push":
			return 8.0
		"fall":
			return 5.5
		_:
			if base.begins_with("attack"):
				return 16.0
			return 7.0


static func _add_anim(frames: SpriteFrames, anim_name: String, imgs: Array, speed: float, loop: bool) -> void:
	if frames.has_animation(anim_name):
		frames.clear(anim_name)
	else:
		frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for img in imgs:
		frames.add_frame(anim_name, ImageTexture.create_from_image(img))


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

	var body_top := base - 28
	_oval(img, cx, body_top + 10, 9, 14, fill, true)
	_oval(img, cx, body_top + 10, 9, 14, OUTLINE, false)

	var hy := body_top - 2
	if look > 0:
		hy -= 1
	elif look < 0:
		hy += 2
	_oval(img, cx, hy, 8, 8, fill, true)
	_oval(img, cx, hy, 8, 8, OUTLINE, false)
	_oval(img, cx - 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx + 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx - 4, hy - 7, 2, 3, OUTLINE, false)
	_oval(img, cx + 4, hy - 7, 2, 3, OUTLINE, false)
	var ey := hy - 1 + (1 if look < 0 else (-1 if look > 0 else 0))
	_oval(img, cx - 3, ey, 2, 2, EYE, true)
	_oval(img, cx + 3, ey, 2, 2, EYE, true)

	# Tight scuttle — legs stay under the cloak (1px lateral, small hop).
	var llx := cx - 3
	var lrx := cx + 3
	var lly := base - 2
	var lry := base - 2
	match leg:
		1:
			llx -= 1
			lly -= 1
			lry += 0
		2:
			lrx += 1
			lry -= 1
		3:
			llx -= 1
			lly -= 1
		4:
			lrx += 1
			lry -= 1
	if air:
		llx -= 1
		lrx += 1
		lly -= 1
		lry -= 2
	if running:
		# unused — run reuses walk frames
		pass
	_oval(img, llx, lly - 5, 2, 5, fill, true)
	_oval(img, lrx, lry - 5, 2, 5, fill, true)
	_oval(img, llx, lly - 5, 2, 5, OUTLINE, false)
	_oval(img, lrx, lry - 5, 2, 5, OUTLINE, false)

	var arm_x := cx + (8 if shove else 6)
	var arm_y := body_top + 8
	if slash > 0:
		_draw_weapon(img, cx, hy, look, slash)
	else:
		_oval(img, cx - 8, arm_y, 3, 5, fill, true)
		_oval(img, arm_x, arm_y + (-3 if look > 0 else (3 if look < 0 else 0)), 3, 5, fill, true)
		_oval(img, cx - 8, arm_y, 3, 5, OUTLINE, false)
		_oval(img, arm_x, arm_y + (-3 if look > 0 else (3 if look < 0 else 0)), 3, 5, OUTLINE, false)

	return img


static func _draw_fall(phase: int) -> Image:
	## Falling pose: same spirit body, arms slightly out/up (subtle, not frantic).
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := FILL
	var cx := 24
	var base := 54
	var body_top := base - 28
	_oval(img, cx, body_top + 10, 9, 14, fill, true)
	_oval(img, cx, body_top + 10, 9, 14, OUTLINE, false)
	var hy := body_top
	_oval(img, cx, hy, 8, 8, fill, true)
	_oval(img, cx, hy, 8, 8, OUTLINE, false)
	_oval(img, cx - 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx + 4, hy - 7, 2, 3, fill, true)
	_oval(img, cx - 4, hy - 7, 2, 3, OUTLINE, false)
	_oval(img, cx + 4, hy - 7, 2, 3, OUTLINE, false)
	_oval(img, cx - 3, hy - 1, 2, 2, EYE, true)
	_oval(img, cx + 3, hy - 1, 2, 2, EYE, true)
	## Legs tucked a touch under the cloak.
	_oval(img, cx - 4, base - 8, 2, 5, fill, true)
	_oval(img, cx + 4, base - 9, 2, 5, fill, true)
	_oval(img, cx - 4, base - 8, 2, 5, OUTLINE, false)
	_oval(img, cx + 4, base - 9, 2, 5, OUTLINE, false)
	## Arms: mild outward + upward, alternate a couple pixels between frames.
	var lift := 2 + (phase % 2)
	var spread := 2 + (phase % 2)
	var ly := body_top + 5 - lift
	var ry := body_top + 6 - lift
	_oval(img, cx - 9 - spread, ly, 3, 5, fill, true)
	_oval(img, cx + 9 + spread, ry, 3, 5, fill, true)
	_oval(img, cx - 9 - spread, ly, 3, 5, OUTLINE, false)
	_oval(img, cx + 9 + spread, ry, 3, 5, OUTLINE, false)
	return img


static func _draw_weapon(img: Image, cx: int, hy: int, look: int, phase: int) -> void:
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


static func _draw_pull(phase: int) -> Image:
	## Stand beside crate: lean, both arms stretched back toward the box.
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var lean := -2 - (phase % 2)
	var cx := 24 + lean
	var base := 52
	var body_top := base - 28
	_oval(img, cx, body_top + 10, 9, 14, FILL, true)
	_oval(img, cx, body_top + 10, 9, 14, OUTLINE, false)
	var hy := body_top - 1
	_oval(img, cx, hy, 8, 8, FILL, true)
	_oval(img, cx, hy, 8, 8, OUTLINE, false)
	_oval(img, cx - 3, hy - 1, 2, 2, EYE, true)
	_oval(img, cx + 3, hy - 1, 2, 2, EYE, true)
	# Legs planted / tiny scuttle
	var ox := 1 if phase == 1 else (-1 if phase == 2 else 0)
	_oval(img, cx - 3 + ox, base - 7, 2, 5, FILL, true)
	_oval(img, cx + 3 - ox, base - 7, 2, 5, FILL, true)
	_oval(img, cx - 3 + ox, base - 7, 2, 5, OUTLINE, false)
	_oval(img, cx + 3 - ox, base - 7, 2, 5, OUTLINE, false)
	# Arms reaching BACK (toward crate behind) — long stretch to the left of sprite
	var reach := 10 + phase
	_line_thick(img, Vector2(cx - 2, body_top + 8), Vector2(cx - reach, body_top + 10 + phase), FILL, 2)
	_line_thick(img, Vector2(cx + 1, body_top + 9), Vector2(cx - reach + 2, body_top + 12), FILL, 2)
	_line_thick(img, Vector2(cx - 2, body_top + 8), Vector2(cx - reach, body_top + 10 + phase), OUTLINE, 1)
	_oval(img, cx - reach, body_top + 10 + phase, 2, 2, FILL, true)
	return img


static func _draw_crouch(leg: int) -> Image:
	## Squash in place — feet stay at same baseline as standing (base 52).
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := 24
	var base := 52
	# Wider, shorter body (squish), feet at base.
	_oval(img, cx, base - 12, 12, 9, FILL, true)
	_oval(img, cx, base - 12, 12, 9, OUTLINE, false)
	_oval(img, cx, base - 22, 8, 6, FILL, true)
	_oval(img, cx, base - 22, 8, 6, OUTLINE, false)
	_oval(img, cx - 3, base - 23, 2, 2, EYE, true)
	_oval(img, cx + 3, base - 23, 2, 2, EYE, true)
	var ox := 1 if leg == 1 else (-1 if leg == 2 else 0)
	_oval(img, cx - 4 + ox, base - 3, 3, 3, FILL, true)
	_oval(img, cx + 4 - ox, base - 3, 3, 3, FILL, true)
	_oval(img, cx - 4 + ox, base - 3, 3, 3, OUTLINE, false)
	_oval(img, cx + 4 - ox, base - 3, 3, 3, OUTLINE, false)
	return img


static func _with_dissipate(src: Image, mode: String, phase: int) -> Image:
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i.ZERO)
	var col := SHADE_WISP if mode == "shade" else BURN_WISP
	# Head top ~ y 20–24 in 48x64 canvas; wisps rise and fade by phase.
	var hx := 24
	var hy := 20
	for i in 3:
		var rise := 3 + phase * 2 + i * 3
		var spread := (i - 1) * (1 + phase % 2)
		var rx := 2 + (2 - i)
		var ry := 3 + i
		var alpha := clampf(0.85 - float(phase) * 0.18 - float(i) * 0.2, 0.15, 0.9)
		var c := Color(col.r, col.g, col.b, alpha)
		_oval(img, hx + spread, hy - rise, rx, ry, c, true)
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
	if c.a < 1.0:
		var prev := img.get_pixel(x, y)
		var a := c.a
		img.set_pixel(x, y, Color(
			c.r * a + prev.r * (1.0 - a),
			c.g * a + prev.g * (1.0 - a),
			c.b * a + prev.b * (1.0 - a),
			minf(1.0, a + prev.a)
		))
	else:
		img.set_pixel(x, y, c)
