extends Control
## Whole-zone side view. Every editor piece, uniform scale, letterboxed into this control.


const PAD := 14.0

var zone_id: String = ""
var player_world: Vector2 = Vector2.ZERO
var has_player: bool = false

var _cache_zone: String = ""
var _pieces: Array = []
var _bounds: Rect2 = Rect2(0, 160, 800, 360)
var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _plate_font: Font


func set_zone_map(zone: String, p_player: Vector2, p_has_player: bool) -> void:
	zone_id = zone
	player_world = p_player
	has_player = p_has_player
	if zone != _cache_zone:
		_cache_zone = zone
		_pieces = MapAtlas.pieces_for(zone)
		_bounds = MapAtlas.content_bounds(_pieces)
	queue_redraw()


func _fit() -> void:
	var inner := size - Vector2(PAD * 2.0, PAD * 2.0)
	if _bounds.size.x < 1.0 or _bounds.size.y < 1.0 or inner.x < 8.0 or inner.y < 8.0:
		_scale = 1.0
		_origin = Vector2(PAD, PAD)
		return
	_scale = minf(inner.x / _bounds.size.x, inner.y / _bounds.size.y)
	var drawn := _bounds.size * _scale
	_origin = Vector2(PAD, PAD) + (inner - drawn) * 0.5 - _bounds.position * _scale


func _to_map(world: Vector2) -> Vector2:
	return _origin + world * _scale


func _map_rect(world_rect: Rect2) -> Rect2:
	return Rect2(_to_map(world_rect.position), world_rect.size * _scale)


func _draw() -> void:
	var wr := size
	if wr.x < 8.0 or wr.y < 8.0:
		return
	_fit()
	var veil := Color(0.05, 0.03, 0.07, 1.0)
	draw_rect(Rect2(Vector2.ZERO, wr), veil, true)
	if _pieces.is_empty():
		_draw_plaque("No map for this zone", Vector2(PAD, wr.y * 0.5 - 16.0), 18)
		_draw_frame(wr)
		return
	var fitted := Rect2(_to_map(_bounds.position), _bounds.size * _scale)
	draw_rect(fitted, Color("0d020f"), true)
	var band_h := clampf(fitted.size.y * 0.07, 6.0, 28.0)
	draw_rect(Rect2(fitted.position, Vector2(fitted.size.x, band_h)), Color(WorldArt.EMBER.r, WorldArt.EMBER.g, WorldArt.EMBER.b, 0.45), true)
	_draw_washes()
	for piece in _pieces:
		if typeof(piece) == TYPE_DICTIONARY:
			_draw_piece(piece)
	## Cover everything the camera has not framed, so the zone shape stays hidden.
	for span in GameState.map_hidden_spans(zone_id, _bounds):
		draw_rect(_map_rect(span), veil, true)
	_draw_seen_labels()
	_draw_plaque(_zone_title(), Vector2(16, 14), 20)
	_draw_frame(wr)
	if has_player:
		_draw_player_icon(_to_map(player_world))


func _draw_washes() -> void:
	for piece in _pieces:
		if typeof(piece) != TYPE_DICTIONARY:
			continue
		var kind := str(piece.get("kind", ""))
		if kind != "light" and kind != "prop_lantern":
			continue
		var radius := float(piece.get("radius", 0.0))
		if radius <= 1.0:
			continue
		var center := _to_map(Vector2(float(piece.get("x", 0.0)), float(piece.get("y", 0.0))))
		draw_circle(center, radius * _scale, Color(WorldArt.LAMP.r, WorldArt.LAMP.g, WorldArt.LAMP.b, 0.07))


