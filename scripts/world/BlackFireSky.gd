extends Node2D
class_name BlackFireSky
## Black-fire along the TOP of the visible playfield — hangs down into frame (not off-screen above).


var floor_top: float = 500.0
var roof_top: float = 180.0
var map_width: float = 4000.0
## World Y where flame roots sit (inside the camera’s top band).
var flame_band_y: float = 220.0
var _flames: Array = []
var _t: float = 0.0


func setup(width: float, floor_y_top: float, roof_y_top: float = 180.0) -> void:
	map_width = width
	floor_top = floor_y_top
	roof_top = roof_y_top
	## Sit the fire just below the roof/camera top so tongues hang into view.
	flame_band_y = roof_y_top + 52.0
	z_index = -25
	_build()


func _build() -> void:
	## Deep void behind the playfield.
	var void_poly := Polygon2D.new()
	void_poly.polygon = PackedVector2Array([
		Vector2(-200, -120), Vector2(map_width + 200, -120),
		Vector2(map_width + 200, floor_top + 8.0), Vector2(-200, floor_top + 8.0)
	])
	void_poly.color = Color(0.02, 0.01, 0.03, 1.0)
	add_child(void_poly)

	## Soft ember haze under the flame band (helps the top read as fire, not empty void).
	var haze := Polygon2D.new()
	haze.z_index = 0
	haze.color = Color(0.08, 0.03, 0.1, 0.35)
	haze.polygon = PackedVector2Array([
		Vector2(-200, flame_band_y - 10.0), Vector2(map_width + 200, flame_band_y - 10.0),
		Vector2(map_width + 200, flame_band_y + 90.0), Vector2(-200, flame_band_y + 90.0)
	])
	add_child(haze)

	for i in 56:
		var flame := Node2D.new()
		flame.position = Vector2(
			i * (map_width / 48.0) - 50.0,
			flame_band_y + randf_range(-6.0, 10.0)
		)
		flame.set_meta("phase", randf() * TAU)
		flame.set_meta("speed", randf_range(2.2, 4.8))
		flame.set_meta("h", randf_range(48.0, 92.0))
		var poly := Polygon2D.new()
		poly.color = Color(0.05, 0.02, 0.08, 0.95)
		poly.name = "Body"
		flame.add_child(poly)
		var tip := Polygon2D.new()
		tip.color = Color(0.14, 0.05, 0.18, 0.75)
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
		var lean := sin(_t * speed * 0.7 + phase) * 10.0
		var body: Polygon2D = flame.get_node("Body")
		var tip: Polygon2D = flame.get_node("Tip")
		## Hang DOWN into the playfield (+Y) so the fire stays on-screen.
		body.polygon = PackedVector2Array([
			Vector2(-12, 0), Vector2(12, 0),
			Vector2(7 + lean * 0.3, height * 0.55),
			Vector2(-7 + lean * 0.3, height * 0.55),
		])
		tip.polygon = PackedVector2Array([
			Vector2(-6 + lean * 0.2, height * 0.45),
			Vector2(6 + lean * 0.2, height * 0.45),
			Vector2(lean, height),
		])
		body.color.a = 0.75 + 0.2 * flicker
		tip.color.a = 0.5 + 0.35 * flicker
