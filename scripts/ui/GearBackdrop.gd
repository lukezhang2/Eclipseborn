extends Node2D
class_name GearBackdrop
## Vibrant steel-and-brass title backdrop with real toothed gears + decor.


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	for c in get_children():
		c.queue_free()

	var wash := Polygon2D.new()
	wash.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)
	])
	wash.color = Color(0.09, 0.07, 0.08, 1.0)
	wash.z_index = -20
	add_child(wash)

	# Warm ember glow behind gears
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(200, 100), Vector2(1080, 80), Vector2(1200, 640), Vector2(80, 680)
	])
	glow.color = Color(0.35, 0.18, 0.08, 0.22)
	glow.z_index = -19
	add_child(glow)

	_add_pipe_decor()
	_add_rivet_panel(Vector2(80, 520), Vector2(220, 120))
	_add_rivet_panel(Vector2(980, 80), Vector2(240, 100))
	_add_valve(Vector2(200, 280))
	_add_valve(Vector2(1100, 400))

	var placements := [
		{"pos": Vector2(200, 180), "r": 78.0, "teeth": 16, "speed": 16.0, "brass": true},
		{"pos": Vector2(430, 540), "r": 100.0, "teeth": 20, "speed": -11.0, "brass": false},
		{"pos": Vector2(780, 190), "r": 120.0, "teeth": 22, "speed": 9.0, "brass": true},
		{"pos": Vector2(1080, 500), "r": 88.0, "teeth": 14, "speed": -20.0, "brass": false},
		{"pos": Vector2(640, 380), "r": 58.0, "teeth": 12, "speed": 26.0, "brass": true},
		{"pos": Vector2(320, 360), "r": 40.0, "teeth": 10, "speed": -30.0, "brass": false},
	]
	for p in placements:
		var g := _make_gear(float(p["r"]), int(p["teeth"]), bool(p["brass"]))
		g.position = p["pos"]
		g.set_meta("speed", float(p["speed"]))
		g.modulate = Color(1.05, 1.0, 0.95, 0.92)
		add_child(g)

	# Steam wisps
	for i in 6:
		var steam := Polygon2D.new()
		steam.position = Vector2(150 + i * 180, 600 + (i % 2) * 20)
		steam.color = Color(0.75, 0.78, 0.82, 0.12)
		steam.polygon = PackedVector2Array([
			Vector2(-20, 10), Vector2(20, 8), Vector2(28, -30), Vector2(-16, -26)
		])
		steam.z_index = -5
		add_child(steam)


func _process(delta: float) -> void:
	for g in get_children():
		if g is Node2D and g.has_meta("speed"):
			(g as Node2D).rotation_degrees += float(g.get_meta("speed")) * delta


func _add_pipe_decor() -> void:
	var pipe := Line2D.new()
	pipe.width = 18.0
	pipe.default_color = Color(0.42, 0.38, 0.32, 0.85)
	pipe.add_point(Vector2(40, 80))
	pipe.add_point(Vector2(400, 80))
	pipe.add_point(Vector2(400, 200))
	pipe.z_index = -15
	add_child(pipe)
	var shine := Line2D.new()
	shine.width = 5.0
	shine.default_color = Color(0.7, 0.62, 0.45, 0.5)
	shine.add_point(Vector2(40, 76))
	shine.add_point(Vector2(400, 76))
	shine.add_point(Vector2(400, 200))
	shine.z_index = -14
	add_child(shine)
	var pipe2 := Line2D.new()
	pipe2.width = 14.0
	pipe2.default_color = Color(0.38, 0.34, 0.3, 0.8)
	pipe2.add_point(Vector2(900, 640))
	pipe2.add_point(Vector2(1240, 640))
	pipe2.z_index = -15
	add_child(pipe2)


func _add_rivet_panel(pos: Vector2, size: Vector2) -> void:
	var panel := Polygon2D.new()
	panel.position = pos
	panel.color = Color(0.22, 0.18, 0.16, 0.7)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	panel.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	panel.z_index = -16
	add_child(panel)
	for corner in [Vector2(-hx + 10, -hy + 10), Vector2(hx - 10, -hy + 10), Vector2(-hx + 10, hy - 10), Vector2(hx - 10, hy - 10)]:
		var rivet := Polygon2D.new()
		rivet.position = pos + corner
		rivet.color = Color(0.65, 0.5, 0.28)
		rivet.polygon = PackedVector2Array([
			Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
		])
		rivet.z_index = -15
		add_child(rivet)


