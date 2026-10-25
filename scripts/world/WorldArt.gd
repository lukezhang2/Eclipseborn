extends Node2D
class_name WorldArt
## Procedural steampunk art for world props (visual only: no collision, no light).
## Three style options per kind while we choose. Origins match the props they dress:
##   PLATFORM / CRATE: centered on `size`.  HOUSE / CHECKPOINT: bottom-center.  LANTERN: lamp body center.

enum Kind { PLATFORM, CRATE, HOUSE, CHECKPOINT, LANTERN, POT, HATCH, BACKDROP, LEVER, WINDOW, BENCH, VALVE, VENT, CHAIN }

@export var kind: Kind = Kind.PLATFORM
@export var style: int = 0
@export var size: Vector2 = Vector2(140, 20)
## Levers: handle up/down. Lanterns and checkpoints: lit (true) or dimmed (false).
@export var on: bool = true
## Steam vents: draw stand-in puffs (option previews only; the game uses particle steam).
@export var steam_preview: bool = false
## Lanterns: glass/glow colour (warm by default; moon lamps pass a pale blue).
@export var tint: Color = Color("f0b45a")

const COAL := Color("0d0b0c")
const IRON := Color("24211f")
const IRON_MID := Color("37322e")
const IRON_HI := Color("4f4842")
const RUST := Color("6b3b24")
const BRASS := Color("b08d57")
const BRASS_HI := Color("e0c07f")
const BRASS_LO := Color("6e5530")
const LAMP := Color("f0b45a")
const LAMP_CORE := Color("ffe2a3")
const EMBER := Color("c2412d")
const INK := Color("6b4c9a")
const INK_HI := Color("b8a3e0")
const WOOD := Color("5a3e26")
const WOOD_HI := Color("7a5634")
const WOOD_LO := Color("3a2717")
const BRICK := Color("4a2a22")
const BRICK_HI := Color("5e362a")
const SLATE := Color("2b3438")
# Teal-slate stone from the reference art
const STONE := Color("2b3d42")
const STONE_HI := Color("44595c")
const STONE_LO := Color("1a2629")

var _t: float = 0.0


## Distance straight down from `n` to the first solid (layer 1) surface, or -1 if none in range.
static func floor_distance(n: Node2D, max_dist: float = 80.0) -> float:
	return _ray_distance(n, Vector2(0, max_dist))


## Distance straight up from `n` (offset by `start`) to the ceiling, or -1 if none in range.
static func ceiling_distance(n: Node2D, start: Vector2, max_dist: float = 500.0) -> float:
	return _ray_distance(n, Vector2(0, -max_dist), start)


## Light-blocking outline of a drawn house (bottom-center origin): the walls plus the roof
## above them. Eaves and the C1 jetty are left out on purpose, so light reaches all the way to
## the walls instead of leaving a shadow strip under each overhang (the overhang art covers the
## wash there anyway). Always convex. Matches _house / _house_timber.
static func house_silhouette(house_style: int, w: float, h: float) -> PackedVector2Array:
	# Tucked 1.5px inside the walls: wash rays stop just short of what they hit, so without the
	# inset a hairline of shadow shows between the light and the wall.
	var hx := w * 0.5 - 1.5
	match house_style:
		6:
			# Jettied two-storey: roof triangle (±(hx+16) at -1.15h, apex -1.6h) clipped to the walls.
			var eave := -h * 1.15 - h * 0.45 * (16.0 / (hx + 16.0))
			return PackedVector2Array([Vector2(-hx, 4), Vector2(hx, 4), Vector2(hx, eave),
				Vector2(0, -h * 1.6), Vector2(-hx, eave)])
		9:
			# Clockmaker: roof triangle (±(hx+12) at -h, apex -h-46) clipped to the walls.
			var eave := -h - 46.0 * (12.0 / (hx + 12.0))
			return PackedVector2Array([Vector2(-hx, 4), Vector2(hx, 4), Vector2(hx, eave),
				Vector2(0, -h - 46.0), Vector2(-hx, eave)])
		_:
			# Timber workshop (C) and fallback: roof trapezoid (±(hx+12) at -h, ±0.6hx at -h-34).
			var eave := -h - 34.0 * (12.0 / (hx * 0.4 + 12.0))
			return PackedVector2Array([Vector2(-hx, 4), Vector2(hx, 4), Vector2(hx, eave),
				Vector2(hx * 0.6, -h - 34.0), Vector2(-hx * 0.6, -h - 34.0), Vector2(-hx, eave)])


static func _ray_distance(n: Node2D, dir: Vector2, start: Vector2 = Vector2.ZERO) -> float:
	var from := n.global_position + start
	var q := PhysicsRayQueryParameters2D.create(from, from + dir, 1)
	var hit := n.get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return -1.0
	return absf((hit.position as Vector2).y - from.y)


func _process(delta: float) -> void:
	# Only things with flames or glow animate.
	if kind in [Kind.LANTERN, Kind.CHECKPOINT, Kind.POT, Kind.BACKDROP, Kind.WINDOW, Kind.VENT]:
		_t += delta
		queue_redraw()


func _draw() -> void:
	# Styles 0-2: first round of options, 3-5: second round, 6+: third round.
	var more := style >= 3
	match kind:
		Kind.PLATFORM:
			if more: _platform_more()
			else: _platform()
		Kind.CRATE:
			if style == 9: _crate_pine_planks()
			elif style >= 6: _crate_wood_x()
			elif more: _crate_more()
			else: _crate()
		Kind.HOUSE:
			if style >= 6: _house_timber()
			elif more: _house_more()
			else: _house()
		Kind.CHECKPOINT:
			if style >= 6: _checkpoint_twin_posts()
			elif more: _checkpoint_more()
			else: _checkpoint()
		Kind.LANTERN: _lantern()
		Kind.POT:
			if style == 14: _pot_clay_jar()
			elif style >= 8: _pot_third()
			elif style >= 4: _pot_more()
			else: _pot()
		Kind.HATCH:
			if style >= 12: _hatch_brass_doors_plain()
			elif style >= 7: _hatch_third()
			elif style >= 3: _hatch_more()
			else: _hatch()
		Kind.BACKDROP: _backdrop()
		Kind.LEVER: _lever()
		Kind.WINDOW:
			if style == 10: _window_dark_arch()
			elif style >= 4: _window_arched()
			else: _window_art()
		Kind.BENCH: _bench()
		Kind.VALVE: _valve()
		Kind.VENT: _vent()
		Kind.CHAIN: _chain()


# ---------------- PLATFORMS ----------------

func _platform() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		0:
			# Riveted girder: iron slab, bright top lip, brass rivets, truss underneath.
			_rect(r, IRON)
			_rect(Rect2(r.position, Vector2(w, 4)), IRON_HI)
			_rect(Rect2(r.position + Vector2(0, h - 3), Vector2(w, 3)), COAL)
			var x := r.position.x + 10.0
			while x < r.end.x - 6.0:
				_rivet(Vector2(x, r.position.y + h * 0.55), 2.2)
				x += 22.0
			var under := r.end.y
			var step := 28.0
			var sx := r.position.x + 6.0
			while sx + step <= r.end.x - 6.0:
				draw_line(Vector2(sx, under), Vector2(sx + step * 0.5, under + 10), IRON_MID, 3.0)
				draw_line(Vector2(sx + step * 0.5, under + 10), Vector2(sx + step, under), IRON_MID, 3.0)
				sx += step
			draw_line(Vector2(r.position.x + 6, under + 10), Vector2(r.end.x - 6, under + 10), IRON_MID, 2.0)
		1:
			# Grated stone catwalk (reference art): chunky teal-slate blocks, grate inset, bevelled caps.
			_rect(r, STONE)
			_rect(Rect2(r.position, Vector2(w, 5)), STONE_HI)
			_rect(Rect2(r.position + Vector2(0, h - 4), Vector2(w, 4)), STONE_LO)
			var block := 46.0
			var bx := r.position.x
			while bx < r.end.x - 1.0:
				draw_line(Vector2(bx, r.position.y), Vector2(bx, r.end.y), STONE_LO, 2.0)
				bx += block
			var g := r.grow_individual(-10, -6, -10, -6)
			if g.size.y >= 4.0:
				_rect(g, COAL)
				var gx := g.position.x + 3.0
				while gx < g.end.x:
					draw_line(Vector2(gx, g.position.y), Vector2(gx, g.end.y), STONE_LO, 1.0)
					gx += 5.0
			# Caps sticking out at the ends
			_rect(Rect2(r.position.x - 4, r.position.y - 3, 14, h + 6), STONE_HI)
			_rect(Rect2(r.end.x - 10, r.position.y - 3, 14, h + 6), STONE_HI)
			_rect(Rect2(r.position.x - 4, r.end.y + 1, 14, 2), STONE_LO)
			_rect(Rect2(r.end.x - 10, r.end.y + 1, 14, 2), STONE_LO)
		2:
			# Brass-trimmed steam plate: dark plate, brass rail, a pipe and gear teeth below.
			_rect(r, IRON_MID)
			_rect(Rect2(r.position, Vector2(w, 3)), BRASS_HI)
			_rect(Rect2(r.position + Vector2(0, 3), Vector2(w, 2)), BRASS_LO)
			var px := r.position.x + 30.0
			while px < r.end.x - 20.0:
				draw_line(Vector2(px, r.position.y + 6), Vector2(px, r.end.y - 2), IRON, 2.0)
				px += 40.0
			var pipe_y := r.end.y + 4.0
			draw_line(Vector2(r.position.x + 8, pipe_y), Vector2(r.end.x - 8, pipe_y), RUST, 5.0)
			draw_line(Vector2(r.position.x + 8, pipe_y - 1.5), Vector2(r.end.x - 8, pipe_y - 1.5), Color(RUST.lightened(0.25)), 1.0)
			var tx := r.position.x + 6.0
			while tx < r.end.x - 6.0:
				_rect(Rect2(tx, r.end.y, 6, 3), IRON)
				tx += 12.0
			_rivet(Vector2(r.position.x + 6, r.position.y + h * 0.6), 2.5)
			_rivet(Vector2(r.end.x - 6, r.position.y + h * 0.6), 2.5)


# ---------------- CRATES ----------------

func _crate() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		0:
			# Iron-banded wood: planks, iron bands top and bottom, corner brackets.
			_rect(r, WOOD)
			var y := r.position.y + 2
			var i := 0
			while y < r.end.y:
				_rect(Rect2(r.position.x, y, w, h / 5.0 - 1), WOOD_HI if i % 2 == 0 else WOOD)
				y += h / 5.0
				i += 1
			_rect(Rect2(r.position.x, r.position.y + h * 0.18, w, 5), IRON_MID)
			_rect(Rect2(r.position.x, r.end.y - h * 0.18 - 5, w, 5), IRON_MID)
			for c in _corners(r, 0):
				_bracket(c, r)
			_outline(r, COAL, 2.0)
		1:
			# Riveted steel crate with an X brace.
			_rect(r, IRON_MID)
			var inner := r.grow(-6)
			_rect(inner, IRON)
			draw_line(inner.position, inner.end, IRON_HI, 4.0)
			draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), IRON_HI, 4.0)
			_outline(inner, COAL, 1.0)
			for c in _corners(r, 4):
				_rivet(c, 2.2)
			_rect(Rect2(r.position, Vector2(w, 2)), IRON_HI)
			_outline(r, COAL, 2.0)
		2:
			# Brass-cornered cargo box: wood, diagonal brace, stencil stripe, brass corners.
			_rect(r, WOOD_HI)
			var frame := r.grow(-5)
			_rect(frame, WOOD)
			draw_line(Vector2(frame.position.x, frame.end.y), Vector2(frame.end.x, frame.position.y), WOOD_HI, 6.0)
			_rect(Rect2(frame.position.x, -4, frame.size.x, 8), Color(EMBER, 0.55))
			for c in _corners(r, 0):
				var sx := 1.0 if c.x < 0 else -1.0
				var sy := 1.0 if c.y < 0 else -1.0
				draw_colored_polygon(PackedVector2Array([c, c + Vector2(12 * sx, 0), c + Vector2(0, 12 * sy)]), BRASS)
				_rivet(c + Vector2(4 * sx, 4 * sy), 1.6)
			_outline(r, WOOD_LO, 2.0)


# ---------------- HOUSES ----------------

