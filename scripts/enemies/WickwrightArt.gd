extends Node2D

## Procedural Wickwright boss art. The boss script drives the pose fields every frame.
## style 1 = Brass Owl Clock, 2 = Clockwork Moth, 3 = Grandfather Wraith.

const BRASS := Color(0.78, 0.6, 0.3)
const BRASS_DARK := Color(0.45, 0.32, 0.16)
const BRASS_HI := Color(0.98, 0.84, 0.5)
const IRON := Color(0.17, 0.15, 0.17)
const IRON_HI := Color(0.3, 0.27, 0.28)
const FACE := Color(0.9, 0.84, 0.66)
const INK := Color(0.12, 0.08, 0.06)
const EYE := Color(0.78, 0.45, 1.0)
const EYE_ANGRY := Color(1.0, 0.3, 0.2)
const HEART := Color(1.0, 0.55, 0.18)

var style: int = 1
## Pose fields (set by Wickwright).
var t: float = 0.0
var flap: float = 0.0 ## wing angle in radians; negative = raised
var look: Vector2 = Vector2.ZERO ## unit-ish direction toward the player
var heart: float = 0.0 ## 0 closed .. 1 fully open
var windup: float = 0.0 ## 0..1 eye flare before an attack
var hand_speed: float = 1.0
var damage: float = 0.0 ## 0..1 cracks and sparks as phases advance
var dying: bool = false


func _process(delta: float) -> void:
	if dying:
		t += delta ## boss physics is frozen during the defeat cutscene
	queue_redraw()


func _draw() -> void:
	match style:
		2:
			_draw_moth()
		3:
			_draw_grandfather()
		_:
			_draw_owl()


# ---------- Style 1: Brass Owl Clock ----------

func _draw_owl() -> void:
	## Pendulum tail behind the body.
	var sw := sin(t * 3.2) * 0.35
	var tail_end := Vector2(0, 34) + Vector2(sin(sw), cos(sw)) * 22.0
	draw_line(Vector2(0, 30), tail_end, BRASS_DARK, 3.0)
	_disc(tail_end, 6.0, BRASS, BRASS_DARK)
	for side in [-1.0, 1.0]:
		_owl_wing(side)
	## Body pod.
	_ellipse(Vector2(0, 6), Vector2(24, 31), BRASS_DARK)
	_ellipse(Vector2(0, 5), Vector2(21, 28), BRASS)
	_ellipse(Vector2(-6, -2), Vector2(8, 18), BRASS_HI * Color(1, 1, 1, 0.25))
	## Riveted belt.
	draw_rect(Rect2(-21, 2, 42, 6), BRASS_DARK)
	for i in 6:
		draw_circle(Vector2(-17.5 + i * 7.0, 5), 1.2, BRASS_HI)
	## Ear tufts.
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 8, -24), Vector2(side * 20, -40), Vector2(side * 17, -20)]), BRASS_DARK)
	## Furnace heart grate.
	_heart_window(Vector2(0, 19), 8.0)
	## Clock face with the eye lens.
	_clock_face(Vector2(0, -12), 15.0)
	_eye(Vector2(0, -12), 5.5)
	_damage_marks(Vector2(0, 5), 20.0)


func _owl_wing(side: float) -> void:
	var sh := Vector2(side * 15, -10)
	var a := flap * side
	var tips := [Vector2(54, -46), Vector2(72, -22), Vector2(70, 4), Vector2(52, 24)]
	var pts := PackedVector2Array([sh])
	for i in tips.size():
		var tip: Vector2 = tips[i]
		pts.append(sh + Vector2(tip.x * side, tip.y).rotated(a))
		if i < tips.size() - 1:
			var nxt: Vector2 = tips[i + 1]
			var mid: Vector2 = (tip + nxt) * 0.5 * 0.82
			pts.append(sh + Vector2(mid.x * side, mid.y).rotated(a))
	draw_colored_polygon(pts, Color(0.25, 0.14, 0.1, 0.92))
	for tip in tips:
		var p: Vector2 = sh + Vector2(tip.x * side, tip.y).rotated(a)
		draw_line(sh, p, BRASS_DARK, 4.0)
		draw_line(sh, p, BRASS, 2.0)
		draw_circle(p, 2.2, BRASS_HI)
	_gear(sh, 7.0, BRASS_DARK, t * 2.0 * side)


