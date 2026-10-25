extends Control
## Continuous side-view zone picture with a live player icon.


var zone_id: String = ""
var discovered: Array = []
var world_x_range: Vector2 = Vector2(0, 4000)
var world_y_range: Vector2 = Vector2(160, 520)
var landmarks: Array = [] ## {id, x, y?, kind, label}
var rooms: Array = [] ## {id, x0, x1} for fog
var player_world: Vector2 = Vector2.ZERO
var has_player: bool = false


func set_picture_data(
	p_zone: String,
	p_discovered: Array,
	p_x_range: Vector2,
	p_y_range: Vector2,
	p_landmarks: Array,
	p_rooms: Array,
	p_player: Vector2,
	p_has_player: bool
) -> void:
	zone_id = p_zone
	discovered = p_discovered
	world_x_range = p_x_range
	world_y_range = p_y_range
	landmarks = p_landmarks
	rooms = p_rooms
	player_world = p_player
	has_player = p_has_player
	queue_redraw()


func _world_to_map(world: Vector2) -> Vector2:
	var wr := size
	if wr.x < 8.0 or wr.y < 8.0:
		return Vector2.ZERO
	var pad := Vector2(28, 36)
	var inner := wr - pad * 2.0
	var nx := 0.0
	var ny := 0.5
	if world_x_range.y > world_x_range.x:
		nx = clampf((world.x - world_x_range.x) / (world_x_range.y - world_x_range.x), 0.0, 1.0)
	if world_y_range.y > world_y_range.x:
		ny = clampf((world.y - world_y_range.x) / (world_y_range.y - world_y_range.x), 0.0, 1.0)
	return pad + Vector2(nx * inner.x, ny * inner.y)


func _room_known(id: String) -> bool:
	return discovered.has(id)


func _x_discovered(world_x: float) -> bool:
	## A vertical strip is known if any discovered room covers that x.
	if rooms.is_empty():
		return true
	for room in rooms:
		if not _room_known(str(room.get("id", ""))):
			continue
		if world_x >= float(room.get("x0", 0)) and world_x <= float(room.get("x1", 0)):
			return true
	return false


func _draw() -> void:
	var wr := size
	if wr.x < 8.0 or wr.y < 8.0:
		return
	_draw_parchment(wr)
	_draw_continuous_ground(wr)
	## Silhouettes first so the whole zone reads as one picture under fog.
	_draw_landmarks(false)
	_draw_fog(wr)
	## Known landmarks + labels on top of the veil.
	_draw_landmarks(true)
	_draw_frame(wr)
	if has_player:
		_draw_player_icon(_world_to_map(player_world))


func _draw_parchment(wr: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, wr), Color(0.12, 0.1, 0.09, 0.92), true)
	## Soft vignette bands
	draw_rect(Rect2(0, 0, wr.x, 18), Color(0.06, 0.05, 0.04, 0.55), true)
	draw_rect(Rect2(0, wr.y - 22, wr.x, 22), Color(0.06, 0.05, 0.04, 0.55), true)
	## Faint grid of stitch lines (map cloth)
	var col := Color(0.35, 0.28, 0.2, 0.12)
	var x := 40.0
	while x < wr.x - 20.0:
		draw_line(Vector2(x, 24), Vector2(x, wr.y - 28), col, 1.0)
		x += 80.0


func _draw_continuous_ground(wr: Vector2) -> void:
	## One unbroken floor ribbon across the zone picture.
	var left := _world_to_map(Vector2(world_x_range.x, world_y_range.y))
	var right := _world_to_map(Vector2(world_x_range.y, world_y_range.y))
	var roof_l := _world_to_map(Vector2(world_x_range.x, world_y_range.x))
	var floor_y := left.y
	var roof_y := roof_l.y
	var span_w := right.x - left.x
	## Soft depth wash (far wall → mid air) so the strip reads as one scene
	draw_rect(
		Rect2(Vector2(left.x, roof_y), Vector2(span_w, floor_y - roof_y)),
		Color(0.14, 0.12, 0.16, 0.7),
		true
	)
	## Mid-tone band suggests wall height along the whole zone
	var mid_y := lerpf(roof_y, floor_y, 0.35)
	draw_rect(
		Rect2(Vector2(left.x, mid_y), Vector2(span_w, floor_y - mid_y)),
		Color(0.2, 0.17, 0.15, 0.45),
		true
	)
	## Floor band
	var floor_h := maxf(14.0, wr.y - floor_y - 28.0)
	draw_rect(
		Rect2(Vector2(left.x, floor_y), Vector2(span_w, floor_h)),
		Color(0.28, 0.26, 0.24, 0.95),
		true
	)
	draw_line(Vector2(left.x, floor_y), Vector2(right.x, floor_y), Color(0.7, 0.58, 0.38, 0.85), 2.5)
	## Thin roof rail
	draw_line(Vector2(left.x, roof_y), Vector2(right.x, roof_y), Color(0.45, 0.38, 0.3, 0.5), 1.5)
	## Path ticks along the floor so travel distance is readable
	var tick_col := Color(0.55, 0.45, 0.3, 0.35)
	var wx := world_x_range.x
	var step := 200.0
	while wx <= world_x_range.y + 0.1:
		var tx := _world_to_map(Vector2(wx, world_y_range.y)).x
		draw_line(Vector2(tx, floor_y), Vector2(tx, floor_y + 8.0), tick_col, 1.0)
		wx += step


