extends Node2D
class_name LevelCommon
## Helpers for steel-and-steam rooms: floors, brick walls, windows, props, UI.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const UI_SCENE := preload("res://scenes/ui/GameUI.tscn")


static func add_steel_floor(parent: Node2D, x: float, y: float, width: float, height: float = 32.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	body.add_child(cs)
	var hx := width * 0.5
	var hy := height * 0.5
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	visual.color = Color(0.26, 0.27, 0.3)
	body.add_child(visual)
	# Plate seams
	var seams := Line2D.new()
	seams.width = 1.0
	seams.default_color = Color(0.12, 0.12, 0.14, 0.8)
	var i := -hx + 48.0
	while i < hx:
		seams.add_point(Vector2(i, -hy))
		seams.add_point(Vector2(i, hy))
		seams.add_point(Vector2(i, -hy))
		i += 48.0
	body.add_child(seams)
	# Rivets
	var rivets := Polygon2D.new()
	rivets.color = Color(0.5, 0.38, 0.22)
	var pts := PackedVector2Array()
	var rx := -hx + 16.0
	while rx < hx:
		for ry in [-hy + 6.0, hy - 8.0]:
			pts.append(Vector2(rx - 2, ry))
			pts.append(Vector2(rx + 2, ry))
			pts.append(Vector2(rx + 2, ry + 3))
			pts.append(Vector2(rx - 2, ry + 3))
		rx += 32.0
	rivets.polygon = pts
	body.add_child(rivets)
	parent.add_child(body)
	return body


static func add_cobble_floor(parent: Node2D, x: float, y: float, width: float, height: float = 36.0) -> StaticBody2D:
	var body := add_steel_floor(parent, x, y, width, height)
	# Overpaint as street cobble
	for c in body.get_children():
		if c is Polygon2D and c.color.r < 0.4:
			(c as Polygon2D).color = Color(0.22, 0.2, 0.19)
	var stones := Polygon2D.new()
	stones.color = Color(0.32, 0.3, 0.28, 0.55)
	var hx := width * 0.5
	var pts := PackedVector2Array()
	var sx := -hx + 10.0
	while sx < hx:
		pts.append(Vector2(sx, -8))
		pts.append(Vector2(sx + 14, -8))
		pts.append(Vector2(sx + 14, 4))
		pts.append(Vector2(sx, 4))
		sx += 22.0
	stones.polygon = pts
	body.add_child(stones)
	return body


static func add_wall(parent: Node2D, x: float, y: float, width: float, height: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	body.add_child(cs)
	var hx := width * 0.5
	var hy := height * 0.5
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	poly.color = Color(0.17, 0.15, 0.14)
	body.add_child(poly)
	parent.add_child(body)
	return body


static func add_brick_wall_face(parent: Node2D, x: float, y: float, width: float, height: float) -> void:
	## Decorative back wall (no collision) with brick courses.
	var face := Node2D.new()
	face.position = Vector2(x, y)
	face.z_index = -10
	var bg := Polygon2D.new()
	var hx := width * 0.5
	var hy := height * 0.5
	bg.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	bg.color = Color(0.14, 0.12, 0.11)
	face.add_child(bg)
	var row := 0
	var yy := -hy + 8.0
	while yy < hy:
		var offset := 12.0 if row % 2 == 1 else 0.0
		var xx := -hx + offset
		while xx < hx:
			var brick := Polygon2D.new()
			var bw := 28.0
			var bh := 12.0
			brick.polygon = PackedVector2Array([
				Vector2(xx, yy), Vector2(xx + bw - 2, yy),
				Vector2(xx + bw - 2, yy + bh - 2), Vector2(xx, yy + bh - 2)
			])
			brick.color = Color(0.28 + fmod(xx * 0.01, 0.06), 0.18, 0.14)
			face.add_child(brick)
			xx += bw
		yy += 14.0
		row += 1
	parent.add_child(face)


static func add_window(parent: Node2D, x: float, y: float, w: float = 48.0, h: float = 64.0, moonlit: bool = false) -> void:
	var frame := Polygon2D.new()
	frame.position = Vector2(x, y)
	frame.z_index = -8
	var hx := w * 0.5
	var hy := h * 0.5
	frame.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	frame.color = Color(0.25, 0.22, 0.18)
	parent.add_child(frame)
	var glass := Polygon2D.new()
	glass.position = Vector2(x, y)
	glass.z_index = -7
	glass.polygon = PackedVector2Array([
		Vector2(-hx + 4, -hy + 4), Vector2(hx - 4, -hy + 4),
		Vector2(hx - 4, hy - 4), Vector2(-hx + 4, hy - 4)
	])
	glass.color = Color(0.35, 0.45, 0.55, 0.35) if moonlit else Color(0.08, 0.1, 0.12, 0.7)
	parent.add_child(glass)
	var mullion := Line2D.new()
	mullion.z_index = -6
	mullion.width = 3.0
	mullion.default_color = Color(0.3, 0.26, 0.2)
	mullion.add_point(Vector2(x, y - hy + 4))
	mullion.add_point(Vector2(x, y + hy - 4))
	parent.add_child(mullion)


static func add_pipe(parent: Node2D, from: Vector2, to: Vector2, thick: float = 12.0) -> void:
	var line := Line2D.new()
	line.width = thick
	line.default_color = Color(0.38, 0.36, 0.33)
	line.add_point(from)
	line.add_point(to)
	parent.add_child(line)
	var shine := Line2D.new()
	shine.width = thick * 0.35
	shine.default_color = Color(0.55, 0.5, 0.42, 0.7)
	shine.add_point(from)
	shine.add_point(to)
	parent.add_child(shine)
	# Flange joint mid
	var mid := (from + to) * 0.5
	var flange := Polygon2D.new()
	flange.position = mid
	flange.color = Color(0.45, 0.35, 0.22)
	flange.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	parent.add_child(flange)


static func add_valve(parent: Node2D, pos: Vector2) -> void:
	var wheel := Polygon2D.new()
	wheel.position = pos
	wheel.color = Color(0.55, 0.2, 0.15)
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	wheel.polygon = pts
	parent.add_child(wheel)


static func add_crate_prop(parent: Node2D, pos: Vector2, size: Vector2 = Vector2(36, 28)) -> void:
	## Non-interactive scenery crate.
	var p := Polygon2D.new()
	p.position = pos
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	p.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	p.color = Color(0.35, 0.25, 0.16)
	parent.add_child(p)


static func add_bench(parent: Node2D, pos: Vector2) -> void:
	var seat := Polygon2D.new()
	seat.position = pos
	seat.color = Color(0.2, 0.18, 0.16)
	seat.polygon = PackedVector2Array([
		Vector2(-30, -8), Vector2(30, -8), Vector2(30, 0), Vector2(-30, 0)
	])
	parent.add_child(seat)
	var back := Polygon2D.new()
	back.position = pos + Vector2(0, -18)
	back.color = Color(0.18, 0.16, 0.14)
	back.polygon = PackedVector2Array([
		Vector2(-28, -10), Vector2(28, -10), Vector2(28, 10), Vector2(-28, 10)
	])
	parent.add_child(back)


static func add_lamp_post(parent: Node2D, pos: Vector2) -> void:
	var pole := Polygon2D.new()
	pole.position = pos
	pole.color = Color(0.2, 0.2, 0.22)
	pole.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(3, -90), Vector2(-3, -90)
	])
	parent.add_child(pole)
	var head := Polygon2D.new()
	head.position = pos + Vector2(0, -96)
	head.color = Color(0.45, 0.35, 0.2)
	head.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(10, 0), Vector2(8, -16), Vector2(-8, -16)
	])
	parent.add_child(head)