func _draw_piece(piece: Dictionary) -> void:
	var kind := str(piece.get("kind", ""))
	var rect := _map_rect(MapAtlas.world_rect(piece))
	match kind:
		"floor", "block":
			_draw_floor(piece, rect)
		"wall", "background":
			_draw_brick(rect)
		"prop_platform":
			_draw_floor(piece, rect)
			_draw_platform_gear(piece)
		"prop_house":
			_draw_house(piece, rect)
		"prop_tower":
			_draw_tower(rect)
		"prop_bg_gear":
			_draw_gear(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.42, WorldArt.BRASS)
		"crate", "prop_crate":
			_draw_crate(rect)
		"light", "prop_lantern":
			_draw_lantern(piece, rect)
		"prop_window":
			_draw_window(rect)
		"prop_bench":
			_draw_bench(rect)
		"prop_vent":
			_draw_vent(rect)
		"prop_checkpoint":
			_draw_checkpoint(rect)
		"prop_switch":
			_draw_lever(rect)
		"prop_pipe":
			draw_rect(rect, WorldArt.IRON_MID, true)
			draw_rect(rect, WorldArt.BRASS_LO, false, 1.0)
		"prop_pickup":
			_draw_crystal(rect)
		"prop_enemy", "prop_npc":
			_draw_figure(rect, kind == "prop_enemy")
		"prop_hatch", "prop_exit":
			draw_rect(rect, WorldArt.WOOD, true)
			draw_line(rect.position + Vector2(0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x, rect.size.y * 0.5), WorldArt.BRASS_HI, 1.5)
		"prop_breakable":
			_draw_jar(rect)
		"prop_door":
			draw_rect(rect, WorldArt.WOOD, true)
			draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.55), maxf(1.5, rect.size.x * 0.12), WorldArt.BRASS)
		"prop_valve":
			_draw_gear(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.45, WorldArt.BRASS)
		"prop_ladder":
			_draw_ladder(rect)
		"prop_desk":
			draw_rect(rect, WorldArt.WOOD, true)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(2.0, rect.size.y * 0.25))), WorldArt.WOOD_HI, true)
		_:
			draw_rect(rect, WorldArt.IRON, true)


func _draw_floor(piece: Dictionary, rect: Rect2) -> void:
	var cobble := zone_id == "lantern_village" and str(piece.get("kind", "")) == "floor"
	draw_rect(rect, WorldArt.STONE if cobble else WorldArt.IRON_MID, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(1.0, rect.size.y * 0.18))), WorldArt.STONE_HI if cobble else WorldArt.IRON_HI, true)
	var step := 46.0 * _scale
	if step < 3.0:
		return
	var x := rect.position.x + step
	var seam := Color(WorldArt.STONE_LO.r, WorldArt.STONE_LO.g, WorldArt.STONE_LO.b, 0.65)
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), seam, 1.0)
		x += step


func _draw_brick(rect: Rect2) -> void:
	draw_rect(rect, WorldArt.BRICK, true)
	var course := maxf(3.0, 10.0 * _scale)
	var y := rect.position.y + course
	var mortar := Color(WorldArt.BRICK_HI.r, WorldArt.BRICK_HI.g, WorldArt.BRICK_HI.b, 0.7)
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), mortar, 1.0)
		y += course


func _draw_house(piece: Dictionary, rect: Rect2) -> void:
	var roof_h := rect.size.y * 0.28
	var roof := Rect2(rect.position, Vector2(rect.size.x, roof_h))
	var walls := Rect2(rect.position + Vector2(rect.size.x * 0.06, roof_h), Vector2(rect.size.x * 0.88, rect.size.y - roof_h))
	draw_rect(walls, WorldArt.BRICK, true)
	var peak := PackedVector2Array([
		roof.position + Vector2(-2, roof.size.y),
		roof.position + Vector2(roof.size.x + 2, roof.size.y),
		roof.position + Vector2(roof.size.x * 0.5, 0),
	])
	draw_colored_polygon(peak, WorldArt.SLATE)
	var door := Rect2(walls.position + Vector2(walls.size.x * 0.38, walls.size.y * 0.45), Vector2(walls.size.x * 0.24, walls.size.y * 0.55))
	draw_rect(door, WorldArt.BRASS_LO, true)
	var window := Rect2(walls.position + Vector2(walls.size.x * 0.12, walls.size.y * 0.18), Vector2(walls.size.x * 0.22, walls.size.y * 0.22))
	draw_rect(window, WorldArt.LAMP, true)


func _draw_tower(rect: Rect2) -> void:
	draw_rect(rect, WorldArt.BRICK, true)
	var clock_r := minf(rect.size.x, rect.size.y) * 0.18
	var clock_c := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.16)
	draw_circle(clock_c, clock_r, WorldArt.BRASS)
	draw_circle(clock_c, clock_r * 0.72, WorldArt.IRON)
	var win_w := maxf(2.0, rect.size.x * 0.16)
	var win_h := maxf(3.0, rect.size.y * 0.05)
	var y := rect.position.y + rect.size.y * 0.32
	while y < rect.end.y - win_h:
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.22, y, win_w, win_h), WorldArt.LAMP, true)
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.62, y, win_w, win_h), WorldArt.LAMP, true)
		y += win_h * 2.4