# ---------- Style 2: Clockwork Moth ----------

func _draw_moth() -> void:
	for side in [-1.0, 1.0]:
		_moth_wing(side)
	## Abdomen segments, lantern glass in the middle.
	for i in 4:
		var y := 12.0 + i * 8.0
		var w := 14.0 - i * 2.6
		var wob := sin(t * 3.0 + i) * 1.5
		if i == 1:
			_heart_lantern(Vector2(wob, y), Vector2(w, 6.0))
		else:
			_ellipse(Vector2(wob, y), Vector2(w, 5.0), IRON)
			draw_arc(Vector2(wob, y), w, PI * 0.15, PI * 0.85, 10, BRASS_DARK, 1.5)
	## Thorax with fur collar.
	_ellipse(Vector2(0, -2), Vector2(15, 12), IRON)
	for i in 9:
		var ang := PI + PI * float(i) / 8.0
		draw_line(Vector2(0, -4) + Vector2(cos(ang), sin(ang)) * 11.0,
			Vector2(0, -4) + Vector2(cos(ang), sin(ang)) * 17.0, Color(0.55, 0.48, 0.42), 2.0)
	## Antennae as clock hands.
	for side in [-1.0, 1.0]:
		var base := Vector2(side * 5, -30)
		var tip := base + Vector2(side * 14, -18).rotated(sin(t * 2.4 + side) * 0.15)
		draw_line(base, tip, BRASS, 2.0)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -5), tip + Vector2(3, 0),
			tip + Vector2(0, 4), tip + Vector2(-3, 0)]), BRASS_HI)
	_clock_face(Vector2(0, -20), 13.0)
	_eye(Vector2(0, -20), 5.0)
	_damage_marks(Vector2(0, -2), 14.0)


func _moth_wing(side: float) -> void:
	var sh := Vector2(side * 10, -6)
	var a := flap * side
	var upper := [Vector2(0, 0), Vector2(26, -44), Vector2(66, -42), Vector2(74, -12), Vector2(10, 2)]
	var lower := [Vector2(0, 4), Vector2(50, 8), Vector2(54, 30), Vector2(26, 40)]
	for shape in [upper, lower]:
		var pts := PackedVector2Array()
		for p in shape:
			pts.append(sh + Vector2(p.x * side, p.y).rotated(a))
		var glass := Color(0.95, 0.62, 0.25, 0.5) if shape == upper else Color(0.35, 0.75, 0.75, 0.45)
		draw_colored_polygon(pts, glass)
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, BRASS_DARK, 3.0)
		draw_polyline(loop, BRASS, 1.5)
		## Leading mullions.
		var c: Vector2 = pts[0]
		for i in range(2, pts.size() - 1):
			draw_line(c, pts[i], BRASS_DARK, 1.5)
	## Eye spot on the upper pane.
	var spot := sh + Vector2(46 * side, -26).rotated(a)
	draw_circle(spot, 6.0, BRASS_DARK)
	draw_circle(spot, 3.5, EYE.lerp(EYE_ANGRY, windup))


# ---------- Style 3: Grandfather Wraith ----------

const WOOD := Color(0.3, 0.14, 0.08)
const WOOD_DARK := Color(0.16, 0.07, 0.05)
const WOOD_HI := Color(0.46, 0.24, 0.12)
const CLOTH := Color(0.16, 0.08, 0.2, 0.94)
const CLOTH_EDGE := Color(0.42, 0.24, 0.5)