func _house() -> void:
	var w := size.x
	var h := size.y
	var hx := w * 0.5
	match style:
		0:
			# Brick rowhouse: brick wall, slate roof, sooty chimney, iron-framed lit window.
			_rect(Rect2(-hx, -h, w, h), BRICK)
			var row := 0
			var by := -h + 2.0
			while by < -2.0:
				var off := 0.0 if row % 2 == 0 else 9.0
				var bx := -hx + off
				while bx < hx:
					_rect(Rect2(bx + 1, by, minf(16.0, hx - bx - 1), 6), BRICK_HI)
					bx += 18.0
				by += 8.0
				row += 1
			_rect(Rect2(hx * 0.35, -h - 46, 16, 30), BRICK)
			_rect(Rect2(hx * 0.35 - 2, -h - 50, 20, 5), IRON_MID)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 10, -h), Vector2(hx + 10, -h), Vector2(0, -h - 38)]), SLATE)
			for k in 4:
				var yy := -h - 8.0 - k * 8.0
				var half := (hx + 10) * (1.0 - (k * 8.0 + 8.0) / 38.0)
				draw_line(Vector2(-half, yy), Vector2(half, yy), Color(SLATE.lightened(0.15)), 1.0)
			_window(Vector2(-hx + 26, -h + 34), Vector2(22, 26))
			_door(Vector2(0, 0), BRASS)
			_rect(Rect2(-hx, -4, w, 4), COAL)
		1:
			# Riveted iron shack: plate panels, pipe chimney, round porthole window.
			_rect(Rect2(-hx, -h, w, h), IRON_MID)
			var px := -hx
			while px < hx:
				draw_line(Vector2(px, -h), Vector2(px, 0), IRON, 2.0)
				for ry in [-h + 6, -h * 0.5, -6.0]:
					_rivet(Vector2(px + 5, ry), 1.6)
				px += 30.0
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 8, -h), Vector2(hx + 8, -h), Vector2(hx - 6, -h - 22), Vector2(-hx + 6, -h - 22)]), RUST)
			draw_line(Vector2(-hx - 8, -h), Vector2(hx + 8, -h), Color(RUST.darkened(0.4)), 3.0)
			_rect(Rect2(hx * 0.4, -h - 54, 10, 34), IRON_HI)
			_rect(Rect2(hx * 0.4 - 3, -h - 56, 16, 4), BRASS_LO)
			draw_circle(Vector2(hx * 0.4 + 5, -h - 66), 7.0, Color(0.85, 0.85, 0.85, 0.12))
			draw_circle(Vector2(-hx + 30, -h + 32), 12.0, BRASS)
			draw_circle(Vector2(-hx + 30, -h + 32), 9.0, Color(LAMP, 0.75))
			draw_line(Vector2(-hx + 21, -h + 32), Vector2(-hx + 39, -h + 32), BRASS_LO, 1.5)
			_door(Vector2(0, 0), BRASS_HI)
		2:
			# Timber-framed workshop: plaster and beams, gear emblem, striped awning.
			_rect(Rect2(-hx, -h, w, h), Color("4b4136"))
			for bx in [-hx, -hx * 0.33, hx * 0.33, hx - 6]:
				_rect(Rect2(bx, -h, 6, h), WOOD_LO)
			_rect(Rect2(-hx, -h * 0.55, w, 5), WOOD_LO)
			draw_line(Vector2(-hx, -h * 0.55), Vector2(-hx * 0.33, -h), WOOD_LO, 4.0)
			draw_line(Vector2(hx, -h * 0.55), Vector2(hx * 0.33, -h), WOOD_LO, 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 12, -h), Vector2(hx + 12, -h), Vector2(hx * 0.6, -h - 34), Vector2(-hx * 0.6, -h - 34)]), Color("3a2a28"))
			_gear(Vector2(0, -h - 14), 10.0, BRASS)
			var aw := 40.0
			for k in 5:
				var c := EMBER if k % 2 == 0 else Color("d9c9a3")
				draw_colored_polygon(PackedVector2Array([
					Vector2(-aw * 0.5 + k * 8, -40), Vector2(-aw * 0.5 + (k + 1) * 8, -40),
					Vector2(-aw * 0.5 + (k + 1) * 8 + 2, -32), Vector2(-aw * 0.5 + k * 8 + 2, -32)]), c)
			_window(Vector2(-hx + 24, -h + 30), Vector2(20, 22))
			_window(Vector2(hx - 24, -h + 30), Vector2(20, 22))
			_door(Vector2(0, 0), BRASS)


# ---------------- CHECKPOINTS ("Rest") ----------------

func _checkpoint() -> void:
	var flick := 0.85 + 0.15 * sin(_t * 6.0) * sin(_t * 2.3)
	match style:
		0:
			# Furnace hearth: iron stove with a glowing grate and a short flue.
			draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(26, -36), Vector2(-26, -36)]), IRON)
			_rect(Rect2(-28, -40, 56, 6), IRON_HI)
			_rect(Rect2(10, -62, 9, 22), IRON_MID)
			_rect(Rect2(8, -64, 13, 4), BRASS_LO)
			var g := Rect2(-16, -28, 32, 18)
			_rect(g, Color(EMBER, flick))
			_rect(g.grow(-4), Color(LAMP, 0.6 * flick))
			for k in 5:
				draw_line(Vector2(g.position.x + 3 + k * 6.5, g.position.y), Vector2(g.position.x + 3 + k * 6.5, g.end.y), COAL, 2.0)
			_rivet(Vector2(-22, -6), 2.0)
			_rivet(Vector2(22, -6), 2.0)
		1:
			# Ink shrine: brass pedestal holding a purple shadow-flame (safe for the spirit).
			draw_colored_polygon(PackedVector2Array([Vector2(-22, 0), Vector2(22, 0), Vector2(14, -10), Vector2(-14, -10)]), IRON_MID)
			_rect(Rect2(-6, -34, 12, 24), BRASS_LO)
			_rect(Rect2(-14, -38, 28, 5), BRASS)
			draw_arc(Vector2(0, -40), 14, 0, PI, 16, BRASS, 3.0)
			var top := -52.0 - 6.0 * flick
			draw_colored_polygon(PackedVector2Array([Vector2(-9, -40), Vector2(9, -40), Vector2(4, top + 10), Vector2(0, top), Vector2(-4, top + 10)]), INK)
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -41), Vector2(4, -41), Vector2(0, top + 12)]), INK_HI)
			draw_circle(Vector2(0, -46), 22.0, Color(INK, 0.12 * flick))
		2:
			# Gear bench: a stone bench under a half-buried clock gear with an ember gem.
			_gear(Vector2(0, -34), 26.0, BRASS_LO, 10)
			draw_circle(Vector2(0, -34), 14.0, IRON)
			draw_circle(Vector2(0, -34), 5.0, Color(EMBER, flick))
			draw_line(Vector2(0, -34), Vector2(0, -46), BRASS_HI, 2.0)
			draw_line(Vector2(0, -34), Vector2(8, -30), BRASS_HI, 2.0)
			_rect(Rect2(-34, -16, 68, 8), STONE_HI)
			_rect(Rect2(-30, -8, 8, 8), STONE)
			_rect(Rect2(22, -8, 8, 8), STONE)
			_rect(Rect2(-34, -16, 68, 2), Color(STONE_HI.lightened(0.2)))


# ---------------- LANTERNS ----------------

func _lantern() -> void:
	var flick := 0.88 + 0.12 * sin(_t * 7.0) * sin(_t * 3.1)
	if not on:
		flick = 0.22
	else:
		draw_circle(Vector2(0, -2), 26.0, Color(tint, 0.10 * flick))
	match style:
		0:
			# Caged brass lantern (reference art): cap, cage bars, diamond bottom, warm core.
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -22), Vector2(8, -22), Vector2(12, -16), Vector2(-12, -16)]), BRASS)
			draw_arc(Vector2(0, -24), 4.0, PI, TAU, 8, BRASS_HI, 2.0)
			_rect(Rect2(-10, -16, 20, 22), Color(tint, 0.85 * flick))
			_rect(Rect2(-5, -12, 10, 14), Color(tint.lightened(0.55), flick))
			for bx in [-10.0, -3.5, 3.5, 10.0]:
				draw_line(Vector2(bx, -16), Vector2(bx, 6), BRASS_LO, 2.0)
			draw_line(Vector2(-10, -5), Vector2(10, -5), BRASS_LO, 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 6), Vector2(12, 6), Vector2(0, 16)]), BRASS)
		1:
			# Gas street lamp head: iron hex hood, four glass panes, finial.
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -16), Vector2(14, -16), Vector2(6, -24), Vector2(-6, -24)]), IRON_HI)
			draw_line(Vector2(0, -24), Vector2(0, -30), IRON_HI, 2.0)
			draw_circle(Vector2(0, -31), 2.5, BRASS)
			draw_colored_polygon(PackedVector2Array([Vector2(-11, -16), Vector2(11, -16), Vector2(8, 8), Vector2(-8, 8)]), Color(LAMP, 0.8 * flick))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -10), Vector2(4, -10), Vector2(3, 4), Vector2(-3, 4)]), Color(LAMP_CORE, flick))
			draw_line(Vector2(0, -16), Vector2(0, 8), IRON, 2.0)
			draw_polyline(PackedVector2Array([Vector2(-11, -16), Vector2(-8, 8), Vector2(8, 8), Vector2(11, -16)]), IRON, 2.0)
			_rect(Rect2(-9, 8, 18, 4), IRON_HI)
		2:
			# Ship's globe lantern: round glass, brass bands, top handle.
			draw_arc(Vector2(0, -24), 7.0, PI, TAU, 12, BRASS_LO, 2.5)
			_rect(Rect2(-9, -20, 18, 5), BRASS)
			draw_circle(Vector2(0, -4), 12.0, Color(LAMP, 0.8 * flick))
			draw_circle(Vector2(0, -4), 6.0, Color(LAMP_CORE, flick))
			draw_arc(Vector2(0, -4), 12.0, 0, TAU, 20, BRASS_LO, 2.0)
			draw_line(Vector2(-12, -4), Vector2(12, -4), BRASS_LO, 2.0)
			_rect(Rect2(-9, 7, 18, 5), BRASS)
			draw_circle(Vector2(-4, -9), 2.0, Color(1, 1, 1, 0.5))


# ---------------- second round: D / E / F ----------------

func _platform_more() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		3:
			# Chain-hung plank bridge: wood planks on iron straps, chains rising off-screen.
			var x := r.position.x
			var i := 0
			while x < r.end.x - 1.0:
				_rect(Rect2(x + 1, r.position.y, minf(15.0, r.end.x - x - 1), h), WOOD_HI if i % 3 == 0 else WOOD)
				x += 16.0
				i += 1
			_rect(Rect2(r.position.x, r.position.y + 3, w, 3), IRON_MID)
			_rect(Rect2(r.position.x, r.end.y - 6, w, 3), IRON_MID)
			for cx in [r.position.x + 8, r.end.x - 8]:
				var cy := r.position.y
				for k in 6:
					draw_arc(Vector2(cx, cy - 5 - k * 9), 3.5, 0, TAU, 8, IRON_HI, 1.5)
		4:
			# Clockwork gear ledge: brass-edged plate riding on half-sunk gears.
			var gy := r.end.y + 2
			var gx := r.position.x + 22.0
			while gx < r.end.x - 10.0:
				_gear(Vector2(gx, gy), 13.0, BRASS_LO, 9)
				draw_circle(Vector2(gx, gy), 4.0, IRON)
				gx += 44.0
			_rect(r, IRON)
			_rect(Rect2(r.position, Vector2(w, 4)), BRASS)
			var tx := r.position.x
			while tx < r.end.x:
				_rect(Rect2(tx, r.position.y - 3, 5, 3), BRASS_HI)
				tx += 10.0
			_rect(Rect2(r.position.x, r.end.y - 2, w, 2), COAL)
		5:
			# Copper pipe bundle: three fat pipes with flanges and a small valve wheel.
			var bands := 3
			var bh := h / bands
			for k in bands:
				var y := r.position.y + k * bh
				var col := Color("8a5a35") if k != 1 else Color("a06a3e")
				_rect(Rect2(r.position.x, y, w, bh - 1), col)
				draw_line(Vector2(r.position.x, y + 2), Vector2(r.end.x, y + 2), Color(col.lightened(0.3)), 1.5)
			var fx := r.position.x + 14.0
			while fx < r.end.x - 8.0:
				_rect(Rect2(fx, r.position.y - 2, 6, h + 4), IRON_HI)
				_rivet(Vector2(fx + 3, r.position.y + 2), 1.4)
				_rivet(Vector2(fx + 3, r.end.y - 2), 1.4)
				fx += 52.0
			draw_circle(Vector2(r.end.x - 26, r.position.y - 8), 6.0, EMBER)
			draw_circle(Vector2(r.end.x - 26, r.position.y - 8), 3.0, IRON)
			draw_line(Vector2(r.end.x - 26, r.position.y - 2), Vector2(r.end.x - 26, r.position.y), IRON_HI, 2.0)


