extends Node2D
class_name BlackFireSky
## Full-field purple void; animated black-fire tongues only along the TOP of the playfield.


## Standard world void — #0d020f. Zones layer other art on top when needed.
const DEFAULT_VOID := Color("0d020f")
const DEFAULT_FLAME_BAND_OFFSET := 12.0 ## World Y = roof_top + offset (smaller → higher).

var floor_top: float = 500.0
var roof_top: float = 180.0
var map_width: float = 4000.0
## World Y where flame roots sit (camera top band).
var flame_band_y: float = 182.0
var flame_band_offset: float = DEFAULT_FLAME_BAND_OFFSET
var void_color: Color = DEFAULT_VOID
var flame_count: int = 48
var _flames: Array = []
var _void_poly: Polygon2D
var _t: float = 0.0


func setup(width: float, floor_y_top: float, roof_y_top: float = 180.0, settings: Dictionary = {}) -> void:
	map_width = width
	floor_top = floor_y_top
	roof_top = roof_y_top
	apply_settings(settings)
	## Above the optional city fill plate (−26), under brick/silhouette props (−17).
	z_index = -25
	_rebuild()


func apply_settings(settings: Dictionary) -> void:
	if settings.is_empty():
		flame_band_offset = DEFAULT_FLAME_BAND_OFFSET
		void_color = DEFAULT_VOID
		flame_count = 48
	else:
		flame_band_offset = float(settings.get("flame_band_offset", DEFAULT_FLAME_BAND_OFFSET))
		flame_count = int(settings.get("flame_count", 48))
		void_color = _color_from(settings.get("void_color", null), DEFAULT_VOID)
	flame_band_y = roof_top + flame_band_offset


func rebuild_with_settings(settings: Dictionary) -> void:
	apply_settings(settings)
	_rebuild()


func settings_dict() -> Dictionary:
	return {
		"kind": "black_fire",
		"enabled": true,
		"flame_band_offset": flame_band_offset,
		"flame_count": flame_count,
		"void_color": [void_color.r, void_color.g, void_color.b, void_color.a],
	}


static func _color_from(raw: Variant, fallback: Color) -> Color:
	if raw is Color:
		return raw
	if raw is Array and (raw as Array).size() >= 3:
		var a: Array = raw
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	if raw is Dictionary:
		var d: Dictionary = raw
		return Color(
			float(d.get("r", fallback.r)),
			float(d.get("g", fallback.g)),
			float(d.get("b", fallback.b)),
			float(d.get("a", fallback.a))
		)
	return fallback


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_flames.clear()
	_build()


func _build() -> void:
	## Full playfield — same purple as the fire aura (no near-black void).
	_void_poly = Polygon2D.new()
	_void_poly.polygon = PackedVector2Array([
		Vector2(-200, minf(roof_top, flame_band_y) - 160.0),
		Vector2(map_width + 200, minf(roof_top, flame_band_y) - 160.0),
		Vector2(map_width + 200, floor_top + 120.0),
		Vector2(-200, floor_top + 120.0)
	])
	_void_poly.color = void_color
	add_child(_void_poly)

	## Animated tongues only in a thin band at the top of the screen.
	var n := maxi(flame_count, 8)
	for i in n:
		var flame := Node2D.new()
		flame.position = Vector2(
			float(i) * (map_width / float(maxi(n - 2, 1))) - 40.0,
			flame_band_y + randf_range(-4.0, 6.0)
		)
		flame.set_meta("phase", randf() * TAU)
		flame.set_meta("speed", randf_range(2.2, 4.8))
		## Shorter hang so animation stays a top fringe, not a mid-screen wash.
		flame.set_meta("h", randf_range(36.0, 68.0))
		var poly := Polygon2D.new()
		poly.color = Color(0.06, 0.02, 0.1, 0.95)
		poly.name = "Body"
		flame.add_child(poly)
		var tip := Polygon2D.new()
		tip.color = Color(0.16, 0.05, 0.2, 0.8)
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
		## Hang DOWN into the playfield (+Y); roots stay in the top band.
		body.polygon = PackedVector2Array([
			Vector2(-11, 0), Vector2(11, 0),
			Vector2(6 + lean * 0.3, height * 0.55),
			Vector2(-6 + lean * 0.3, height * 0.55),
		])
		tip.polygon = PackedVector2Array([
			Vector2(-5 + lean * 0.2, height * 0.45),
			Vector2(5 + lean * 0.2, height * 0.45),
			Vector2(lean, height),
		])
		body.color.a = 0.75 + 0.2 * flicker
		tip.color.a = 0.5 + 0.35 * flicker