func _draw_grandfather() -> void:
	for side in [-1.0, 1.0]:
		_cloth_wing(side, true)
	for side in [-1.0, 1.0]:
		_cloth_wing(side, false)
	## Ghostly wisp trailing under the case.
	for i in 3:
		var ph := fmod(t * 0.8 + i * 0.33, 1.0)
		draw_circle(Vector2(sin(t * 2.0 + i * 2.0) * 4.0, 50.0 + ph * 18.0), 7.0 * (1.0 - ph), Color(0.4, 0.2, 0.5, 0.25 * (1.0 - ph)))
	## Plinth with brass claw feet.
	_wood_block(PackedVector2Array([Vector2(-18, 32), Vector2(18, 32), Vector2(20, 44), Vector2(-20, 44)]))
	draw_line(Vector2(-18, 33), Vector2(18, 33), BRASS, 2.0)
	for side in [-1.0, 1.0]:
		_disc(Vector2(side * 16, 46), 3.0, BRASS, BRASS_DARK)
		draw_line(Vector2(side * 16, 46), Vector2(side * 21, 49), BRASS_DARK, 2.0)
	## Trunk, slightly waisted.
	_wood_block(PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(12, 32), Vector2(-12, 32)]))
	for gx in [-8.0, 9.0]:
		draw_line(Vector2(gx, 0), Vector2(gx * 0.9, 30), WOOD_HI * Color(1, 1, 1, 0.35), 1.0)
	## Arched glass door: pendulum (the heart) and two weights.
	var door := PackedVector2Array()
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		door.append(Vector2(0, 6) + Vector2(cos(a) * 8.0, sin(a) * 6.0))
	door.append(Vector2(8, 28))
	door.append(Vector2(-8, 28))
	draw_colored_polygon(door, Color(0.05, 0.03, 0.06))
	for wx in [-5.0, 5.0]:
		var wy := 14.0 + sin(t * (1.1 if wx < 0 else 0.8)) * 3.0
		draw_line(Vector2(wx, 2), Vector2(wx, wy), BRASS_DARK, 1.0)
		draw_rect(Rect2(wx - 1.5, wy, 3, 7), BRASS)
	var sw := sin(t * 3.4) * 0.38
	var bob := Vector2(0, 2) + Vector2(sin(sw), cos(sw)) * 21.0
	draw_line(Vector2(0, 2), bob, BRASS_HI, 1.5)
	_glow(bob, 6.0 + heart * 12.0, 0.25 + heart * 1.6)
	_disc(bob, 4.5, BRASS.lerp(HEART, 0.3 + heart * 0.7), BRASS_DARK)
	if heart > 0.05:
		draw_circle(bob, 2.5 * heart, Color(1.0, 0.95, 0.7, heart))
	var door_loop := door.duplicate()
	door_loop.append(door[0])
	draw_polyline(door_loop, BRASS, 1.5)
	draw_line(Vector2(-6, 4), Vector2(-2, 22), Color(1, 1, 1, 0.12), 1.5) ## glass glint
	## Hood: brass pillars, swan-neck pediment and spinning gear finial.
	_wood_block(PackedVector2Array([Vector2(-20, -6), Vector2(20, -6), Vector2(20, -40), Vector2(-20, -40)]))
	draw_rect(Rect2(-22, -8, 44, 4), BRASS_DARK)
	draw_line(Vector2(-22, -7), Vector2(22, -7), BRASS, 1.5)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * 18 - 1.5, -38, 3, 30), BRASS)
		draw_rect(Rect2(side * 18 - 2.5, -40, 5, 3), BRASS_HI)
		## Scroll of the broken pediment.
		var scroll := PackedVector2Array()
		for i in 7:
			var u := float(i) / 6.0
			scroll.append(Vector2(side * (21.0 - u * 15.0), -41.0 - sin(u * PI * 0.9) * 10.0 + u * 2.0))
		draw_polyline(scroll, WOOD_DARK, 5.0)
		draw_polyline(scroll, WOOD_HI, 2.0)
		_disc(scroll[scroll.size() - 1], 2.0, BRASS, BRASS_DARK)
	_gear(Vector2(0, -51), 6.0, BRASS, t * 1.5 * hand_speed)
	draw_circle(Vector2(0, -51), 1.5, BRASS_DARK)
	## Moon-phase arch over the dial.
	draw_circle(Vector2(0, -32), 8.0, Color(0.12, 0.14, 0.3))
	draw_arc(Vector2(0, -32), 8.0, PI, TAU, 12, BRASS, 1.5)
	var moon := Vector2(0, -32) + Vector2(cos(t * 0.5 - PI * 0.5), sin(t * 0.5 - PI * 0.5)) * 4.5
	draw_circle(moon, 2.5, FACE)
	draw_circle(Vector2(-4, -35), 0.8, Color(1, 1, 0.8, 0.8))
	draw_circle(Vector2(5, -36), 0.6, Color(1, 1, 0.8, 0.8))
	_clock_face(Vector2(0, -17), 11.0)
	_eye(Vector2(0, -17), 4.5)
	_damage_marks(Vector2(0, 12), 13.0)