func _draw_landmarks(known_only: bool) -> void:
	for lm in landmarks:
		var id := str(lm.get("id", ""))
		## Fog/detail keyed by containing room when provided (houses share a street room).
		var room_key := str(lm.get("room", id))
		var known := _room_known(room_key) if room_key != "" else true
		if known_only and not known:
			continue
		if not known_only and known:
			## Known marks are drawn in the second pass (above fog).
			continue
		var wx := float(lm.get("x", 0))
		var wy := float(lm.get("y", world_y_range.y))
		var p := _world_to_map(Vector2(wx, wy))
		var kind := str(lm.get("kind", "mark"))
		## Unknown: readable silhouette under the veil. Known: full detail + label.
		var alpha := 1.0 if known else 0.55
		match kind:
			"house":
				_draw_house_mark(p, alpha)
			"hatch":
				_draw_hatch_mark(p, alpha)
			"tower":
				_draw_tower_mark(p, alpha)
			"lamp":
				_draw_lamp_mark(p, alpha)
			"platform":
				_draw_platform_mark(p, alpha)
			_:
				_draw_generic_mark(p, alpha)
		if known:
			var label := str(lm.get("label", id))
			if label != "":
				draw_string(
					ThemeDB.fallback_font,
					p + Vector2(-24, -46),
					label,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					13,
					Color(0.88, 0.8, 0.62, 0.95)
				)


func _draw_house_mark(p: Vector2, a: float) -> void:
	var wall := PackedVector2Array([
		p + Vector2(-18, 0), p + Vector2(18, 0), p + Vector2(18, -28), p + Vector2(-18, -28)
	])
	draw_colored_polygon(wall, Color(0.32, 0.26, 0.22, a))
	var roof := PackedVector2Array([
		p + Vector2(-22, -28), p + Vector2(22, -28), p + Vector2(0, -44)
	])
	draw_colored_polygon(roof, Color(0.45, 0.22, 0.18, a))


func _draw_hatch_mark(p: Vector2, a: float) -> void:
	draw_rect(Rect2(p + Vector2(-16, -4), Vector2(32, 8)), Color(0.4, 0.35, 0.28, a), true)
	draw_line(p + Vector2(-16, 0), p + Vector2(16, 0), Color(0.7, 0.55, 0.3, a), 2.0)


func _draw_tower_mark(p: Vector2, a: float) -> void:
	draw_rect(Rect2(p + Vector2(-12, -70), Vector2(24, 70)), Color(0.3, 0.28, 0.26, a), true)
	draw_circle(p + Vector2(0, -78), 10.0, Color(0.5, 0.42, 0.28, a))


func _draw_lamp_mark(p: Vector2, a: float) -> void:
	draw_circle(p + Vector2(0, -10), 6.0, Color(1.0, 0.75, 0.35, a * 0.85))
	draw_line(p + Vector2(0, -4), p + Vector2(0, 0), Color(0.5, 0.45, 0.35, a), 2.0)


func _draw_platform_mark(p: Vector2, a: float) -> void:
	draw_rect(Rect2(p + Vector2(-20, -6), Vector2(40, 6)), Color(0.4, 0.38, 0.36, a), true)


func _draw_generic_mark(p: Vector2, a: float) -> void:
	draw_circle(p + Vector2(0, -8), 5.0, Color(0.55, 0.5, 0.4, a))


func _draw_fog(wr: Vector2) -> void:
	## Soft veil on undiscovered spans — panorama + silhouettes stay readable underneath.
	if rooms.is_empty():
		return
	var pad := 28.0
	for room in rooms:
		var id := str(room.get("id", ""))
		if _room_known(id):
			continue
		var x0 := _world_to_map(Vector2(float(room.get("x0", 0)), world_y_range.y)).x
		var x1 := _world_to_map(Vector2(float(room.get("x1", 0)), world_y_range.y)).x
		var w := maxf(4.0, x1 - x0)
		draw_rect(
			Rect2(Vector2(x0, pad), Vector2(w, wr.y - pad * 2.0)),
			Color(0.05, 0.04, 0.06, 0.38),
			true
		)
		## Hatch marks so fogged span still feels mapped, not empty.
		var hatch_y := pad + 10.0
		while hatch_y < wr.y - pad - 8.0:
			draw_line(
				Vector2(x0 + 4.0, hatch_y),
				Vector2(x0 + w - 4.0, hatch_y + 10.0),
				Color(0.2, 0.17, 0.14, 0.18),
				1.0
			)
			hatch_y += 18.0


func _draw_frame(wr: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, wr), Color(0.55, 0.45, 0.28, 0.9), false, 3.0)
	draw_rect(Rect2(Vector2(6, 6), wr - Vector2(12, 12)), Color(0.35, 0.28, 0.18, 0.5), false, 1.0)


func _draw_player_icon(p: Vector2) -> void:
	## Shadow spirit: dark body + pale eyes (matches in-game silhouette).
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
	## Soft halo so it reads on dark fog
	draw_arc(p + Vector2(0, -8), 16.0, 0.0, TAU, 24, Color(0.95, 0.85, 0.55, 0.35), 1.5)