func _draw_platform_gear(piece: Dictionary) -> void:
	if not bool(piece.get("with_gear", true)):
		return
	var center := _to_map(Vector2(
		float(piece.get("x", 0.0)) + float(piece.get("gear_dx", -70.0)),
		float(piece.get("y", 0.0)) + float(piece.get("gear_dy", -50.0))
	))
	_draw_gear(center, 28.0 * _scale, WorldArt.BRASS)


func _draw_gear(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1.5:
		draw_circle(center, maxf(radius, 1.0), color)
		return
	draw_circle(center, radius, color)
	draw_circle(center, radius * 0.45, WorldArt.IRON)
	var tooth := radius * 0.28
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var dir := Vector2.from_angle(ang)
		draw_line(center + dir * radius * 0.72, center + dir * (radius + tooth), color, maxf(1.0, radius * 0.22))


func _draw_crate(rect: Rect2) -> void:
	draw_rect(rect, WorldArt.WOOD, true)
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * 0.28, rect.size.x, maxf(1.0, rect.size.y * 0.12)), WorldArt.IRON_HI, true)
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * 0.64, rect.size.x, maxf(1.0, rect.size.y * 0.12)), WorldArt.IRON_HI, true)


func _draw_lantern(piece: Dictionary, rect: Rect2) -> void:
	var chain_top := _to_map(Vector2(float(piece.get("x", 0.0)), float(piece.get("y", 0.0)) - 40.0))
	var cage := rect
	draw_line(chain_top, cage.get_center() + Vector2(0, -cage.size.y * 0.4), WorldArt.BRASS_LO, 1.0)
	draw_rect(cage, WorldArt.BRASS, true)
	draw_rect(cage.grow(-maxf(1.0, cage.size.x * 0.18)), WorldArt.LAMP_CORE, true)


func _draw_window(rect: Rect2) -> void:
	draw_rect(rect, WorldArt.SLATE, true)
	draw_rect(rect.grow(-maxf(1.0, rect.size.x * 0.16)), WorldArt.LAMP, true)


func _draw_bench(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(2.0, rect.size.y * 0.35))), WorldArt.WOOD, true)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.35), Vector2(maxf(2.0, rect.size.x * 0.1), rect.size.y * 0.65)), WorldArt.WOOD_HI, true)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.35), Vector2(maxf(2.0, rect.size.x * 0.1), rect.size.y * 0.65)), WorldArt.WOOD_HI, true)


func _draw_vent(rect: Rect2) -> void:
	draw_rect(rect, WorldArt.IRON, true)
	var slit := maxf(2.0, rect.size.x / 4.0)
	var x := rect.position.x + slit * 0.4
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y + 1.0), Vector2(x, rect.end.y - 1.0), WorldArt.IRON_HI, 1.0)
		x += slit


func _draw_checkpoint(rect: Rect2) -> void:
	var post_w := maxf(2.0, rect.size.x * 0.12)
	draw_rect(Rect2(rect.position.x, rect.position.y, post_w, rect.size.y), WorldArt.IRON_HI, true)
	draw_rect(Rect2(rect.end.x - post_w, rect.position.y, post_w, rect.size.y), WorldArt.IRON_HI, true)
	draw_circle(rect.get_center(), maxf(2.0, minf(rect.size.x, rect.size.y) * 0.28), WorldArt.EMBER)


func _draw_lever(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.72), Vector2(rect.size.x, rect.size.y * 0.28)), WorldArt.WOOD, true)
	draw_line(rect.get_center() + Vector2(0, rect.size.y * 0.2), rect.position + Vector2(rect.size.x * 0.72, rect.size.y * 0.15), WorldArt.BRASS_HI, maxf(1.5, rect.size.x * 0.12))


func _draw_crystal(rect: Rect2) -> void:
	var c := rect.get_center()
	var diamond := PackedVector2Array([
		c + Vector2(0, -rect.size.y * 0.5),
		c + Vector2(rect.size.x * 0.5, 0),
		c + Vector2(0, rect.size.y * 0.5),
		c + Vector2(-rect.size.x * 0.5, 0),
	])
	draw_colored_polygon(diamond, WorldArt.EMBER)