func _wood_block(pts: PackedVector2Array) -> void:
	draw_colored_polygon(pts, WOOD)
	## Left bevel lit, right bevel shaded.
	draw_line(pts[0], pts[pts.size() - 1], WOOD_HI, 2.0)
	draw_line(pts[1], pts[2], WOOD_DARK, 2.0)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, WOOD_DARK, 1.0)


func _cloth_wing(side: float, back: bool) -> void:
	var sh := Vector2(side * 17, -20)
	var a := flap * side * (0.8 if back else 1.0) + (-0.25 * side if back else 0.0)
	var span := 0.85 if back else 1.0
	var knuckles := [Vector2(34, -40), Vector2(62, -26), Vector2(72, -2), Vector2(62, 22), Vector2(40, 36)]
	var pts := PackedVector2Array([sh])
	var edge := PackedVector2Array()
	for i in knuckles.size():
		var k: Vector2 = knuckles[i] * span
		var p := sh + Vector2(k.x * side, k.y).rotated(a)
		pts.append(p)
		edge.append(p)
		if i < knuckles.size() - 1:
			var nxt: Vector2 = knuckles[i + 1] * span
			## Ragged scallop with a flutter.
			for j in [0.3, 0.7]:
				var m: Vector2 = k.lerp(nxt, j) * (0.72 + 0.08 * sin(t * 7.0 + i * 1.7 + j * 4.0))
				var q := sh + Vector2(m.x * side, m.y).rotated(a)
				pts.append(q)
				edge.append(q)
	pts.append(sh + Vector2(8 * side, 34).rotated(a))
	if back:
		draw_colored_polygon(pts, Color(0.08, 0.04, 0.1, 0.85))
		return
	draw_colored_polygon(pts, CLOTH)
	draw_polyline(edge, CLOTH_EDGE, 1.5)
	for k in knuckles:
		var p: Vector2 = sh + Vector2(k.x * side, k.y).rotated(a)
		var d := (p - sh).normalized()
		draw_line(sh, p, BRASS_DARK, 3.0)
		draw_line(sh, p, BRASS, 1.2)
		## Ornate hour-hand tip: ring then spade.
		var ring := p - d * 7.0
		draw_arc(ring, 2.5, 0.0, TAU, 10, BRASS_HI, 1.2)
		draw_colored_polygon(PackedVector2Array([p + d * 6.0, p + d.orthogonal() * 3.0, p - d * 2.0,
			p - d.orthogonal() * 3.0]), BRASS_HI)
	_gear(sh, 5.0, BRASS_DARK, -t * 2.0 * side)


# ---------- Shared pieces ----------

func _clock_face(c: Vector2, r: float) -> void:
	draw_circle(c, r + 3.0, BRASS_DARK)
	draw_circle(c, r + 1.5, BRASS)
	draw_circle(c, r, FACE)
	for i in 12:
		var ang := TAU * float(i) / 12.0
		var d := Vector2(cos(ang), sin(ang))
		draw_line(c + d * (r - (3.5 if i % 3 == 0 else 2.0)), c + d * (r - 0.5), INK, 1.5 if i % 3 == 0 else 1.0)
	var spin := t * hand_speed * (6.0 if dying else 1.0)
	var hr := spin * 0.6 - PI * 0.5
	var mn := spin * 3.0 - PI * 0.5
	draw_line(c, c + Vector2(cos(hr), sin(hr)) * r * 0.5, INK, 2.0)
	draw_line(c, c + Vector2(cos(mn), sin(mn)) * r * 0.82, INK, 1.2)