func _crate_more() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		3:
			# Coal bin: riveted iron tub heaped with coal lumps.
			_rect(Rect2(r.position.x, r.position.y + h * 0.18, w, h * 0.82), IRON_MID)
			for k in 7:
				var cx := r.position.x + 6 + k * (w - 12) / 6.0
				draw_circle(Vector2(cx, r.position.y + h * 0.2 - (k % 3) * 2), 6.0 + (k % 2) * 2, COAL)
			draw_circle(Vector2(r.position.x + w * 0.35, r.position.y + h * 0.1), 2.0, Color(EMBER, 0.8))
			_rect(Rect2(r.position.x, r.position.y + h * 0.2, w, 4), IRON_HI)
			for c in _corners(r.grow_individual(0, -h * 0.18, 0, 0), 5):
				_rivet(c, 2.0)
			draw_line(Vector2(r.position.x + 6, r.position.y + h * 0.55), Vector2(r.end.x - 6, r.position.y + h * 0.55), IRON, 2.0)
			_outline(r.grow_individual(0, -h * 0.18, 0, 0), COAL, 2.0)
		4:
			# Steam boiler cube: banded tank with a pressure gauge and a stub valve.
			_rect(r, Color("3d4a4a"))
			for yy in [0.2, 0.8]:
				_rect(Rect2(r.position.x, r.position.y + h * yy - 3, w, 6), BRASS_LO)
			draw_circle(Vector2(0, 0), minf(w, h) * 0.22, Color("e8dcc0"))
			draw_arc(Vector2(0, 0), minf(w, h) * 0.22, 0, TAU, 20, BRASS, 3.0)
			draw_line(Vector2(0, 0), Vector2(minf(w, h) * 0.14, -minf(w, h) * 0.08), EMBER, 2.0)
			_rect(Rect2(r.end.x - 14, r.position.y - 6, 6, 8), IRON_HI)
			_outline(r, COAL, 2.0)
		5:
			# Painted guild crate: deep green boards, stencilled brass gear emblem.
			_rect(r, Color("23362b"))
			var y := r.position.y
			while y < r.end.y:
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("1a281f"), 1.0)
				y += 9.0
			_gear(Vector2(0, 0), minf(w, h) * 0.22, Color(BRASS, 0.85), 8)
			draw_circle(Vector2(0, 0), minf(w, h) * 0.08, Color("23362b"))
			_rect(Rect2(r.position.x, r.position.y, w, 4), Color("2f4a3a"))
			_outline(r, COAL, 2.0)
			for c in _corners(r, 4):
				_rivet(c, 1.6)


func _house_more() -> void:
	var w := size.x
	var h := size.y
	var hx := w * 0.5
	match style:
		3:
			# Tall townhouse: two storeys, steep gable, iron balcony.
			var th := h * 1.35
			_rect(Rect2(-hx * 0.8, -th, w * 0.8, th), Color("3b2f2a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-hx * 0.8 - 8, -th), Vector2(hx * 0.8 + 8, -th), Vector2(0, -th - 50)]), SLATE)
			_window(Vector2(0, -th - 18), Vector2(14, 16))
			_window(Vector2(-hx * 0.4, -th + 28), Vector2(18, 26))
			_window(Vector2(hx * 0.4, -th + 28), Vector2(18, 26))
			_rect(Rect2(-hx * 0.8, -th * 0.5, w * 0.8, 3), IRON_HI)
			var bx := -hx * 0.6
			while bx <= hx * 0.6:
				draw_line(Vector2(bx, -th * 0.5), Vector2(bx, -th * 0.5 - 14), IRON_HI, 1.5)
				bx += 8.0
			draw_line(Vector2(-hx * 0.6, -th * 0.5 - 14), Vector2(hx * 0.6, -th * 0.5 - 14), IRON_HI, 2.0)
			_door(Vector2(0, 0), BRASS)
		4:
			# Boiler-house: sawtooth roof, big round window, twin smokestacks.
			_rect(Rect2(-hx, -h, w, h), Color("33302c"))
			var teeth := 3
			for k in teeth:
				var x0 := -hx + k * (w / teeth)
				draw_colored_polygon(PackedVector2Array([Vector2(x0, -h), Vector2(x0 + w / teeth, -h), Vector2(x0 + w / teeth, -h - 22)]), IRON_MID)
				draw_line(Vector2(x0 + w / teeth, -h), Vector2(x0 + w / teeth, -h - 22), Color(LAMP, 0.5), 2.0)
			for sx in [-hx * 0.55, -hx * 0.3]:
				_rect(Rect2(sx, -h - 60, 10, 40), BRICK)
				_rect(Rect2(sx - 2, -h - 62, 14, 4), IRON)
			draw_circle(Vector2(hx * 0.35, -h * 0.6), 18.0, IRON)
			draw_circle(Vector2(hx * 0.35, -h * 0.6), 14.0, Color(LAMP, 0.7))
			for a in 6:
				var d := Vector2(cos(a * PI / 3.0), sin(a * PI / 3.0)) * 14.0
				draw_line(Vector2(hx * 0.35, -h * 0.6), Vector2(hx * 0.35, -h * 0.6) + d, IRON, 2.0)
			_rect(Rect2(-hx + 12, -40, 40, 40), IRON)
			_rect(Rect2(-hx + 15, -37, 34, 37), WOOD_LO)
			draw_line(Vector2(-hx + 32, -37), Vector2(-hx + 32, 0), IRON, 2.0)
			draw_circle(Vector2(-hx + 28, -18), 2.0, BRASS)
		5:
			# Observatory cottage: stone walls under a brass dome with a telescope.
			_rect(Rect2(-hx, -h, w, h), Color("3a3a3c"))
			var row := 0
			var y := -h + 4.0
			while y < -4.0:
				draw_line(Vector2(-hx, y), Vector2(hx, y), Color("2c2c2e"), 1.0)
				y += 12.0
				row += 1
			draw_arc(Vector2(0, -h), hx * 0.8, PI, TAU, 24, BRASS_LO, 3.0)
			var pts := PackedVector2Array()
			for k in 25:
				var a := PI + PI * float(k) / 24.0
				pts.append(Vector2(cos(a), sin(a)) * hx * 0.8 + Vector2(0, -h))
			draw_colored_polygon(pts, BRASS)
			for k in 4:
				var a := PI + PI * (k + 1) / 5.0
				draw_line(Vector2(0, -h), Vector2(cos(a), sin(a)) * hx * 0.8 + Vector2(0, -h), BRASS_LO, 1.5)
			draw_line(Vector2(hx * 0.1, -h - hx * 0.5), Vector2(hx * 0.6, -h - hx * 0.95), IRON_HI, 6.0)
			_window(Vector2(-hx + 24, -h + 30), Vector2(18, 22))
			_door(Vector2(hx * 0.3, 0), BRASS_HI)


func _checkpoint_more() -> void:
	var flick := 0.85 + 0.15 * sin(_t * 6.0) * sin(_t * 2.3)
	match style:
		3:
			# Snuffed lamp post: a dead street lamp whose glass now holds shadow-ink.
			_rect(Rect2(-3, -80, 6, 80), IRON_MID)
			_rect(Rect2(-12, -4, 24, 4), IRON_HI)
			draw_colored_polygon(PackedVector2Array([Vector2(-12, -80), Vector2(12, -80), Vector2(5, -88), Vector2(-5, -88)]), IRON_HI)
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -80), Vector2(10, -80), Vector2(7, -60), Vector2(-7, -60)]), Color(INK, 0.9))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -64), Vector2(4, -64), Vector2(0, -76 - 3 * flick)]), INK_HI)
			draw_line(Vector2(-10, -80), Vector2(-4, -70), Color(1, 1, 1, 0.25), 1.0)
			draw_circle(Vector2(0, -70), 20.0, Color(INK, 0.12 * flick))
		4:
			# Ink cauldron: squat iron pot bubbling with violet ink.
			draw_colored_polygon(PackedVector2Array([Vector2(-26, -30), Vector2(26, -30), Vector2(20, -4), Vector2(-20, -4)]), IRON)
			_rect(Rect2(-28, -34, 56, 5), IRON_HI)
			_rect(Rect2(-22, -4, 6, 4), IRON_MID)
			_rect(Rect2(16, -4, 6, 4), IRON_MID)
			_rect(Rect2(-24, -36, 48, 3), INK)
			for k in 3:
				var bx := -12.0 + k * 12.0
				var bob := fmod(_t * 1.5 + k * 0.33, 1.0)
				draw_circle(Vector2(bx, -40 - bob * 14), 3.0 * (1.0 - bob), Color(INK_HI, 1.0 - bob))
			draw_circle(Vector2(0, -36), 26.0, Color(INK, 0.1 * flick))
		5:
			# Bell shrine: a small iron frame holding a brass bell over a step.
			_rect(Rect2(-30, -8, 60, 8), STONE)
			_rect(Rect2(-24, -64, 5, 56), IRON_MID)
			_rect(Rect2(19, -64, 5, 56), IRON_MID)
			_rect(Rect2(-28, -68, 56, 5), IRON_HI)
			var sway := sin(_t * 1.6) * 3.0
			draw_colored_polygon(PackedVector2Array([Vector2(-6 + sway, -62), Vector2(6 + sway, -62), Vector2(13 + sway, -32), Vector2(-13 + sway, -32)]), BRASS)
			draw_line(Vector2(-13 + sway, -32), Vector2(13 + sway, -32), BRASS_HI, 2.0)
			draw_circle(Vector2(sway, -29), 3.0, Color(EMBER, flick))


# ---------------- POTS (glowing breakables) ----------------

func _pot() -> void:
	var w := size.x
	var h := size.y
	var pulse := 0.75 + 0.25 * sin(_t * 2.4)
	var glow := Color(0.75, 0.9, 1.0)
	match style:
		0:
			# Brass canister: riveted cylinder with a glass window and the glow inside.
			_rect(Rect2(-w * 0.5, -h * 0.5, w, h), BRASS_LO)
			_rect(Rect2(-w * 0.5, -h * 0.5, w, 4), BRASS_HI)
			_rect(Rect2(-w * 0.5, h * 0.5 - 4, w, 4), BRASS)
			_rect(Rect2(-w * 0.3, -h * 0.3, w * 0.6, h * 0.55), Color(glow, 0.8 * pulse))
			_rect(Rect2(-w * 0.12, -h * 0.2, w * 0.24, h * 0.35), Color(1, 1, 1, 0.8 * pulse))
			_outline(Rect2(-w * 0.3, -h * 0.3, w * 0.6, h * 0.55), IRON, 2.0)
			_rivet(Vector2(-w * 0.4, h * 0.38), 1.4)
			_rivet(Vector2(w * 0.4, h * 0.38), 1.4)
		1:
			# Clay jar with glowing cracks.
			var pts := PackedVector2Array([Vector2(-w * 0.25, -h * 0.5), Vector2(w * 0.25, -h * 0.5), Vector2(w * 0.5, -h * 0.1),
				Vector2(w * 0.42, h * 0.45), Vector2(-w * 0.42, h * 0.45), Vector2(-w * 0.5, -h * 0.1)])
			draw_colored_polygon(pts, Color("5b4334"))
			_rect(Rect2(-w * 0.3, -h * 0.58, w * 0.6, 5), Color("6e5240"))
			var crack := PackedVector2Array([Vector2(-w * 0.1, -h * 0.35), Vector2(w * 0.05, -h * 0.1), Vector2(-w * 0.08, h * 0.1), Vector2(w * 0.12, h * 0.35)])
			draw_polyline(crack, Color(glow, pulse), 2.0)
			draw_line(Vector2(w * 0.05, -h * 0.1), Vector2(w * 0.3, -h * 0.05), Color(glow, pulse), 1.5)
		2:
			# Glass specimen jar with a floating wisp.
			_rect(Rect2(-w * 0.45, -h * 0.4, w * 0.9, h * 0.85), Color(0.5, 0.65, 0.7, 0.25))
			_outline(Rect2(-w * 0.45, -h * 0.4, w * 0.9, h * 0.85), Color(0.7, 0.85, 0.9, 0.6), 1.5)
			_rect(Rect2(-w * 0.5, -h * 0.52, w, 7), BRASS)
			_rect(Rect2(-w * 0.5, h * 0.42, w, 5), BRASS_LO)
			var bob := sin(_t * 2.0) * 3.0
			draw_circle(Vector2(0, bob), w * 0.2, Color(glow, 0.7 * pulse))
			draw_circle(Vector2(0, bob), w * 0.1, Color(1, 1, 1, pulse))
		3:
			# Little boiler kettle: round iron body, glowing gauge, spout.
			draw_circle(Vector2(0, h * 0.08), w * 0.48, IRON_MID)
			_rect(Rect2(-w * 0.3, -h * 0.5, w * 0.6, 6), IRON_HI)
			draw_line(Vector2(w * 0.4, 0), Vector2(w * 0.7, -h * 0.2), IRON_HI, 4.0)
			draw_circle(Vector2(0, h * 0.08), w * 0.22, Color(glow, 0.85 * pulse))
			draw_arc(Vector2(0, h * 0.08), w * 0.22, 0, TAU, 16, BRASS, 2.0)
			draw_line(Vector2(0, h * 0.08), Vector2(w * 0.12, 0), IRON, 1.5)


