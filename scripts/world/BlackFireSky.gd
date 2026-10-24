extends Node2D
class_name BlackFireSky
## Black-fire burn along the TOP of the outside void — never under the floor.


var floor_top: float = 500.0
var map_width: float = 4000.0
var _flames: Array = []
var _t: float = 0.0


func setup(width: float, floor_y_top: float) -> void:
	map_width = width
	floor_top = floor_y_top
	z_index = -25
	_build()


func _build() -> void:
	# Deep void above the playfield only (y from -80 to just above ceiling strip).
	var void_poly := Polygon2D.new()
	void_poly.polygon = PackedVector2Array([
		Vector2(-200, -120), Vector2(map_width + 200, -120),
		Vector2(map_width + 200, 70), Vector2(-200, 70)
	])
	void_poly.color = Color(0.02, 0.01, 0.03, 1.0)
	add_child(void_poly)

	# Flame tongues along the top edge of the sky band (screen-top of the outside).
	for i in 48:
		var flame := Node2D.new()
		flame.position = Vector2(i * (map_width / 40.0) - 40.0, 8.0 + randf_range(-6, 10))
		flame.set_meta("phase", randf() * TAU)
		flame.set_meta("speed", randf_range(2.5, 5.0))
		flame.set_meta("h", randf_range(28.0, 55.0))
		var poly := Polygon2D.new()
		poly.color = Color(0.04, 0.02, 0.06, 0.95)
		poly.name = "Body"
		flame.add_child(poly)
		var tip := Polygon2D.new()
		tip.color = Color(0.12, 0.05, 0.16, 0.7)
		tip.name = "Tip"
		flame.add_child(tip)
		add_child(flame)
		_flames.append(flame)


func _process(delta: float) -> void:
	_t += delta
	for flame in _flames:
		if not is_instance_valid(flame):
			continue
		var phase: float = flame.get_meta("phase")
		var speed: float = flame.get_meta("speed")
		var h: float = flame.get_meta("h")
		var flicker := 0.65 + 0.35 * sin(_t * speed + phase)
		var height := h * flicker
		var lean := sin(_t * speed * 0.7 + phase) * 8.0
		var body: Polygon2D = flame.get_node("Body")
		var tip: Polygon2D = flame.get_node("Tip")
		# Flames rise upward (negative Y) from the sky band — never downward into the map.
		body.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(10, 0),
			Vector2(6 + lean * 0.3, -height * 0.55),
			Vector2(-6 + lean * 0.3, -height * 0.55),
		])
		tip.polygon = PackedVector2Array([
			Vector2(-5 + lean * 0.2, -height * 0.45),
			Vector2(5 + lean * 0.2, -height * 0.45),
			Vector2(lean, -height),
		])
		body.color.a = 0.75 + 0.2 * flicker
		tip.color.a = 0.45 + 0.35 * flicker