func _eye(c: Vector2, r: float) -> void:
	draw_circle(c, r + 1.5, BRASS_DARK)
	draw_circle(c, r, Color(0.08, 0.05, 0.1))
	var col := EYE.lerp(EYE_ANGRY, windup)
	if dying:
		col = col.darkened(0.6)
	_glow(c + look * 1.5, r * 0.9, 0.6 + windup * 0.4, col)
	draw_circle(c + look * 1.8, r * 0.55, col)
	draw_circle(c + look * 1.8 + Vector2(-1, -1), r * 0.18, Color(1, 1, 1, 0.8))


func _heart_window(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, Color(0.12, 0.06, 0.04))
	var pulse := 1.0 + sin(t * 9.0) * 0.15 * heart
	_glow(c, r * (0.9 + heart * 1.6) * pulse, 0.15 + heart * 1.6)
	draw_colored_polygon(pts, HEART * Color(1, 1, 1, 0.2 + heart * 0.8))
	if heart > 0.05:
		draw_circle(c, r * 0.45 * heart * pulse, Color(1.0, 0.92, 0.6, heart))
	## Grate bars slide open as the heart opens.
	if heart < 0.95:
		for i in 3:
			var x := (-r * 0.5 + i * r * 0.5) * (1.0 - heart) + c.x
			draw_line(Vector2(x, c.y - r * 0.8), Vector2(x, c.y + r * 0.8), BRASS_DARK, 2.0)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, BRASS_HI, 1.5)


func _heart_lantern(c: Vector2, half: Vector2) -> void:
	_ellipse(c, half + Vector2(2, 2), BRASS_DARK)
	_glow(c, half.x * (1.0 + heart * 1.5), 0.15 + heart * 1.6)
	_ellipse(c, half, HEART * Color(1, 1, 1, 0.25 + heart * 0.75))
	for i in 3:
		draw_line(c + Vector2(-half.x + 4 + i * (half.x - 4), -half.y), c + Vector2(-half.x + 4 + i * (half.x - 4), half.y), BRASS_DARK, 1.2)


func _damage_marks(c: Vector2, r: float) -> void:
	if damage <= 0.0:
		return
	var n := int(damage * 4.0) + 1
	for i in n:
		var a := 0.7 + i * 1.6
		var p0 := c + Vector2(cos(a), sin(a)) * r * 0.3
		var p1 := c + Vector2(cos(a + 0.3), sin(a + 0.3)) * r * 0.7
		var p2 := c + Vector2(cos(a - 0.1), sin(a - 0.1)) * r
		draw_polyline(PackedVector2Array([p0, p1, p2]), INK, 1.2)
	## Loose sparks once badly damaged.
	if damage > 0.5:
		for i in 3:
			var ph := fmod(t * 1.7 + i * 0.33, 1.0)
			var sp := c + Vector2((i - 1) * 10.0, -6.0 - ph * 26.0)
			draw_circle(sp, 1.4 * (1.0 - ph), BRASS_HI * Color(1, 1, 1, 1.0 - ph))


func _glow(c: Vector2, r: float, strength: float, col: Color = HEART) -> void:
	if strength <= 0.0:
		return
	for i in 4:
		draw_circle(c, r * (1.0 + i * 0.6), Color(col.r, col.g, col.b, 0.12 * strength / (1.0 + i)))


func _disc(c: Vector2, r: float, fill: Color, rim: Color) -> void:
	draw_circle(c, r + 1.5, rim)
	draw_circle(c, r, fill)


func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
	draw_colored_polygon(pts, col)


func _gear(c: Vector2, r: float, col: Color, rot: float) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := rot + TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.72))
	draw_colored_polygon(pts, col)
	draw_circle(c, r * 0.35, BRASS_HI)