func _add_valve(pos: Vector2) -> void:
	var wheel := Polygon2D.new()
	wheel.position = pos
	wheel.color = Color(0.7, 0.25, 0.18)
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * (14.0 if i % 2 == 0 else 9.0))
	wheel.polygon = pts
	wheel.z_index = -12
	add_child(wheel)


static func make_title_gear(radius: float = 90.0, tooth_count: int = 16, brass: bool = true) -> Node2D:
	## Same steel/brass gear used on the title/boot menu.
	return _build_gear(radius, tooth_count, brass)


func _make_gear(radius: float, tooth_count: int, brass: bool) -> Node2D:
	return _build_gear(radius, tooth_count, brass)


static func _build_gear(radius: float, tooth_count: int, brass: bool) -> Node2D:
	## Involute-ish: thick rim, keyed hub, rectangular teeth with bevel highlights.
	var root := Node2D.new()
	var steel := Color(0.45, 0.44, 0.42) if not brass else Color(0.62, 0.48, 0.24)
	var steel_dark := steel.darkened(0.25)
	var steel_light := steel.lightened(0.2)

	# Outer disc under teeth
	var disc := Polygon2D.new()
	disc.polygon = _circle_poly(radius * 0.88, 36)
	disc.color = steel_dark
	root.add_child(disc)

	# Rim ring
	var ring := Polygon2D.new()
	ring.polygon = _ring_poly(radius * 0.88, radius * 0.62, 36)
	ring.color = steel
	root.add_child(ring)

	# Inner web
	var web := Polygon2D.new()
	web.polygon = _ring_poly(radius * 0.58, radius * 0.32, 28)
	web.color = steel.darkened(0.1)
	root.add_child(web)

	# Cross spokes with thickness
	for i in 6:
		var spoke := Polygon2D.new()
		spoke.color = steel_light
		spoke.polygon = PackedVector2Array([
			Vector2(-4, -radius * 0.58), Vector2(4, -radius * 0.58),
			Vector2(3.2, -radius * 0.3), Vector2(-3.2, -radius * 0.3),
		])
		spoke.rotation = i * TAU / 6.0
		root.add_child(spoke)

	# Hub + keyway
	var hub := Polygon2D.new()
	hub.polygon = _circle_poly(radius * 0.28, 20)
	hub.color = Color(0.55, 0.42, 0.22) if brass else Color(0.5, 0.48, 0.45)
	root.add_child(hub)
	var hole := Polygon2D.new()
	hole.polygon = _circle_poly(radius * 0.1, 12)
	hole.color = Color(0.06, 0.05, 0.05)
	root.add_child(hole)
	var key := Polygon2D.new()
	key.color = Color(0.08, 0.07, 0.07)
	key.polygon = PackedVector2Array([
		Vector2(-2, -radius * 0.1), Vector2(2, -radius * 0.1),
		Vector2(2, -radius * 0.22), Vector2(-2, -radius * 0.22),
	])
	root.add_child(key)

	# Teeth — trapezoid with highlight edge
	for i in tooth_count:
		var tooth := Node2D.new()
		tooth.rotation = i * TAU / float(tooth_count)
		var body := Polygon2D.new()
		var tw := radius * 0.14
		var th := radius * 0.22
		body.color = steel_light
		body.polygon = PackedVector2Array([
			Vector2(-tw, -radius * 0.86),
			Vector2(tw, -radius * 0.86),
			Vector2(tw * 0.72, -radius * 0.86 - th),
			Vector2(-tw * 0.72, -radius * 0.86 - th),
		])
		tooth.add_child(body)
		var hi := Polygon2D.new()
		hi.color = Color(1, 1, 1, 0.22)
		hi.polygon = PackedVector2Array([
			Vector2(-tw * 0.5, -radius * 0.86 - 2),
			Vector2(-tw * 0.2, -radius * 0.86 - 2),
			Vector2(-tw * 0.15, -radius * 0.86 - th + 2),
			Vector2(-tw * 0.45, -radius * 0.86 - th + 2),
		])
		tooth.add_child(hi)
		root.add_child(tooth)

	return root


static func _circle_poly(r: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


static func _ring_poly(outer: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * outer)
	for i in range(points - 1, -1, -1):
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * inner)
	return out