# ---------------- HATCHES ----------------

func _hatch() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		0:
			# Riveted iron manhole: plate, rivet ring, pull ring.
			_rect(r, IRON_MID)
			_rect(Rect2(r.position, Vector2(w, 3)), IRON_HI)
			var x := r.position.x + 5
			while x < r.end.x - 3:
				_rivet(Vector2(x, r.position.y + 5), 1.4)
				_rivet(Vector2(x, r.end.y - 4), 1.4)
				x += 10
			draw_arc(Vector2(0, r.position.y - 1), 6.0, PI, TAU, 10, BRASS, 2.5)
			_outline(r, COAL, 2.0)
		1:
			# Wooden trapdoor with iron straps and hinges.
			var x := r.position.x
			while x < r.end.x - 1:
				_rect(Rect2(x + 1, r.position.y, minf(11.0, r.end.x - x - 1), h), WOOD)
				x += 12.0
			for sx in [r.position.x + w * 0.22, r.end.x - w * 0.22 - 6]:
				_rect(Rect2(sx, r.position.y, 6, h), IRON_HI)
			_rect(Rect2(r.position.x - 3, r.position.y + 2, 6, 6), IRON_HI)
			_rect(Rect2(r.end.x - 3, r.position.y + 2, 6, 6), IRON_HI)
			draw_circle(Vector2(0, 0), 3.0, BRASS)
			_outline(r, WOOD_LO, 2.0)
		2:
			# Brass vault hatch with a valve wheel in the middle.
			_rect(r, BRASS_LO)
			_rect(r.grow(-3), Color("4a3a22"))
			draw_circle(Vector2.ZERO, h * 0.75, BRASS)
			draw_circle(Vector2.ZERO, h * 0.5, Color("4a3a22"))
			for a in 4:
				var d := Vector2(cos(a * PI / 2.0 + 0.4), sin(a * PI / 2.0 + 0.4)) * h * 0.75
				draw_line(Vector2.ZERO, d, BRASS, 2.0)
			draw_circle(Vector2.ZERO, 2.5, BRASS_HI)


# ---------------- BACKDROPS (walls, pipes, windows, gears, vents) ----------------

## Draws a sample stretch of background (size = area) so each option shows a whole matching set.
func _backdrop() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h, w, h)
	match style:
		0:
			# Brick & copper: soot-dark brick, copper pipe with valve, arched window, slow gear.
			_rect(r, Color("2a1c19"))
			var row := 0
			var y := r.position.y
			while y < r.end.y:
				var x := r.position.x + (0.0 if row % 2 == 0 else 12.0)
				while x < r.end.x - 2.0:
					_rect(Rect2(x + 1, y + 1, minf(22.0, r.end.x - x - 2.0), minf(9.0, r.end.y - y - 1.0)), Color("33231e"))
					x += 24.0
				y += 11.0
				row += 1
			draw_line(Vector2(r.position.x, r.position.y + 40), Vector2(r.end.x, r.position.y + 40), Color("8a5a35"), 10.0)
			draw_line(Vector2(r.position.x, r.position.y + 37), Vector2(r.end.x, r.position.y + 37), Color("b07a4c"), 2.0)
			draw_circle(Vector2(r.position.x + w * 0.25, r.position.y + 40), 9.0, EMBER)
			draw_circle(Vector2(r.position.x + w * 0.25, r.position.y + 40), 4.0, IRON)
			var wc := Vector2(r.position.x + w * 0.62, r.position.y + h * 0.5)
			_rect(Rect2(wc - Vector2(22, 20), Vector2(44, 50)), IRON)
			draw_circle(wc + Vector2(0, -20), 22.0, IRON)
			_rect(Rect2(wc - Vector2(18, 18), Vector2(36, 46)), Color("2b3a55"))
			draw_circle(wc + Vector2(0, -18), 18.0, Color("2b3a55"))
			draw_line(wc + Vector2(0, -36), wc + Vector2(0, 28), IRON, 2.0)
			_gear(Vector2(r.end.x - 60, r.position.y + h * 0.7), 40.0, Color("3a2d22"), 12)
		1:
			# Teal foundry (reference art): misty teal depth, big gold gears joined by a belt, steam.
			_rect(r, Color("102a33"))
			_rect(Rect2(r.position.x, r.position.y + h * 0.55, w, h * 0.45), Color("0c2028"))
			var c1 := Vector2(r.position.x + w * 0.3, r.position.y + h * 0.45)
			var c2 := Vector2(r.position.x + w * 0.72, r.position.y + h * 0.35)
			draw_line(c1 + Vector2(0, -34), c2 + Vector2(0, -22), Color("1f3a40"), 8.0)
			draw_line(c1 + Vector2(0, 34), c2 + Vector2(0, 22), Color("1f3a40"), 8.0)
			_gear(c1, 44.0, Color("b8892f"), 14)
			draw_circle(c1, 22.0, Color("6e5530"))
			draw_circle(c1, 9.0, Color("1f3a40"))
			_gear(c2, 28.0, Color("2f4f55"), 10)
			draw_circle(c2, 12.0, Color("b8892f"))
			for k in 3:
				var sy := fmod(_t * 12.0 + k * 20.0, 60.0)
				draw_circle(Vector2(r.end.x - 40 + k * 6, r.end.y - 20 - sy), 8.0 + sy * 0.2, Color(0.8, 0.9, 0.9, 0.12 * (1.0 - sy / 60.0)))
		2:
			# Riveted bulkhead: iron hull panels, porthole, pressure gauges, a steam vent grille.
			_rect(r, Color("1e1c1b"))
			var px := r.position.x
			while px < r.end.x:
				draw_line(Vector2(px, r.position.y), Vector2(px, r.end.y), Color("2c2826"), 3.0)
				var ry := r.position.y + 8.0
				while ry < r.end.y:
					draw_circle(Vector2(px + 6, ry), 1.6, Color("4a423c"))
					ry += 20.0
				px += 60.0
			var pc := Vector2(r.position.x + w * 0.35, r.position.y + h * 0.4)
			draw_circle(pc, 26.0, BRASS_LO)
			draw_circle(pc, 20.0, Color("1d2d3d"))
			draw_circle(pc + Vector2(-6, -6), 4.0, Color(1, 1, 1, 0.15))
			for k in 2:
				var gc := Vector2(r.position.x + w * 0.65 + k * 34, r.position.y + h * 0.35)
				draw_circle(gc, 12.0, Color("e8dcc0"))
				draw_arc(gc, 12.0, 0, TAU, 16, BRASS, 2.0)
				# Needle wobbles across the upper half of the dial.
				draw_line(gc, gc + Vector2(cos(_t * 0.5 + k), -absf(sin(_t * 0.5 + k))) * 8.0, EMBER, 1.5)
			var vg := Rect2(r.position.x + w * 0.62, r.end.y - 40, 70, 22)
			_rect(vg, COAL)
			var gx := vg.position.x + 4
			while gx < vg.end.x:
				draw_line(Vector2(gx, vg.position.y), Vector2(gx, vg.end.y), IRON_HI, 2.0)
				gx += 7.0


# ---------------- third round ----------------

## Wooden take on the X-brace crate (crate B, but all timber).
func _crate_wood_x() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var light := Color("8a6440")
	var mid := Color("6b4a2c")
	var dark := Color("3e2a18")
	match style:
		6:
			# Pine X-brace: light boards, plank frame, nail heads at every joint.
			_rect(r, mid)
			var y := r.position.y
			while y < r.end.y:
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), dark, 1.0)
				y += 11.0
			var inner := r.grow(-7)
			_plank_frame(r, light, 7)
			draw_line(inner.position, inner.end, light, 7.0)
			draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), light, 7.0)
			for c in _corners(r, 3.5):
				draw_circle(c, 1.4, IRON_HI)
			_outline(r, dark, 2.0)
		7:
			# Dark oak X-brace with iron corner plates and rivets (closest to steel crate B).
			_rect(r, Color("4a3220"))
			var inner := r.grow(-6)
			_rect(inner, Color("3a2716"))
			draw_line(inner.position, inner.end, Color("5e4129"), 6.0)
			draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), Color("5e4129"), 6.0)
			_outline(inner, dark, 1.0)
			for c in _corners(r, 0):
				_bracket(c, r)
			draw_circle(Vector2.ZERO, 3.0, IRON_HI)
			_outline(r, COAL, 2.0)
		8:
			# Weathered dock crate: grey-brown X, rope handles, stencilled number.
			_rect(r, Color("5f5243"))
			_plank_frame(r, Color("766654"), 6)
			var inner := r.grow(-6)
			draw_line(inner.position, inner.end, Color("766654"), 6.0)
			draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), Color("766654"), 6.0)
			draw_arc(Vector2(r.position.x, 0), 6.0, -PI * 0.5, PI * 0.5, 8, Color("b39a6b"), 2.5)
			draw_arc(Vector2(r.end.x, 0), 6.0, PI * 0.5, PI * 1.5, 8, Color("b39a6b"), 2.5)
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 9, r.end.y - 9), "07", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(EMBER, 0.7))
			_outline(r, Color("2f271e"), 2.0)


## Scenery crate: dark-oak boards in a frame, no X brace (pushable crates have the X).
## Reads fine at any width/height.
func _crate_pine_planks() -> void:
	var r := Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y)
	var oak := Color("3a2716")
	var oak_lo := Color("2a1c10")
	_rect(r, oak)
	var y := r.position.y + 7.0
	while y < r.end.y - 4.0:
		draw_line(Vector2(r.position.x + 3, y), Vector2(r.end.x - 3, y), oak_lo, 1.0)
		y += 7.0
	_plank_frame(r, Color("5e4129"), 3.0)
	for c in _corners(r, 2.5):
		draw_circle(c, 1.1, IRON_HI)
	_outline(r, COAL, 1.5)


