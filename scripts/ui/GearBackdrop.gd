extends Node2D
class_name GearBackdrop
## Shared steel-gear title background used by boot splash and title menu.


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	for c in get_children():
		c.queue_free()
	# Soft steam wash
	var wash := Polygon2D.new()
	wash.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)
	])
	wash.color = Color(0.07, 0.06, 0.055, 1.0)
	wash.z_index = -20
	add_child(wash)

	var placements := [
		{"pos": Vector2(180, 160), "r": 70.0, "teeth": 14, "speed": 18.0},
		{"pos": Vector2(420, 520), "r": 95.0, "teeth": 16, "speed": -12.0},
		{"pos": Vector2(760, 200), "r": 110.0, "teeth": 18, "speed": 10.0},
		{"pos": Vector2(1080, 480), "r": 80.0, "teeth": 12, "speed": -22.0},
		{"pos": Vector2(640, 360), "r": 55.0, "teeth": 10, "speed": 28.0},
	]
	for p in placements:
		var g := _make_gear(float(p["r"]), int(p["teeth"]))
		g.position = p["pos"]
		g.set_meta("speed", float(p["speed"]))
		g.modulate = Color(1, 1, 1, 0.55)
		add_child(g)


func _process(delta: float) -> void:
	for g in get_children():
		if g is Node2D and g.has_meta("speed"):
			(g as Node2D).rotation_degrees += float(g.get_meta("speed")) * delta


func _make_gear(radius: float, tooth_count: int) -> Node2D:
	var root := Node2D.new()
	var ring := Polygon2D.new()
	ring.polygon = _ring_poly(radius, radius * 0.7, 32)
	ring.color = Color(0.32, 0.3, 0.27)
	root.add_child(ring)
	var hub := Polygon2D.new()
	hub.polygon = _circle_poly(radius * 0.3, 18)
	hub.color = Color(0.5, 0.38, 0.2)
	root.add_child(hub)
	var hole := Polygon2D.new()
	hole.polygon = _circle_poly(radius * 0.12, 12)
	hole.color = Color(0.08, 0.07, 0.06)
	root.add_child(hole)
	for i in 4:
		var spoke := Polygon2D.new()
		spoke.color = Color(0.4, 0.35, 0.28)
		spoke.polygon = PackedVector2Array([
			Vector2(-3, -radius * 0.65), Vector2(3, -radius * 0.65),
			Vector2(3, -radius * 0.32), Vector2(-3, -radius * 0.32),
		])
		spoke.rotation = i * TAU / 4.0
		root.add_child(spoke)
	for i in tooth_count:
		var tooth := Polygon2D.new()
		tooth.color = Color(0.48, 0.36, 0.2)
		var tw := radius * 0.16
		var th := radius * 0.26
		tooth.polygon = PackedVector2Array([
			Vector2(-tw, -radius), Vector2(tw, -radius),
			Vector2(tw * 0.65, -radius + th), Vector2(-tw * 0.65, -radius + th),
		])
		tooth.rotation = i * TAU / float(tooth_count)
		root.add_child(tooth)
	return root


func _circle_poly(r: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


func _ring_poly(outer: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * outer)
	for i in range(points - 1, -1, -1):
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * inner)
	return out
