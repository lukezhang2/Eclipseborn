extends Node2D
## Gear-shift currency art (white). style 1 Pearl, 2 Spoked, 3 Moonlit, 4 Ghost, 5 Pearl + ghost core.

var style: int = 1
var t: float = 0.0
var spin: float = 0.0
var fade: float = 1.0
## UI icon mode: no bob (HUD, shop, backpack).
var still: bool = false


func _ready() -> void:
	t = randf() * 10.0 ## so neighbouring gears don't bob and glint in sync


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


## Slightly smaller than the old flat gear (r 11).
const SIZE := 0.95
const WHITE := Color(0.95, 0.96, 0.99)
const SHADE := Color(0.66, 0.7, 0.78)
const EDGE := Color(0.36, 0.38, 0.46)


func _draw() -> void:
	var c := Vector2.ZERO if still else Vector2(0, sin(t * 3.0) * 1.5 - 2.0)
	draw_set_transform(c, 0.0, Vector2(SIZE, SIZE))
	match style:
		2:
			_draw_spoked()
		3:
			_draw_moon()
		4:
			_draw_ghost()
		5:
			_draw_pearl_core()
		_:
			_draw_pearl()
	draw_set_transform(Vector2.ZERO)


## E: clean white gear, top-lit bevel, small dark axle.
func _draw_pearl() -> void:
	var c := Vector2.ZERO
	_halo(c, 9.0, Color(1, 1, 1), 0.3)
	_gear(c, 10.0, 7.6, 10, spin, EDGE)
	_gear(c, 9.0, 6.8, 10, spin, SHADE)
	_gear(c + Vector2(-0.5, -0.7), 8.3, 6.2, 10, spin, WHITE)
	draw_arc(c, 4.6, PI * 0.1, PI * 0.9, 8, SHADE, 1.4)
	draw_circle(c, 2.2, EDGE)
	_sparkle(c + Vector2(-5, -5), 0.0)


## F: white rim with five spokes and open windows.
func _draw_spoked() -> void:
	var c := Vector2.ZERO
	_halo(c, 9.5, Color(0.9, 0.95, 1.0), 0.35)
	_gear(c, 10.0, 7.6, 12, spin, EDGE)
	_gear(c, 9.0, 6.9, 12, spin, WHITE)
	draw_circle(c, 6.2, Color(0.2, 0.2, 0.26))
	for i in 5:
		var a := spin + TAU * float(i) / 5.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * 6.4, WHITE, 1.8)
	draw_circle(c, 2.6, WHITE)
	draw_circle(c, 1.0, EDGE)
	draw_arc(c, 8.4, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1), 1.2)
	_sparkle(c + Vector2(5, -6), 0.4)


## G: white gear with a pale moonlit-blue inner ring.
func _draw_moon() -> void:
	var c := Vector2.ZERO
	_halo(c, 10.0, Color(0.7, 0.85, 1.0), 0.35)
	_gear(c, 10.0, 7.6, 9, spin, EDGE)
	_gear(c, 9.0, 6.9, 9, spin, WHITE)
	draw_circle(c, 6.0, Color(0.72, 0.84, 0.98))
	draw_circle(c, 4.4, WHITE)
	## Crescent cut into the hub.
	draw_circle(c + Vector2(1.6, -0.8), 3.4, Color(0.72, 0.84, 0.98))
	_sparkle(c + Vector2(-5, -6), 0.7)


## E+H: pearl body with the ghost gear's pulsing light core.
func _draw_pearl_core() -> void:
	var c := Vector2.ZERO
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	_halo(c, 9.5 + pulse * 1.5, Color(1, 1, 1), 0.4)
	_gear(c, 10.0, 7.6, 10, spin, EDGE)
	_gear(c, 9.0, 6.8, 10, spin, SHADE)
	_gear(c + Vector2(-0.5, -0.7), 8.3, 6.2, 10, spin, WHITE)
	draw_arc(c, 4.6, PI * 0.1, PI * 0.9, 8, SHADE, 1.4)
	draw_circle(c, 3.6, Color(1, 1, 1, 0.3))
	draw_circle(c, 2.2 + pulse * 0.7, Color(1, 1, 1, 0.95))
	_sparkle(c + Vector2(-5, -5), 0.0)


## H: soft ghostly gear, white outline with a pulsing light core.
func _draw_ghost() -> void:
	var c := Vector2.ZERO
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	_halo(c, 10.0 + pulse * 2.0, Color(1, 1, 1), 0.5)
	_gear(c, 10.0, 7.6, 10, spin, Color(1, 1, 1, 0.95))
	_gear(c, 8.6, 6.4, 10, spin, Color(0.55, 0.6, 0.72, 0.55))
	draw_circle(c, 5.4, Color(1, 1, 1, 0.25))
	draw_circle(c, 3.0 + pulse * 0.8, Color(1, 1, 1, 0.95))
	_sparkle(c + Vector2(5, -5), 0.2)


func _gear(c: Vector2, r_out: float, r_in: float, teeth: int, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in teeth:
		var a := rot + TAU * float(i) / float(teeth)
		var w := TAU / float(teeth)
		pts.append(c + Vector2(cos(a - w * 0.3), sin(a - w * 0.3)) * r_in)
		pts.append(c + Vector2(cos(a - w * 0.18), sin(a - w * 0.18)) * r_out)
		pts.append(c + Vector2(cos(a + w * 0.18), sin(a + w * 0.18)) * r_out)
		pts.append(c + Vector2(cos(a + w * 0.3), sin(a + w * 0.3)) * r_in)
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, col.a * fade))


func _halo(c: Vector2, r: float, col: Color, strength: float) -> void:
	for i in 3:
		draw_circle(c, r * (1.0 + i * 0.45), Color(col.r, col.g, col.b, strength * fade * 0.18 / (1.0 + i)))


## Brief 4-point glint every ~1.6s.
func _sparkle(p: Vector2, phase: float) -> void:
	var k := fmod(t * 0.62 + phase, 1.0)
	if k > 0.18:
		return
	var s := sin(k / 0.18 * PI) * 4.0
	var col := Color(1, 1, 0.95, 0.95 * fade)
	draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), col, 1.0)
	draw_line(p + Vector2(0, -s), p + Vector2(0, s), col, 1.0)