## More houses in the timber-workshop family (house C).
func _house_timber() -> void:
	var w := size.x
	var h := size.y
	var hx := w * 0.5
	var plaster := Color("4b4136")
	var beam := WOOD_LO
	var roof := Color("3a2a28")
	match style:
		6:
			# Jettied two-storey: upper floor overhangs on brackets, cross beams, small gear clock.
			_rect(Rect2(-hx, -h * 0.55, w, h * 0.55), plaster)
			_rect(Rect2(-hx - 8, -h * 1.15, w + 16, h * 0.6), plaster)
			for bx in [-hx, -hx * 0.33, hx * 0.33, hx - 6]:
				_rect(Rect2(bx, -h * 0.55, 6, h * 0.55), beam)
			for bx in [-hx - 8, 0.0 - 3, hx + 2]:
				_rect(Rect2(bx, -h * 1.15, 6, h * 0.6), beam)
			_rect(Rect2(-hx - 8, -h * 0.58, w + 16, 6), beam)
			for sx in [-hx - 2, hx - 6]:
				draw_colored_polygon(PackedVector2Array([Vector2(sx, -h * 0.52), Vector2(sx + 8, -h * 0.52), Vector2(sx + 8, -h * 0.4)]), beam)
			draw_line(Vector2(-hx - 5, -h * 1.15), Vector2(-3, -h * 0.58), beam, 3.0)
			draw_line(Vector2(hx + 5, -h * 1.15), Vector2(3, -h * 0.58), beam, 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 16, -h * 1.15), Vector2(hx + 16, -h * 1.15), Vector2(0, -h * 1.6)]), roof)
			_gear(Vector2(0, -h * 1.3), 8.0, BRASS)
			_window(Vector2(-hx * 0.55, -h * 0.85), Vector2(18, 18))
			_window(Vector2(hx * 0.55, -h * 0.85), Vector2(18, 18))
			_window(Vector2(-hx * 0.62, -h * 0.3), Vector2(16, 18))
			_door(Vector2(hx * 0.1, 0), BRASS)
		7:
			# Corner shop: brass-framed bay window, hanging gear sign, striped awning.
			_rect(Rect2(-hx, -h, w, h), plaster)
			for bx in [-hx, hx - 6]:
				_rect(Rect2(bx, -h, 6, h), beam)
			_rect(Rect2(-hx, -h * 0.55, w, 5), beam)
			draw_line(Vector2(-hx, -h), Vector2(-hx * 0.2, -h * 0.55), beam, 4.0)
			draw_line(Vector2(hx, -h), Vector2(hx * 0.2, -h * 0.55), beam, 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 10, -h), Vector2(hx + 10, -h), Vector2(hx * 0.6, -h - 30), Vector2(-hx * 0.6, -h - 30)]), roof)
			var bay := Rect2(-hx + 10, -42, 44, 30)
			_rect(bay.grow(3), BRASS_LO)
			_rect(bay, Color(LAMP, 0.7))
			for k in 3:
				draw_line(Vector2(bay.position.x + (k + 1) * bay.size.x / 4.0, bay.position.y), Vector2(bay.position.x + (k + 1) * bay.size.x / 4.0, bay.end.y), BRASS_LO, 2.0)
			for k in 6:
				var c := EMBER if k % 2 == 0 else Color("d9c9a3")
				draw_colored_polygon(PackedVector2Array([Vector2(bay.position.x - 4 + k * 9, bay.position.y - 12), Vector2(bay.position.x + 5 + k * 9, bay.position.y - 12),
					Vector2(bay.position.x + 7 + k * 9, bay.position.y - 4), Vector2(bay.position.x - 2 + k * 9, bay.position.y - 4)]), c)
			draw_line(Vector2(hx - 4, -h * 0.62), Vector2(hx + 18, -h * 0.62), IRON_HI, 2.0)
			_rect(Rect2(hx + 4, -h * 0.62 + 4, 18, 14), WOOD)
			_gear(Vector2(hx + 13, -h * 0.62 + 11), 4.5, BRASS)
			_door(Vector2(hx * 0.45, 0), BRASS)
		8:
			# Gabled cottage: steep gable with exposed X beams, sooty chimney, round attic window.
			_rect(Rect2(-hx, -h, w, h), plaster)
			for bx in [-hx, -hx * 0.4, hx * 0.4 - 6, hx - 6]:
				_rect(Rect2(bx, -h, 6, h), beam)
			_rect(Rect2(-hx, -h * 0.5, w, 5), beam)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 4, -h), Vector2(hx + 4, -h), Vector2(0, -h - 56)]), plaster)
			draw_polyline(PackedVector2Array([Vector2(-hx - 4, -h), Vector2(0, -h - 56), Vector2(hx + 4, -h)]), roof, 9.0)
			draw_line(Vector2(-hx * 0.5, -h - 4), Vector2(hx * 0.5, -h - 4), beam, 4.0)
			draw_line(Vector2(-hx * 0.42, -h - 4), Vector2(0, -h - 36), beam, 3.0)
			draw_line(Vector2(hx * 0.42, -h - 4), Vector2(0, -h - 36), beam, 3.0)
			draw_circle(Vector2(0, -h - 22), 8.0, beam)
			draw_circle(Vector2(0, -h - 22), 6.0, Color(LAMP, 0.75))
			_rect(Rect2(hx * 0.45, -h - 52, 12, 30), BRICK)
			_rect(Rect2(hx * 0.45 - 2, -h - 54, 16, 4), COAL)
			_window(Vector2(-hx * 0.7, -h * 0.25), Vector2(14, 18))
			_window(Vector2(hx * 0.7, -h * 0.25), Vector2(14, 18))
			_door(Vector2(0, 0), BRASS)
		9:
			# Clockmaker's house: big clock face in the gable, twin windows with flower boxes.
			_rect(Rect2(-hx, -h, w, h), plaster)
			for bx in [-hx, -6.0 + 3, hx - 6]:
				_rect(Rect2(bx, -h, 6, h), beam)
			_rect(Rect2(-hx, -h * 0.52, w, 5), beam)
			draw_colored_polygon(PackedVector2Array([Vector2(-hx - 12, -h), Vector2(hx + 12, -h), Vector2(0, -h - 46)]), roof)
			var cc := Vector2(0, -h - 16)
			draw_circle(cc, 14.0, BRASS)
			draw_circle(cc, 11.0, Color("e8dcc0"))
			for k in 12:
				var a := TAU * k / 12.0
				draw_line(cc + Vector2(cos(a), sin(a)) * 9.0, cc + Vector2(cos(a), sin(a)) * 11.0, IRON, 1.0)
			draw_line(cc, cc + Vector2(0, -8), IRON, 2.0)
			draw_line(cc, cc + Vector2(6, 2), IRON, 2.0)
			for wx in [-hx * 0.55, hx * 0.55]:
				_window(Vector2(wx, -h * 0.78), Vector2(18, 20))
				_rect(Rect2(wx - 12, -h * 0.78 + 13, 24, 5), WOOD)
				for f in 3:
					draw_circle(Vector2(wx - 7 + f * 7, -h * 0.78 + 12), 2.2, EMBER if f != 1 else Color("d9c9a3"))
			_window(Vector2(-hx * 0.55, -h * 0.25), Vector2(18, 20))
			_door(Vector2(hx * 0.45, 0), BRASS)


## Checkpoint D reworked: two short snuffed lamp posts with a small steel bench between them.
func _checkpoint_twin_posts() -> void:
	var flick := 0.85 + 0.15 * sin(_t * 6.0) * sin(_t * 2.3)
	for px in [-38.0, 38.0]:
		_mini_post(Vector2(px, 0), flick)
	var steel := Color("6d7072")
	var steel_hi := Color("8d9194")
	var steel_lo := Color("45484a")
	match style:
		6:
			# Plain steel slat bench.
			for k in 3:
				_rect(Rect2(-24, -16 + k * 4, 48, 3), steel if k != 0 else steel_hi)
			_rect(Rect2(-22, -6, 3, 6), steel_lo)
			_rect(Rect2(19, -6, 3, 6), steel_lo)
		7:
			# Riveted steel bench with a backrest and curled arms.
			_rect(Rect2(-24, -14, 48, 4), steel_hi)
			_rect(Rect2(-22, -26, 44, 3), steel)
			_rect(Rect2(-22, -21, 44, 3), steel)
			_rect(Rect2(-22, -26, 3, 26), steel_lo)
			_rect(Rect2(19, -26, 3, 26), steel_lo)
			draw_arc(Vector2(-24, -14), 4.0, PI * 0.5, PI * 1.5, 8, steel_hi, 2.0)
			draw_arc(Vector2(24, -14), 4.0, -PI * 0.5, PI * 0.5, 8, steel_hi, 2.0)
			for rx in [-16.0, 0.0, 16.0]:
				draw_circle(Vector2(rx, -12), 1.2, steel_lo)
		8:
			# Steel bench whose backrest is a half gear.
			draw_arc(Vector2(0, -14), 18.0, PI, TAU, 20, steel, 3.0)
			for k in 7:
				var a := PI + PI * (k + 0.5) / 7.0
				var d := Vector2(cos(a), sin(a))
				draw_line(Vector2(0, -14) + d * 18.0, Vector2(0, -14) + d * 22.0, steel, 4.0)
			draw_circle(Vector2(0, -14), 4.0, steel_lo)
			_rect(Rect2(-24, -14, 48, 4), steel_hi)
			_rect(Rect2(-20, -10, 3, 10), steel_lo)
			_rect(Rect2(17, -10, 3, 10), steel_lo)


func _mini_post(base: Vector2, flick: float) -> void:
	if not on:
		flick = 0.35
	_rect(Rect2(base.x - 8, base.y - 4, 16, 4), IRON_HI)
	_rect(Rect2(base.x - 2, base.y - 44, 4, 40), IRON_MID)
	var top := base.y - 44
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 9, top), Vector2(base.x + 9, top), Vector2(base.x + 4, top - 6), Vector2(base.x - 4, top - 6)]), IRON_HI)
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 7, top), Vector2(base.x + 7, top), Vector2(base.x + 5, top + 14), Vector2(base.x - 5, top + 14)]), Color(INK, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 3, top + 11), Vector2(base.x + 3, top + 11), Vector2(base.x, top + 2 - 2 * flick)]), INK_HI)
	draw_circle(Vector2(base.x, top + 7), 14.0, Color(INK, 0.1 * flick))


func _pot_more() -> void:
	var w := size.x
	var h := size.y
	var pulse := 0.75 + 0.25 * sin(_t * 2.4)
	var glow := Color(0.75, 0.9, 1.0)
	match style:
		4:
			# Gear-lid jar: squat glass jar with a brass gear for a lid.
			_rect(Rect2(-w * 0.45, -h * 0.3, w * 0.9, h * 0.75), Color(0.5, 0.65, 0.7, 0.3))
			_rect(Rect2(-w * 0.35, -h * 0.15, w * 0.7, h * 0.5), Color(glow, 0.6 * pulse))
			_outline(Rect2(-w * 0.45, -h * 0.3, w * 0.9, h * 0.75), Color(0.75, 0.85, 0.9, 0.6), 1.5)
			_gear(Vector2(0, -h * 0.38), w * 0.32, BRASS, 8)
			draw_circle(Vector2(0, -h * 0.38), w * 0.1, BRASS_LO)
		5:
			# Copper urn: round belly, glowing vent slits, two little handles.
			draw_circle(Vector2(0, h * 0.05), w * 0.5, Color("8a5a35"))
			_rect(Rect2(-w * 0.22, -h * 0.5, w * 0.44, h * 0.22), Color("a06a3e"))
			_rect(Rect2(-w * 0.3, -h * 0.52, w * 0.6, 4), Color("b07a4c"))
			for k in 3:
				_rect(Rect2(-w * 0.3, -h * 0.05 + k * 6, w * 0.6, 2.5), Color(glow, pulse))
			draw_arc(Vector2(-w * 0.52, 0), 4.0, PI * 0.5, PI * 1.5, 6, Color("6e4528"), 2.0)
			draw_arc(Vector2(w * 0.52, 0), 4.0, -PI * 0.5, PI * 0.5, 6, Color("6e4528"), 2.0)
		6:
			# Clockwork egg: brass oval with a glowing seam and little bolts.
			var pts := PackedVector2Array()
			for k in 24:
				var a := TAU * k / 24.0
				pts.append(Vector2(cos(a) * w * 0.45, sin(a) * h * 0.5 + (h * 0.06 if sin(a) > 0 else 0.0)))
			draw_colored_polygon(pts, BRASS)
			draw_line(Vector2(-w * 0.45, 0), Vector2(w * 0.45, 0), Color(glow, pulse), 3.0)
			draw_line(Vector2(-w * 0.2, -h * 0.4), Vector2(-w * 0.2, h * 0.45), BRASS_LO, 1.5)
			draw_line(Vector2(w * 0.2, -h * 0.4), Vector2(w * 0.2, h * 0.45), BRASS_LO, 1.5)
			for by in [-h * 0.25, h * 0.25]:
				draw_circle(Vector2(0, by), 2.0, BRASS_HI)
		7:
			# Ink-glass bottle: tall bottle, cork, glowing liquid with a bubble.
			_rect(Rect2(-w * 0.4, -h * 0.15, w * 0.8, h * 0.62), Color(0.35, 0.45, 0.5, 0.45))
			_rect(Rect2(-w * 0.15, -h * 0.45, w * 0.3, h * 0.32), Color(0.35, 0.45, 0.5, 0.45))
			_rect(Rect2(-w * 0.17, -h * 0.55, w * 0.34, h * 0.12), WOOD_HI)
			_rect(Rect2(-w * 0.34, h * 0.05, w * 0.68, h * 0.38), Color(glow, 0.75 * pulse))
			draw_circle(Vector2(w * 0.1, h * 0.1 - fmod(_t * 8.0, 10.0)), 2.0, Color(1, 1, 1, 0.7))
			_outline(Rect2(-w * 0.4, -h * 0.15, w * 0.8, h * 0.62), Color(0.7, 0.85, 0.9, 0.5), 1.0)


func _hatch_more() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		3:
			# Porthole hatch: square iron frame, round brass-ringed lid, dog-clamps.
			_rect(r, IRON)
			draw_circle(Vector2.ZERO, h * 0.62, BRASS_LO)
			draw_circle(Vector2.ZERO, h * 0.48, IRON_MID)
			for sx in [-1.0, 1.0]:
				_rect(Rect2(sx * w * 0.3 - 3, -h * 0.5, 6, h), IRON_HI)
			draw_circle(Vector2.ZERO, 2.0, BRASS_HI)
			_outline(r, COAL, 2.0)
		4:
			# Drain grate: iron bars over a faint ink glow underneath.
			_rect(r, Color("1b1624"))
			_rect(r.grow(-3), Color(INK, 0.35))
			var x := r.position.x + 4
			while x < r.end.x - 2:
				_rect(Rect2(x, r.position.y, 3, h), IRON_HI)
				x += 7
			_rect(Rect2(r.position.x, r.position.y, w, 3), IRON_HI)
			_rect(Rect2(r.position.x, r.end.y - 3, w, 3), IRON_HI)
		5:
			# Cellar doors: two wooden leaves, iron hinges, a ring handle on each.
			_rect(r, WOOD_LO)
			for k in 2:
				var leaf := Rect2(r.position.x + k * w * 0.5 + 1, r.position.y + 1, w * 0.5 - 2, h - 2)
				_rect(leaf, WOOD)
				var y := leaf.position.y + 4
				while y < leaf.end.y:
					draw_line(Vector2(leaf.position.x, y), Vector2(leaf.end.x, y), WOOD_LO, 1.0)
					y += 5
				_rect(Rect2(leaf.position.x + 3, leaf.position.y + 2, 10, 3), IRON_HI)
				draw_arc(Vector2(leaf.get_center().x + (6 if k == 0 else -6), leaf.get_center().y), 3.0, 0, TAU, 8, IRON_HI, 1.5)
		6:
			# Gear-lock hatch: riveted plate with a rotating gear lock in the middle.
			_rect(r, IRON_MID)
			_rect(r.grow(-3), IRON)
			_gear(Vector2.ZERO, h * 0.45, BRASS, 10)
			draw_circle(Vector2.ZERO, h * 0.18, IRON)
			for c in _corners(r, 4):
				_rivet(c, 1.5)
			draw_line(Vector2(-w * 0.42, 0), Vector2(-h * 0.5, 0), BRASS_LO, 2.0)
			draw_line(Vector2(w * 0.42, 0), Vector2(h * 0.5, 0), BRASS_LO, 2.0)