func _draw_figure(rect: Rect2, hostile: bool) -> void:
	draw_rect(rect, Color(0.08, 0.05, 0.08) if hostile else WorldArt.INK, true)
	draw_circle(rect.position + Vector2(rect.size.x * 0.35, rect.size.y * 0.28), maxf(1.0, rect.size.x * 0.08), WorldArt.BRASS_HI)
	draw_circle(rect.position + Vector2(rect.size.x * 0.65, rect.size.y * 0.28), maxf(1.0, rect.size.x * 0.08), WorldArt.BRASS_HI)


func _draw_jar(rect: Rect2) -> void:
	draw_rect(rect, Color(WorldArt.INK_HI.r, WorldArt.INK_HI.g, WorldArt.INK_HI.b, 0.85), true)
	draw_circle(rect.get_center(), maxf(1.5, minf(rect.size.x, rect.size.y) * 0.22), WorldArt.LAMP_CORE)


func _draw_ladder(rect: Rect2) -> void:
	var rail := maxf(1.5, rect.size.x * 0.16)
	draw_rect(Rect2(rect.position, Vector2(rail, rect.size.y)), WorldArt.WOOD, true)
	draw_rect(Rect2(Vector2(rect.end.x - rail, rect.position.y), Vector2(rail, rect.size.y)), WorldArt.WOOD, true)
	var step := maxf(4.0, 18.0 * _scale)
	var y := rect.position.y + step
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), WorldArt.WOOD_HI, 1.5)
		y += step


func _zone_title() -> String:
	var raw := zone_id.replace("_", " ")
	if raw == "":
		return "Unknown"
	return raw.capitalize()


func _font() -> Font:
	if _plate_font == null:
		_plate_font = UITheme.spaced_font(1, 0.2)
	return _plate_font


func _draw_seen_labels() -> void:
	for piece in _pieces:
		if typeof(piece) != TYPE_DICTIONARY:
			continue
		if str(piece.get("kind", "")) != "prop_house":
			continue
		var world := MapAtlas.world_rect(piece)
		if not GameState.map_cell_seen(zone_id, world.get_center()):
			continue
		var rect := _map_rect(world)
		var walls := Rect2(
			rect.position + Vector2(rect.size.x * 0.06, rect.size.y * 0.28),
			Vector2(rect.size.x * 0.88, rect.size.y * 0.72)
		)
		var label := str(piece.get("name", "")).replace("House: ", "")
		if label == "" or walls.size.x < 36.0:
			continue
		_draw_plaque(label, Vector2.ZERO, 12, Vector2(walls.get_center().x, walls.position.y + 4.0))


func _draw_plaque(text: String, at: Vector2, font_size: int, anchor: Vector2 = Vector2(INF, INF)) -> void:
	var font := _font()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pad := Vector2(8, 3)
	var box := Rect2(Vector2.ZERO, text_size + pad * 2.0)
	if is_finite(anchor.x):
		box.position = Vector2(anchor.x - box.size.x * 0.5, anchor.y)
	else:
		box.position = at
	box.position.x = clampf(box.position.x, 8.0, maxf(8.0, size.x - box.size.x - 8.0))
	box.position.y = clampf(box.position.y, 8.0, maxf(8.0, size.y - box.size.y - 8.0))
	draw_rect(box, Color(UITheme.IRON, 0.94), true)
	draw_rect(box, UITheme.BRASS, false, 1.5)
	var baseline := box.position + Vector2(pad.x, pad.y + font.get_ascent(font_size))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UITheme.BRASS_LIGHT)


func _draw_frame(wr: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, wr), WorldArt.BRASS, false, 3.0)
	draw_rect(Rect2(Vector2(5, 5), wr - Vector2(10, 10)), WorldArt.BRASS_LO, false, 1.0)


func _draw_player_icon(p: Vector2) -> void:
	draw_arc(p + Vector2(0, -8), 16.0, 0.0, TAU, 24, Color(WorldArt.LAMP.r, WorldArt.LAMP.g, WorldArt.LAMP.b, 0.45), 1.5)
	var body := PackedVector2Array([
		p + Vector2(0, -22),
		p + Vector2(9, -10),
		p + Vector2(7, 4),
		p + Vector2(-7, 4),
		p + Vector2(-9, -10),
	])
	draw_colored_polygon(body, Color(0.04, 0.03, 0.06, 1.0))
	draw_circle(p + Vector2(-3.5, -14), 2.2, Color(0.98, 0.96, 0.9))
	draw_circle(p + Vector2(3.5, -14), 2.2, Color(0.98, 0.96, 0.9))