static func add_steam_vent(parent: Node2D, pos: Vector2) -> void:
	var grate := Polygon2D.new()
	grate.position = pos
	grate.color = Color(0.15, 0.15, 0.16)
	grate.polygon = PackedVector2Array([
		Vector2(-18, -4), Vector2(18, -4), Vector2(18, 4), Vector2(-18, 4)
	])
	parent.add_child(grate)
	var puff := Polygon2D.new()
	puff.position = pos + Vector2(0, -20)
	puff.color = Color(0.75, 0.75, 0.78, 0.25)
	puff.polygon = PackedVector2Array([
		Vector2(-8, 10), Vector2(8, 10), Vector2(14, -10), Vector2(-14, -10)
	])
	parent.add_child(puff)


static func add_backdrop(parent: Node2D, width: float, height: float) -> void:
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(0, -200), Vector2(width, -200), Vector2(width, height), Vector2(0, height)
	])
	bg.color = Color(0.05, 0.045, 0.055)
	bg.z_index = -20
	parent.add_child(bg)
	# Far soot gradient strips
	var strip := Polygon2D.new()
	strip.z_index = -19
	strip.color = Color(0.08, 0.06, 0.05, 0.5)
	strip.polygon = PackedVector2Array([
		Vector2(0, height - 120), Vector2(width, height - 160),
		Vector2(width, height), Vector2(0, height)
	])
	parent.add_child(strip)


static func spawn_player(parent: Node2D, pos: Vector2) -> Player:
	var p: Player = PLAYER_SCENE.instantiate()
	p.global_position = pos
	parent.add_child(p)
	GameState.set_checkpoint(pos)
	return p


static func spawn_ui(parent: Node) -> void:
	if parent.get_node_or_null("GameUI") != null:
		return
	parent.add_child(UI_SCENE.instantiate())


static func make_room_trigger(parent: Node2D, pos: Vector2, size: Vector2, zone: String, room: String, hint: String = "", action: String = "") -> void:
	var t := RoomTrigger.new()
	t.position = pos
	t.zone_id = zone
	t.room_id = room
	t.hint = hint
	t.hint_action = action
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	t.add_child(cs)
	parent.add_child(t)


static func make_shadow_root(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "ShadowRoot"
	parent.add_child(root)
	ShadowWorld.set_world_root(root)
	return root