# ---------------- LEVERS ----------------

## Origin = pivot area of the existing lever (base spans about y -22..4).
func _lever() -> void:
	var ang := deg_to_rad(-38.0 if on else 38.0)
	match style:
		0:
			# Brass throw lever: brass wall plate, iron handle, red knob.
			_rect(Rect2(-12, -22, 24, 26), BRASS_LO)
			_rect(Rect2(-10, -20, 20, 22), BRASS)
			for c in [Vector2(-7, -17), Vector2(7, -17), Vector2(-7, -1), Vector2(7, -1)]:
				_rivet(c, 1.5)
			draw_line(Vector2(-6, -9), Vector2(6, -9), BRASS_LO, 3.0)
			var tip := Vector2(0, -9) + Vector2(sin(ang), -cos(ang)) * 24.0
			draw_line(Vector2(0, -9), tip, IRON_HI, 4.0)
			draw_circle(tip, 4.0, EMBER)
			draw_circle(Vector2(0, -9), 3.5, IRON)
		1:
			# Railway switch: low iron box, short rod; the small light is green when on, red when off.
			var state := Color("4caf50") if on else Color("c62828")
			_rect(Rect2(-14, -6, 28, 10), IRON_MID)
			_rect(Rect2(-14, -6, 28, 2), IRON_HI)
			var tip := Vector2(0, -4) + Vector2(sin(ang), -cos(ang)) * 20.0
			draw_line(Vector2(0, -4), tip, IRON_HI, 3.0)
			draw_circle(tip, 4.0, IRON_HI)
			draw_circle(tip - Vector2(1, 1), 1.5, Color(1, 1, 1, 0.3))
			_rect(Rect2(-11, -1, 6, 3), state)
		2:
			# Valve wheel: wall-mounted wheel on a pipe stub; turns a quarter when flipped.
			_rect(Rect2(-4, -10, 8, 14), IRON_MID)
			draw_line(Vector2(-14, 2), Vector2(14, 2), RUST, 6.0)
			var c := Vector2(0, -14)
			draw_arc(c, 11.0, 0, TAU, 20, EMBER, 3.0)
			for k in 4:
				var a := ang + k * PI * 0.5
				draw_line(c, c + Vector2(cos(a), sin(a)) * 11.0, EMBER, 2.0)
			draw_circle(c, 3.0, IRON_HI)
		3:
			# Knife switch: ceramic base, copper blade, glowing contact when closed.
			_rect(Rect2(-13, -6, 26, 8), Color("d8cfbf"))
			_rect(Rect2(-13, -6, 26, 2), Color("efe6d6"))
			_rect(Rect2(-10, -10, 4, 5), BRASS_LO)
			_rect(Rect2(6, -10, 4, 5), BRASS_LO)
			var blade_end := Vector2(8, -8) if on else Vector2(-8, -8) + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * 18.0
			draw_line(Vector2(-8, -8), blade_end, Color("c98a4b"), 3.0)
			_rect(Rect2(-1, -16 if not on else -11, 3, 4), WOOD_LO)
			if on:
				draw_circle(Vector2(8, -8), 4.0, Color(LAMP, 0.5))


# ---------------- WINDOWS ----------------

func _window_art() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var glow := IRON.lerp(LAMP, 0.62 + 0.04 * sin(_t * 1.7))
	match style:
		0:
			# Arched iron window with a warm glow and cross bars.
			var top := Vector2(0, r.position.y + w * 0.5)
			_rect(Rect2(r.position.x - 3, top.y, w + 6, r.end.y - top.y + 3), IRON)
			draw_circle(top, w * 0.5 + 3, IRON)
			_rect(Rect2(r.position.x, top.y, w, r.end.y - top.y), glow)
			draw_circle(top, w * 0.5, glow)
			draw_line(Vector2(0, r.position.y), Vector2(0, r.end.y), IRON, 3.0)
			draw_line(Vector2(r.position.x, top.y + (r.end.y - top.y) * 0.4), Vector2(r.end.x, top.y + (r.end.y - top.y) * 0.4), IRON, 3.0)
			_rect(Rect2(r.position.x - 6, r.end.y + 2, w + 12, 4), STONE_HI)
		1:
			# Brass porthole.
			var rad := minf(w, h) * 0.5
			draw_circle(Vector2.ZERO, rad + 4, BRASS_LO)
			draw_circle(Vector2.ZERO, rad + 1, BRASS)
			draw_circle(Vector2.ZERO, rad - 3, glow)
			for k in 8:
				var a := TAU * k / 8.0
				draw_circle(Vector2(cos(a), sin(a)) * (rad + 1.5), 1.4, BRASS_HI)
			draw_circle(Vector2(-rad * 0.35, -rad * 0.35), rad * 0.18, Color(1, 1, 1, 0.25))
		2:
			# Factory grid window: many small panes, a couple dark or broken.
			_rect(r.grow(3), IRON)
			var cols := 4
			var rows := 5
			var pw := w / cols
			var ph := h / rows
			for cy in rows:
				for cx in cols:
					var pane := Rect2(r.position.x + cx * pw + 1, r.position.y + cy * ph + 1, pw - 2, ph - 2)
					var dead := (cx + cy * 3) % 7 == 2
					_rect(pane, Color("1b1d22") if dead else glow)
					if (cx * 5 + cy) % 11 == 4:
						draw_line(pane.position, pane.end, IRON, 1.0)
			_rect(Rect2(r.position.x - 5, r.end.y + 3, w + 10, 4), IRON_HI)
		3:
			# Shuttered window: open wooden shutters, sill with a flower box.
			_rect(r.grow(2), WOOD_LO)
			_rect(r, glow)
			draw_line(Vector2(0, r.position.y), Vector2(0, r.end.y), WOOD_LO, 2.0)
			draw_line(Vector2(r.position.x, 0), Vector2(r.end.x, 0), WOOD_LO, 2.0)
			for sx in [-1.0, 1.0]:
				var sh := Rect2(r.position.x - w * 0.45 - 2 if sx < 0 else r.end.x + 2, r.position.y, w * 0.45, h)
				_rect(sh, Color("2f4a3a"))
				var y := sh.position.y + 3
				while y < sh.end.y - 2:
					draw_line(Vector2(sh.position.x + 2, y), Vector2(sh.end.x - 2, y), Color("1f3328"), 1.5)
					y += 5
			_rect(Rect2(r.position.x - 4, r.end.y + 2, w + 8, 7), WOOD)
			for f in 4:
				draw_circle(Vector2(r.position.x + 3 + f * (w - 6) / 3.0, r.end.y + 1), 3.0, EMBER if f % 2 == 0 else Color("d9c9a3"))


# ---------------- fourth round ----------------

func _pot_third() -> void:
	var w := size.x
	var h := size.y
	var pulse := 0.75 + 0.25 * sin(_t * 2.4)
	var glow := Color(0.75, 0.9, 1.0)
	match style:
		8:
			# Mesh lantern-jar: brass caps with a wire mesh over the glow.
			_rect(Rect2(-w * 0.4, -h * 0.35, w * 0.8, h * 0.75), Color(glow, 0.75 * pulse))
			var x := -w * 0.4
			while x <= w * 0.4:
				draw_line(Vector2(x, -h * 0.35), Vector2(x, h * 0.4), BRASS_LO, 1.0)
				x += 4.0
			var y := -h * 0.35
			while y <= h * 0.4:
				draw_line(Vector2(-w * 0.4, y), Vector2(w * 0.4, y), BRASS_LO, 1.0)
				y += 4.0
			_rect(Rect2(-w * 0.5, -h * 0.5, w, h * 0.16), BRASS)
			_rect(Rect2(-w * 0.5, h * 0.38, w, h * 0.12), BRASS)
			draw_arc(Vector2(0, -h * 0.5), w * 0.22, PI, TAU, 10, BRASS_HI, 2.0)
		9:
			# Hourglass vial: brass frame, glowing sand pouring through the waist.
			_rect(Rect2(-w * 0.5, -h * 0.5, w, 4), BRASS)
			_rect(Rect2(-w * 0.5, h * 0.5 - 4, w, 4), BRASS)
			for sx in [-w * 0.45, w * 0.45 - 2]:
				_rect(Rect2(sx, -h * 0.5, 2, h), BRASS_LO)
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.35, -h * 0.42), Vector2(w * 0.35, -h * 0.42), Vector2(2, 0), Vector2(-2, 0)]), Color(0.6, 0.75, 0.8, 0.35))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(w * 0.35, h * 0.42), Vector2(-w * 0.35, h * 0.42)]), Color(0.6, 0.75, 0.8, 0.35))
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.32, h * 0.42), Vector2(w * 0.32, h * 0.42), Vector2(0, h * 0.12)]), Color(glow, pulse))
			draw_line(Vector2(0, 0), Vector2(0, h * 0.3), Color(glow, pulse), 1.5)
		10:
			# Pressure flask: round flask on a brass stand with a tiny gauge.
			draw_circle(Vector2(0, h * 0.05), w * 0.42, Color(0.6, 0.75, 0.8, 0.35))
			draw_circle(Vector2(0, h * 0.12), w * 0.32, Color(glow, 0.8 * pulse))
			_rect(Rect2(-w * 0.12, -h * 0.45, w * 0.24, h * 0.18), Color(0.6, 0.75, 0.8, 0.45))
			_rect(Rect2(-w * 0.16, -h * 0.52, w * 0.32, 4), BRASS)
			_rect(Rect2(-w * 0.45, h * 0.42, w * 0.9, 4), BRASS_LO)
			draw_circle(Vector2(w * 0.32, -h * 0.25), 4.0, Color("e8dcc0"))
			draw_line(Vector2(w * 0.32, -h * 0.25), Vector2(w * 0.32 + 2, -h * 0.25 - 2), EMBER, 1.0)
		11:
			# Barrel jar: small banded keg with a glowing bung hole.
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.4, -h * 0.5), Vector2(w * 0.4, -h * 0.5), Vector2(w * 0.5, 0),
				Vector2(w * 0.4, h * 0.5), Vector2(-w * 0.4, h * 0.5), Vector2(-w * 0.5, 0)]), WOOD)
			for k in 3:
				draw_line(Vector2(-w * 0.2 + k * w * 0.2, -h * 0.5), Vector2(-w * 0.2 + k * w * 0.2, h * 0.5), WOOD_LO, 1.0)
			for yy in [-h * 0.3, h * 0.3]:
				_rect(Rect2(-w * 0.47, yy - 2, w * 0.94, 4), BRASS)
			draw_circle(Vector2(0, 0), 4.0, Color(glow, pulse))
			draw_circle(Vector2(0, 0), 2.0, Color(1, 1, 1, pulse))
		12:
			# Rune urn: pale ceramic with a glowing sigil.
			var pts := PackedVector2Array([Vector2(-w * 0.2, -h * 0.5), Vector2(w * 0.2, -h * 0.5), Vector2(w * 0.25, -h * 0.35),
				Vector2(w * 0.48, 0), Vector2(w * 0.3, h * 0.5), Vector2(-w * 0.3, h * 0.5), Vector2(-w * 0.48, 0), Vector2(-w * 0.25, -h * 0.35)])
			draw_colored_polygon(pts, Color("b9ad98"))
			draw_line(Vector2(-w * 0.45, h * 0.15), Vector2(w * 0.45, h * 0.15), Color("8f846f"), 2.0)
			draw_arc(Vector2(0, -h * 0.02), w * 0.16, 0, TAU, 12, Color(glow, pulse), 2.0)
			draw_line(Vector2(0, -h * 0.2), Vector2(0, h * 0.15), Color(glow, pulse), 1.5)
			draw_line(Vector2(-w * 0.15, -h * 0.02), Vector2(w * 0.15, -h * 0.02), Color(glow, pulse), 1.5)
		13:
			# Alchemist flask: round-bottom flask, cork, glowing liquid, a drip of steam.
			draw_circle(Vector2(0, h * 0.15), w * 0.45, Color(0.6, 0.75, 0.8, 0.3))
			draw_circle(Vector2(0, h * 0.22), w * 0.36, Color(glow, 0.8 * pulse))
			_rect(Rect2(-w * 0.12, -h * 0.4, w * 0.24, h * 0.3), Color(0.6, 0.75, 0.8, 0.35))
			_rect(Rect2(-w * 0.15, -h * 0.5, w * 0.3, h * 0.12), WOOD_HI)
			draw_arc(Vector2(0, h * 0.15), w * 0.45, 0, TAU, 20, Color(0.75, 0.85, 0.9, 0.55), 1.0)
			draw_circle(Vector2(-w * 0.15, h * 0.05), 2.0, Color(1, 1, 1, 0.6))


## More hatches in the brass-vault (C) and cellar-door (F) styles.
func _hatch_third() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	match style:
		7:
			# Brass cellar doors: two riveted brass leaves with a valve wheel lock on the seam.
			_rect(r, BRASS_LO)
			for k in 2:
				var leaf := Rect2(r.position.x + k * w * 0.5 + 1, r.position.y + 1, w * 0.5 - 2, h - 2)
				_rect(leaf, Color("8c6d3f"))
				for c in _corners(leaf, 3):
					_rivet(c, 1.2)
			_valve_wheel(Vector2.ZERO, h * 0.45, BRASS_HI)
		8:
			# Oak cellar doors with a brass wheel lock and brass hinges.
			_rect(r, WOOD_LO)
			for k in 2:
				var leaf := Rect2(r.position.x + k * w * 0.5 + 1, r.position.y + 1, w * 0.5 - 2, h - 2)
				_rect(leaf, WOOD)
				var y := leaf.position.y + 4
				while y < leaf.end.y:
					draw_line(Vector2(leaf.position.x, y), Vector2(leaf.end.x, y), WOOD_LO, 1.0)
					y += 5
				_rect(Rect2(leaf.position.x + (2 if k == 0 else leaf.size.x - 12), leaf.position.y + 2, 10, 3), BRASS)
			_valve_wheel(Vector2.ZERO, h * 0.42, BRASS)
		9:
			# Brass vault with a glass porthole showing ink glow below.
			_rect(r, BRASS_LO)
			_rect(r.grow(-3), Color("4a3a22"))
			draw_circle(Vector2.ZERO, h * 0.62, BRASS)
			draw_circle(Vector2.ZERO, h * 0.45, Color(INK, 0.7))
			draw_circle(Vector2(-h * 0.15, -h * 0.15), h * 0.1, Color(1, 1, 1, 0.3))
			for c in _corners(r, 4):
				_rivet(c, 1.4)
		10:
			# Iron-strapped cellar doors with a padlock.
			_rect(r, WOOD_LO)
			for k in 2:
				var leaf := Rect2(r.position.x + k * w * 0.5 + 1, r.position.y + 1, w * 0.5 - 2, h - 2)
				_rect(leaf, Color("5a3e26"))
			for yy in [r.position.y + 3, r.end.y - 6]:
				_rect(Rect2(r.position.x, yy, w, 3), IRON_HI)
			_rect(Rect2(-4, -3, 8, 7), BRASS)
			draw_arc(Vector2(0, -3), 3.0, PI, TAU, 8, IRON_HI, 1.5)
		11:
			# Twin-wheel vault: brass plate with two small valve wheels.
			_rect(r, BRASS_LO)
			_rect(r.grow(-3), Color("4a3a22"))
			for sx in [-w * 0.22, w * 0.22]:
				_valve_wheel(Vector2(sx, 0), h * 0.4, BRASS)
			draw_line(Vector2(-w * 0.22 + h * 0.4, 0), Vector2(w * 0.22 - h * 0.4, 0), BRASS_HI, 2.0)


## More windows in the arched-iron (A) style.
func _window_arched() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var glow := IRON.lerp(LAMP, 0.62 + 0.04 * sin(_t * 1.7))
	match style:
		4:
			# Twin arched windows sharing a stone sill.
			for sx in [-w * 0.27, w * 0.27]:
				_arch(Rect2(sx - w * 0.22, r.position.y, w * 0.44, h), glow, 2)
			_rect(Rect2(r.position.x - 6, r.end.y + 2, w + 12, 4), STONE_HI)
		5:
			# Gothic pointed arch with a quatrefoil.
			var spring := r.position.y + w * 0.6
			_rect(Rect2(r.position.x - 3, spring, w + 6, r.end.y - spring + 3), IRON)
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x - 3, spring), Vector2(r.end.x + 3, spring), Vector2(0, r.position.y - 6)]), IRON)
			_rect(Rect2(r.position.x, spring, w, r.end.y - spring), glow)
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, spring), Vector2(r.end.x, spring), Vector2(0, r.position.y - 2)]), glow)
			draw_line(Vector2(0, r.position.y), Vector2(0, r.end.y), IRON, 3.0)
			for k in 4:
				var a := k * PI * 0.5
				draw_circle(Vector2(0, spring - 6) + Vector2(cos(a), sin(a)) * 3.5, 2.5, IRON)
			_rect(Rect2(r.position.x - 6, r.end.y + 2, w + 12, 4), STONE_HI)
		6:
			# Arched with a fanlight: radiating panes in the arch.
			_arch(r, glow, 0)
			var c := Vector2(0, r.position.y + w * 0.5)
			for k in 5:
				var a := PI + PI * (k + 1) / 6.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * w * 0.5, IRON, 2.0)
			draw_line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), IRON, 3.0)
			draw_line(Vector2(0, c.y), Vector2(0, r.end.y), IRON, 3.0)
			_rect(Rect2(r.position.x - 6, r.end.y + 2, w + 12, 4), STONE_HI)
		7:
			# Arched with a brass keystone and a deep sill.
			_arch(r, glow, 1)
			draw_colored_polygon(PackedVector2Array([Vector2(-5, r.position.y - 6), Vector2(5, r.position.y - 6), Vector2(3, r.position.y + 4), Vector2(-3, r.position.y + 4)]), BRASS)
			_rect(Rect2(r.position.x - 8, r.end.y + 2, w + 16, 7), STONE_HI)
			_rect(Rect2(r.position.x - 8, r.end.y + 8, w + 16, 2), STONE_LO)
		8:
			# Barred arched window: vertical iron bars over the glow.
			_arch(r, glow, 0)
			var x := r.position.x + w * 0.2
			while x < r.end.x - 2:
				draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y), IRON, 2.0)
				x += w * 0.2
			draw_line(Vector2(r.position.x, r.end.y - h * 0.3), Vector2(r.end.x, r.end.y - h * 0.3), IRON, 2.0)
			_rect(Rect2(r.position.x - 6, r.end.y + 2, w + 12, 4), STONE_HI)
		9:
			# Tall arched window with a small iron balcony rail.
			_arch(r, glow, 1)
			_rect(Rect2(r.position.x - 10, r.end.y + 2, w + 20, 4), IRON_HI)
			var x := r.position.x - 8
			while x <= r.end.x + 8:
				draw_line(Vector2(x, r.end.y + 2), Vector2(x, r.end.y - 12), IRON_HI, 1.5)
				x += 6.0
			draw_line(Vector2(r.position.x - 10, r.end.y - 12), Vector2(r.end.x + 10, r.end.y - 12), IRON_HI, 2.0)


# ---------------- BENCHES ----------------

## Origin = floor, bench centered. About 60 wide.
func _bench() -> void:
	match style:
		0:
			# Cast-iron park bench: curly iron legs, wooden slats.
			_rect(Rect2(-30, -14, 60, 4), WOOD_HI)
			_rect(Rect2(-30, -26, 60, 3), WOOD)
			_rect(Rect2(-30, -21, 60, 3), WOOD)
			for sx in [-24.0, 24.0]:
				# Curl faces outward on each side.
				var a0 := -PI * 0.5 if sx > 0 else PI * 0.5
				draw_arc(Vector2(sx, -6), 6.0, a0, a0 + PI, 10, IRON_HI, 2.5)
				draw_line(Vector2(sx, -28), Vector2(sx, -10), IRON_HI, 2.5)
				draw_line(Vector2(sx, -10), Vector2(sx + (4 if sx > 0 else -4), 0), IRON_HI, 2.5)
		1:
			# Riveted steel bench (matches the checkpoint bench).
			_rect(Rect2(-30, -14, 60, 4), Color("8d9194"))
			_rect(Rect2(-28, -26, 56, 3), Color("6d7072"))
			_rect(Rect2(-28, -21, 56, 3), Color("6d7072"))
			for sx in [-27.0, 24.0]:
				_rect(Rect2(sx, -26, 3, 26), Color("45484a"))
			for rx in [-18.0, 0.0, 18.0]:
				draw_circle(Vector2(rx, -12), 1.2, Color("45484a"))
		2:
			# Wooden pew with brass end caps.
			_rect(Rect2(-30, -14, 60, 5), WOOD_HI)
			_rect(Rect2(-30, -34, 60, 18), WOOD)
			draw_line(Vector2(-30, -25), Vector2(30, -25), WOOD_LO, 1.0)
			for sx in [-32.0, 28.0]:
				_rect(Rect2(sx, -36, 4, 36), WOOD_LO)
				_rect(Rect2(sx - 1, -38, 6, 3), BRASS)
		3:
			# Copper pipe-frame bench with a plank seat.
			_rect(Rect2(-30, -14, 60, 5), WOOD)
			draw_polyline(PackedVector2Array([Vector2(-26, 0), Vector2(-26, -30), Vector2(26, -30), Vector2(26, 0)]), Color("a06a3e"), 4.0)
			draw_line(Vector2(-26, -22), Vector2(26, -22), Color("8a5a35"), 3.0)
			for p in [Vector2(-26, -30), Vector2(26, -30), Vector2(-26, -14), Vector2(26, -14)]:
				draw_circle(p, 3.0, BRASS)
		5:
			# Riveted steel bench (B) in a darker, but not black, grey.
			_rect(Rect2(-30, -14, 60, 4), Color("5e6164"))
			_rect(Rect2(-28, -26, 56, 3), Color("4c4f52"))
			_rect(Rect2(-28, -21, 56, 3), Color("4c4f52"))
			for sx in [-27.0, 24.0]:
				_rect(Rect2(sx, -26, 3, 26), Color("36383a"))
			for rx in [-18.0, 0.0, 18.0]:
				draw_circle(Vector2(rx, -12), 1.2, Color("36383a"))
		4:
			# Crate-and-plank bench: a board laid across two small crates.
			for sx in [-24.0, 24.0]:
				var cr := Rect2(sx - 9, -16, 18, 16)
				_rect(cr, WOOD)
				draw_line(cr.position, cr.end, WOOD_HI, 2.0)
				_outline(cr, WOOD_LO, 1.5)
			_rect(Rect2(-32, -20, 64, 4), WOOD_HI)


# ---------------- VALVES ----------------

## Origin = center of the wheel / fitting on the wall.
func _valve() -> void:
	match style:
		0:
			# Red spoked wheel on a pipe stub.
			_rect(Rect2(-4, 0, 8, 14), IRON_MID)
			_valve_wheel(Vector2.ZERO, 11.0, EMBER)
		5:
			# Valve A mounted flat on the wall: round back flange, short stem, red spoked wheel.
			draw_circle(Vector2.ZERO, 6.5, IRON)
			draw_circle(Vector2.ZERO, 5.0, IRON_MID)
			for k in 4:
				var a := k * PI * 0.5 + PI * 0.25
				draw_circle(Vector2(cos(a), sin(a)) * 5.5, 1.0, IRON_HI)
			_valve_wheel(Vector2.ZERO, 8.5, EMBER)
		1:
			# Brass gate valve with a small pressure gauge.
			draw_line(Vector2(-18, 8), Vector2(18, 8), Color("8a5a35"), 7.0)
			_rect(Rect2(-6, -2, 12, 12), BRASS)
			_rect(Rect2(-1.5, -10, 3, 8), IRON_HI)
			_valve_wheel(Vector2(0, -12), 7.0, BRASS_HI)
			draw_circle(Vector2(14, -4), 5.0, Color("e8dcc0"))
			draw_arc(Vector2(14, -4), 5.0, 0, TAU, 12, BRASS, 1.5)
			draw_line(Vector2(14, -4), Vector2(16, -7), EMBER, 1.0)
		2:
			# Butterfly valve: pipe section with a flat lever handle.
			draw_line(Vector2(-18, 0), Vector2(18, 0), IRON_HI, 8.0)
			_rect(Rect2(-5, -6, 10, 12), IRON_MID)
			draw_line(Vector2(0, -2), Vector2(16, -10), EMBER, 4.0)
			draw_circle(Vector2(0, -2), 2.5, BRASS)
		3:
			# Triple manifold: three small wheels on a brass header pipe.
			draw_line(Vector2(-22, 6), Vector2(22, 6), BRASS_LO, 7.0)
			for k in 3:
				var x := -14.0 + k * 14.0
				_rect(Rect2(x - 1.5, -4, 3, 8), IRON_HI)
				_valve_wheel(Vector2(x, -6), 5.0, [EMBER, BRASS, EMBER][k])
		4:
			# Pressure release valve with a little steam whistle.
			draw_line(Vector2(-16, 6), Vector2(16, 6), Color("8a5a35"), 6.0)
			_rect(Rect2(-4, -10, 8, 14), BRASS)
			_rect(Rect2(-2, -18, 4, 8), BRASS_HI)
			draw_circle(Vector2(0, -19), 3.0, BRASS_HI)
			draw_circle(Vector2(0, -25 - fmod(_t * 10.0, 6.0)), 2.5, Color(0.9, 0.9, 0.9, 0.3))
			_valve_wheel(Vector2(-12, -4), 5.0, EMBER)


# ---------------- STEAM VENTS ----------------

## Origin = floor center. Steam puffs are drawn here for the preview; the game keeps its particle steam.
func _vent() -> void:
	match style:
		0:
			# Round brass floor vent.
			draw_colored_polygon(_ellipse(Vector2(0, -2), 20, 6), BRASS_LO)
			draw_colored_polygon(_ellipse(Vector2(0, -2), 16, 4.5), COAL)
			for k in 5:
				draw_line(Vector2(-12 + k * 6, -5), Vector2(-12 + k * 6, 1), BRASS, 1.5)
		1:
			# Riveted iron grate.
			_rect(Rect2(-20, -6, 40, 8), IRON_MID)
			_rect(Rect2(-17, -4, 34, 4), COAL)
			for k in 6:
				draw_line(Vector2(-15 + k * 6, -4), Vector2(-15 + k * 6, 0), IRON_HI, 2.0)
			for x in [-18.0, 18.0]:
				draw_circle(Vector2(x, -2), 1.4, BRASS_HI)
		2:
			# Pipe elbow coming up out of the floor.
			draw_line(Vector2(-14, 0), Vector2(-14, -16), Color("8a5a35"), 8.0)
			draw_arc(Vector2(-6, -16), 8.0, PI, PI * 1.5, 8, Color("8a5a35"), 8.0)
			draw_line(Vector2(-6, -24), Vector2(6, -24), Color("8a5a35"), 8.0)
			_rect(Rect2(6, -29, 4, 10), IRON_HI)
			_rect(Rect2(-19, -2, 10, 3), IRON_HI)
		3:
			# Short smokestack nozzle with a brass rim.
			_rect(Rect2(-8, -18, 16, 18), IRON_MID)
			_rect(Rect2(-10, -21, 20, 4), BRASS)
			_rect(Rect2(-12, -2, 24, 3), IRON_HI)
			draw_line(Vector2(-8, -9), Vector2(8, -9), IRON, 1.5)
		4:
			# Ornate gear grille set into the floor.
			_rect(Rect2(-20, -5, 40, 6), IRON)
			_gear(Vector2(0, -3), 7.0, BRASS, 8)
			draw_circle(Vector2(0, -3), 3.0, COAL)
			for x in [-14.0, 14.0]:
				_rect(Rect2(x - 3, -4, 6, 4), COAL)
	if not steam_preview:
		return
	# Preview puffs (rising, fading)
	var top := -6.0 if style != 2 and style != 3 else -26.0
	var sx := 8.0 if style == 2 else 0.0
	for k in 4:
		var f := fmod(_t * 0.6 + k * 0.25, 1.0)
		draw_circle(Vector2(sx + sin(f * 6.0 + k) * 4.0, top - f * 50.0), 5.0 + f * 9.0, Color(0.9, 0.92, 0.95, 0.22 * (1.0 - f)))


# ---------------- final picks (tweaked) ----------------

## Pot B reworked: a plain clay jar (no crack). The glow sits in its open mouth.
func _pot_clay_jar() -> void:
	# Simple flat jar: one clay colour, dark outline, rolled lip, glow in the mouth.
	# Keep 28:36 proportions so wide/short editor boxes don't squash it; sit it on the box bottom.
	var fit := minf(size.x / 28.0, size.y / 36.0)
	var w := 28.0 * fit
	var h := 36.0 * fit
	draw_set_transform(Vector2(0, size.y * 0.5 - h * 0.5))
	var pulse := 0.75 + 0.25 * sin(_t * 2.4)
	var clay := Color("9a6646")
	var line := Color("4a2c1c")
	# Soft pulsing glow around the jar, like the original glowing breakables.
	var glow := Color(0.75, 0.9, 1.0)
	draw_circle(Vector2(0, -h * 0.1), maxf(w, h) * 0.85, Color(glow, 0.05 * pulse))
	draw_circle(Vector2(0, -h * 0.1), maxf(w, h) * 0.6, Color(glow, 0.08 * pulse))
	# Rounded belly: narrow shoulders, widest in the middle, flat base.
	var belly := PackedVector2Array()
	for k in 25:
		var t := float(k) / 24.0
		var y := lerpf(-h * 0.3, h * 0.5, t)
		var half := lerpf(w * 0.24, w * 0.5, sin(t * PI * 0.85)) if t < 0.95 else w * 0.32
		belly.append(Vector2(half, y))
	for k in range(24, -1, -1):
		belly.append(Vector2(-belly[k].x, belly[k].y))
	var outline := PackedVector2Array()
	for v in belly:
		outline.append(v * 1.06 + Vector2(0, -0.5))
	draw_colored_polygon(outline, line)
	draw_colored_polygon(belly, clay)
	var neck := Rect2(-w * 0.22, -h * 0.42, w * 0.44, h * 0.14)
	draw_rect(neck.grow(1.5), line, true)
	draw_rect(neck, clay, true)
	var lip := Rect2(-w * 0.3, -h * 0.52, w * 0.6, h * 0.11)
	draw_rect(lip.grow(1.5), line, true)
	draw_rect(lip, Color("b27a55"), true)
	draw_rect(Rect2(-w * 0.2, -h * 0.52, w * 0.4, h * 0.05), Color(0.75, 0.9, 1.0, 0.85 * pulse), true)
	draw_line(Vector2(-w * 0.46, h * 0.08), Vector2(w * 0.46, h * 0.08), line, 2.0)
	draw_set_transform(Vector2.ZERO)


## Hatch, side view: a low brass cellar hatch sitting on the floor (origin = floor contact,
## bottom-center), like the steam vent grate. Doors are seen edge-on with the wheel lock in front.
func _hatch_brass_doors_plain() -> void:
	var w := size.x
	var hh := 13.0
	_rect(Rect2(-w * 0.5, -3, w, 3), IRON_MID)
	var body := PackedVector2Array([Vector2(-w * 0.46, -3), Vector2(w * 0.46, -3), Vector2(w * 0.4, -hh), Vector2(-w * 0.4, -hh)])
	draw_colored_polygon(body, Color("8c6d3f"))
	draw_polyline(PackedVector2Array([Vector2(-w * 0.46, -3), Vector2(-w * 0.4, -hh), Vector2(w * 0.4, -hh), Vector2(w * 0.46, -3)]), BRASS_LO, 2.0)
	_rect(Rect2(-w * 0.4, -hh - 2, w * 0.8, 2), BRASS_HI)
	draw_line(Vector2(0, -hh), Vector2(0, -3), BRASS_LO, 2.0)
	for sx in [-w * 0.36, w * 0.36 - 5]:
		_rect(Rect2(sx, -hh + 2, 5, 4), IRON_HI)
	_valve_wheel(Vector2(0, -hh * 0.5 - 1), 5.0, BRASS_HI)


## Window A, unlit: same arched iron frame with dark glass and a faint moon glint.
func _window_dark_arch() -> void:
	var r := Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y)
	_arch(r, Color("4d6f8f"), 1)
	draw_line(r.position + Vector2(6, size.x * 0.45), r.position + Vector2(12, size.x * 0.3), Color(0.85, 0.92, 1.0, 0.45), 2.0)
	_rect(Rect2(r.position.x - 6, r.end.y + 2, size.x + 12, 4), STONE_HI)


# ---------------- chain ----------------

## Hanging chain from the origin up to -size.y (lamps hang from the bottom end).
func _chain() -> void:
	var y := 0.0
	var k := 0
	while y > -size.y:
		if k % 2 == 0:
			draw_arc(Vector2(0, y - 4), 2.5, 0, TAU, 10, IRON_HI, 1.5)
		else:
			draw_line(Vector2(0, y - 1), Vector2(0, y - 7), IRON_MID, 2.0)
		y -= 7.0
		k += 1


# ---------------- helpers ----------------

func _arch(r: Rect2, glow: Color, bars: int) -> void:
	var w := r.size.x
	var top := Vector2(r.get_center().x, r.position.y + w * 0.5)
	_rect(Rect2(r.position.x - 3, top.y, w + 6, r.end.y - top.y + 3), IRON)
	draw_circle(top, w * 0.5 + 3, IRON)
	_rect(Rect2(r.position.x, top.y, w, r.end.y - top.y), glow)
	draw_circle(top, w * 0.5, glow)
	if bars >= 1:
		draw_line(Vector2(top.x, r.position.y), Vector2(top.x, r.end.y), IRON, 3.0)
	if bars >= 1:
		draw_line(Vector2(r.position.x, top.y + (r.end.y - top.y) * 0.4), Vector2(r.end.x, top.y + (r.end.y - top.y) * 0.4), IRON, 3.0)
	if bars == 2:
		draw_line(Vector2(top.x, r.position.y), Vector2(top.x, r.end.y), IRON, 2.0)


func _valve_wheel(c: Vector2, rad: float, col: Color) -> void:
	draw_arc(c, rad, 0, TAU, 20, col, 2.5)
	for k in 4:
		var a := k * PI * 0.5 + 0.4
		draw_line(c, c + Vector2(cos(a), sin(a)) * rad, col, 2.0)
	draw_circle(c, rad * 0.25, IRON_HI)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _plank_frame(r: Rect2, col: Color, t: float) -> void:
	_rect(Rect2(r.position, Vector2(r.size.x, t)), col)
	_rect(Rect2(r.position.x, r.end.y - t, r.size.x, t), col)
	_rect(Rect2(r.position, Vector2(t, r.size.y)), col)
	_rect(Rect2(r.end.x - t, r.position.y, t, r.size.y), col)


func _rect(r: Rect2, c: Color) -> void:
	draw_rect(r, c, true)


func _outline(r: Rect2, c: Color, width: float) -> void:
	draw_rect(r, c, false, width)


func _rivet(p: Vector2, rad: float) -> void:
	draw_circle(p, rad, BRASS_LO)
	draw_circle(p - Vector2(0.6, 0.6), rad * 0.55, BRASS_HI)


func _corners(r: Rect2, inset: float) -> Array:
	return [r.position + Vector2(inset, inset), Vector2(r.end.x - inset, r.position.y + inset),
		Vector2(r.position.x + inset, r.end.y - inset), r.end - Vector2(inset, inset)]


func _bracket(c: Vector2, r: Rect2) -> void:
	var sx := 1.0 if c.x <= r.get_center().x else -1.0
	var sy := 1.0 if c.y <= r.get_center().y else -1.0
	_rect(Rect2(c.x if sx > 0 else c.x - 12, c.y if sy > 0 else c.y - 4, 12, 4), IRON_HI)
	_rect(Rect2(c.x if sx > 0 else c.x - 4, c.y if sy > 0 else c.y - 12, 4, 12), IRON_HI)
	_rivet(c + Vector2(6 * sx, 6 * sy), 1.6)


func _window(center: Vector2, s: Vector2) -> void:
	var r := Rect2(center - s * 0.5, s)
	_rect(r.grow(3), IRON)
	_rect(r, Color(LAMP, 0.7))
	draw_line(Vector2(center.x, r.position.y), Vector2(center.x, r.end.y), IRON, 2.0)
	draw_line(Vector2(r.position.x, center.y), Vector2(r.end.x, center.y), IRON, 2.0)


func _door(bottom: Vector2, knob: Color) -> void:
	_rect(Rect2(bottom + Vector2(-14, -36), Vector2(28, 36)), IRON)
	_rect(Rect2(bottom + Vector2(-11, -33), Vector2(22, 33)), WOOD_LO)
	draw_arc(bottom + Vector2(0, -33), 11.0, PI, TAU, 12, IRON, 3.0)
	draw_circle(bottom + Vector2(7, -16), 2.0, knob)


func _gear(c: Vector2, rad: float, col: Color, teeth: int = 8) -> void:
	for k in teeth:
		var a := TAU * float(k) / float(teeth)
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([
			c + dir * rad * 0.85 - side * rad * 0.16, c + dir * rad * 0.85 + side * rad * 0.16,
			c + dir * rad * 1.15 + side * rad * 0.11, c + dir * rad * 1.15 - side * rad * 0.11]), col)
	draw_circle(c, rad * 0.9, col)
	draw_circle(c, rad * 0.35, col.darkened(0.45))
