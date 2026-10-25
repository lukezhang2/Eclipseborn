extends Node2D
class_name LevelCommon
## Helpers for steel-and-steam rooms: floors, brick walls, windows, props, UI.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const UI_SCENE := preload("res://scenes/ui/GameUI.tscn")

## WorldArt platform style for add_steel_floor. A room can set this before building to use
## a different platform look (e.g. a later zone).
static var platform_style: int = 2


static func add_steel_floor(parent: Node2D, x: float, y: float, width: float, height: float = 32.0, dress: bool = true) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	## Below lantern washes (−2/−1) so AoE reads on the ground; above deep BG.
	body.z_index = -4
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	body.add_child(cs)
	if dress:
		var art := WorldArt.new()
		art.kind = WorldArt.Kind.PLATFORM
		art.style = platform_style
		art.size = Vector2(width, height)
		body.add_child(art)
	else:
		# Plain metal texture; add_cobble_floor tints it and lays stones on top.
		var spr := Sprite2D.new()
		spr.texture = _make_metal_texture(mini(int(width), 512), maxi(int(height), 16))
		spr.centered = true
		spr.scale = Vector2(width / float(spr.texture.get_width()), height / float(spr.texture.get_height()))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.add_child(spr)
	# Solid floors/platforms occlude light (backgrounds do not).
	var hx := width * 0.5
	var hy := height * 0.5
	var occ := ShadowOccluder.new()
	occ.local_polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	body.add_child(occ)
	body.set_meta("editor_kind", "floor")
	body.set_meta("editor_size", Vector2(width, height))
	## Footstep bank — steel is the default for all floors until we author more.
	body.set_meta("floor_sfx", "steel")
	parent.add_child(body)
	return body


static func _make_metal_texture(w: int, h: int) -> ImageTexture:
	w = clampi(w, 16, 512)
	h = clampi(h, 8, 128)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var plate := int(x / 48)
			var shade := 0.26 + fmod(float(plate) * 0.03, 0.06)
			var c := Color(shade, shade + 0.01, shade + 0.03, 1.0)
			if y < 2 or y >= h - 2:
				c = c.lightened(0.08)
			if x % 48 < 2:
				c = c.darkened(0.25)
			if (x + 16) % 32 < 3 and (y == 4 or y == h - 5):
				c = Color(0.55, 0.42, 0.25)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func add_cobble_floor(parent: Node2D, x: float, y: float, width: float, height: float = 36.0) -> StaticBody2D:
	var body := add_steel_floor(parent, x, y, width, height, false)
	for c in body.get_children():
		if c is Sprite2D:
			(c as Sprite2D).modulate = Color(0.85, 0.78, 0.7)
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
	body.z_index = -4
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
	var occ := ShadowOccluder.new()
	occ.local_polygon = poly.polygon
	body.add_child(occ)
	parent.add_child(body)
	return body


static func configure_camera(player: Node2D, roof_y: float, floor_bottom: float, map_min_x: float, map_max_x: float) -> void:
	## Lock vertical framing so the roof sits at the top of the player's vision.
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_top = int(roof_y)
	cam.limit_bottom = int(floor_bottom)
	cam.limit_left = int(map_min_x - 20)
	cam.limit_right = int(map_max_x + 20)
	cam.position = Vector2(0, -20)
	cam.zoom = Vector2(1.35, 1.35)


static func add_border_walls(parent: Node2D, map_w: float, floor_top: float, roof_top: float) -> void:
	## Obvious designed end-caps so the player cannot walk off-screen.
	var mid_y := (floor_top + roof_top) * 0.5
	var h := floor_top - roof_top + 80.0
	_make_border_pillar(parent, 24, mid_y, 48, h, true)
	_make_border_pillar(parent, map_w - 24, mid_y, 48, h, false)


static func _make_border_pillar(parent: Node2D, x: float, y: float, w: float, h: float, left: bool) -> void:
	var body := add_wall(parent, x, y, w, h)
	# Decorative riveted face
	var face := Polygon2D.new()
	face.position = Vector2(x, y)
	face.z_index = 2
	var hx := w * 0.45
	var hy := h * 0.48
	face.color = Color(0.28, 0.24, 0.2)
	face.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	parent.add_child(face)
	var brace := Polygon2D.new()
	brace.position = Vector2(x + (14 if left else -14), y)
	brace.color = Color(0.45, 0.35, 0.22)
	brace.polygon = PackedVector2Array([
		Vector2(-6, -hy * 0.6), Vector2(6, -hy * 0.6), Vector2(6, hy * 0.6), Vector2(-6, hy * 0.6)
	])
	parent.add_child(brace)
	body.name = "BorderLeft" if left else "BorderRight"


static func add_underfloor_fill(parent: Node2D, width: float, floor_bottom: float) -> void:
	## Kill the empty black void under the walkable floor.
	var fill := Polygon2D.new()
	fill.z_index = -18
	fill.color = Color(0.1, 0.09, 0.1)
	fill.polygon = PackedVector2Array([
		Vector2(0, floor_bottom - 2), Vector2(width, floor_bottom - 2),
		Vector2(width, floor_bottom + 260), Vector2(0, floor_bottom + 260)
	])
	parent.add_child(fill)
	var strata := Polygon2D.new()
	strata.z_index = -17
	strata.color = Color(0.14, 0.12, 0.11, 0.7)
	strata.polygon = PackedVector2Array([
		Vector2(0, floor_bottom + 40), Vector2(width, floor_bottom + 60),
		Vector2(width, floor_bottom + 120), Vector2(0, floor_bottom + 100)
	])
	parent.add_child(strata)


static func add_bg_gear(parent: Node2D, pos: Vector2, radius: float = 50.0, speed: float = 12.0) -> Node2D:
	## Decorative background gear — casts light shadows, no player collision.
	var g := Node2D.new()
	g.position = pos
	g.z_index = -12
	g.modulate = Color(1, 1, 1, 0.35)
	g.set_meta("bg_gear_speed", speed)
	# Soot-brown gear with a dark hub (brick & copper background set).
	var disc := Polygon2D.new()
	disc.color = Color(0.23, 0.18, 0.13)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * radius * (0.85 if i % 2 == 0 else 1.0))
	disc.polygon = pts
	g.add_child(disc)
	var hub := Polygon2D.new()
	hub.color = Color(0.11, 0.08, 0.06)
	var hub_pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		hub_pts.append(Vector2(cos(a), sin(a)) * radius * 0.3)
	hub.polygon = hub_pts
	g.add_child(hub)
	## Circular occluder so spin doesn't churn shadow dirties; still clips umbra.
	var occ_pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		occ_pts.append(Vector2(cos(a), sin(a)) * radius * 0.92)
	LightOnlyBlocker.attach(g, occ_pts, true)
	parent.add_child(g)
	g.set_process(true)
	g.process_mode = Node.PROCESS_MODE_INHERIT
	# Spin via a tiny helper
	var spinner := Node.new()
	spinner.set_script(preload("res://scripts/world/BgGearSpin.gd"))
	g.add_child(spinner)
	return g


static func add_brick_wall_face(parent: Node2D, x: float, y: float, width: float, height: float) -> void:
	## Distant mural — darker, flatter, no collision. Reads as BG not solid geometry.
	var face := Node2D.new()
	face.position = Vector2(x, y)
	face.z_index = -14
	face.modulate = Color(0.55, 0.5, 0.48, 0.75)
	var bg := Polygon2D.new()
	var hx := width * 0.5
	var hy := height * 0.5
	bg.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	bg.color = Color(0.16, 0.11, 0.1)
	face.add_child(bg)
	var row := 0
	var yy := -hy + 10.0
	while yy < hy - 20:
		var offset := 14.0 if row % 2 == 1 else 0.0
		var xx := -hx + offset
		while xx < hx:
			var brick := Polygon2D.new()
			var bw := 30.0
			var bh := 11.0
			brick.polygon = PackedVector2Array([
				Vector2(xx, yy), Vector2(xx + bw - 3, yy),
				Vector2(xx + bw - 3, yy + bh - 2), Vector2(xx, yy + bh - 2)
			])
			brick.color = Color(0.22 + fmod(xx * 0.008, 0.04), 0.14, 0.12, 0.8)
			face.add_child(brick)
			xx += bw
		yy += 13.0
		row += 1
	# Soft vignette so it sinks into the room
	var fade := Polygon2D.new()
	fade.color = Color(0.05, 0.04, 0.06, 0.35)
	fade.polygon = PackedVector2Array([
		Vector2(-hx, hy - 40), Vector2(hx, hy - 40), Vector2(hx, hy), Vector2(-hx, hy)
	])
	face.add_child(fade)
	## Visual-only: washes stop on the mural; player burns ignore it.
	var occ := ShadowOccluder.new()
	occ.local_polygon = bg.polygon
	occ.blocks_gameplay = false
	occ.ignore_rotation = true
	face.add_child(occ)
	parent.add_child(face)


static func add_window(parent: Node2D, x: float, y: float, w: float = 48.0, h: float = 64.0, moonlit: bool = false) -> void:
	## Dark arched iron window. `moonlit` is kept for old callers; all windows are unlit now.
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.WINDOW
	art.style = 10
	art.size = Vector2(w, h)
	art.position = Vector2(x, y)
	art.z_index = -8
	parent.add_child(art)
	var hx := w * 0.5
	var hy := h * 0.5
	LightOnlyBlocker.attach(art, PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	]), true)

static func add_pipe(parent: Node2D, from: Vector2, to: Vector2, thick: float = 12.0) -> void:
	## Copper pipe with a highlight and an iron flange at the middle.
	var holder := Node2D.new()
	holder.position = (from + to) * 0.5
	parent.add_child(holder)
	var local_from := from - holder.position
	var local_to := to - holder.position
	var line := Line2D.new()
	line.width = thick
	line.default_color = Color(0.54, 0.35, 0.21)
	line.add_point(local_from)
	line.add_point(local_to)
	holder.add_child(line)
	var shine := Line2D.new()
	shine.width = thick * 0.25
	shine.default_color = Color(0.69, 0.48, 0.3, 0.8)
	shine.add_point(local_from + Vector2(0, -thick * 0.25))
	shine.add_point(local_to + Vector2(0, -thick * 0.25))
	holder.add_child(shine)
	var flange := Polygon2D.new()
	flange.color = Color(0.22, 0.2, 0.19)
	flange.polygon = PackedVector2Array([
		Vector2(-5, -thick * 0.75), Vector2(5, -thick * 0.75), Vector2(5, thick * 0.75), Vector2(-5, thick * 0.75)
	])
	holder.add_child(flange)
	## Thin AABB along the run so the pipe casts a realistic shadow band.
	var min_x := mini(local_from.x, local_to.x) - thick * 0.5
	var max_x := maxi(local_from.x, local_to.x) + thick * 0.5
	var min_y := mini(local_from.y, local_to.y) - thick * 0.5
	var max_y := maxi(local_from.y, local_to.y) + thick * 0.5
	LightOnlyBlocker.attach(holder, PackedVector2Array([
		Vector2(min_x, min_y), Vector2(max_x, min_y), Vector2(max_x, max_y), Vector2(min_x, max_y)
	]), true)

static func add_valve(parent: Node2D, pos: Vector2) -> void:
	## Red spoked wheel mounted flat on the wall.
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.VALVE
	art.style = 5
	art.position = pos
	parent.add_child(art)
	LightOnlyBlocker.attach(art, PackedVector2Array([
		Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)
	]), true)

static func add_crate_prop(parent: Node2D, pos: Vector2, size: Vector2 = Vector2(36, 28)) -> void:
	## Non-interactive scenery crate: dark-oak planks without the X brace pushable crates have.
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.CRATE
	art.style = 9
	art.size = size
	art.position = pos
	parent.add_child(art)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	LightOnlyBlocker.attach(art, PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	]), true)

static func add_bench(parent: Node2D, pos: Vector2) -> void:
	## Riveted steel bench in mid-dark grey.
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.BENCH
	art.style = 5
	art.position = pos
	parent.add_child(art)
	LightOnlyBlocker.attach(art, PackedVector2Array([
		Vector2(-30, -28), Vector2(30, -28), Vector2(30, 2), Vector2(-30, 2)
	]), true)

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


static func add_hanging_lantern(parent: Node2D, wire_pos: Vector2, drop: float = 70.0, radius: float = 150.0) -> void:
	## Lantern suspended from the overhead pipe/wire at wire_pos.
	# Link chain from the top ring of the caged lantern up to the wire.
	var chain := WorldArt.new()
	chain.kind = WorldArt.Kind.CHAIN
	chain.size = Vector2(0, drop - 20)
	chain.position = wire_pos + Vector2(0, drop - 20)
	chain.z_index = -1
	parent.add_child(chain)
	var hook := Polygon2D.new()
	hook.position = wire_pos
	hook.color = Color(0.4, 0.36, 0.3)
	hook.polygon = PackedVector2Array([
		Vector2(-4, -3), Vector2(4, -3), Vector2(4, 3), Vector2(-4, 3)
	])
	parent.add_child(hook)
	var lamp := LightSource.new()
	lamp.position = wire_pos + Vector2(0, drop + 4)
	lamp.light_kind = GameState.LightKind.CANDLE
	lamp.radius = radius
	lamp.shadow_length = radius + 40.0
	lamp.pushable = false
	lamp.set_meta("has_chain", true)
	parent.add_child(lamp)


static func add_steam_vent(parent: Node2D, pos: Vector2) -> SteamVent:
	var vent := SteamVent.new()
	vent.position = pos
	parent.add_child(vent)
	return vent


static func add_moving_platform(parent: Node2D, pos: Vector2, size: Vector2, cfg: Dictionary = {}) -> Node2D:
	## Steel floor + PlatformDriver (+ optional bg gear). cfg keys match PlatformDriver.configure.
	var body := add_steel_floor(parent, pos.x, pos.y, size.x, maxf(size.y, 16.0))
	if cfg.has("rotation"):
		body.rotation_degrees = float(cfg.get("rotation"))
	var gear_pos := pos + Vector2(float(cfg.get("gear_dx", -90.0)), float(cfg.get("gear_dy", -80.0)))
	var bg: Node2D = null
	if bool(cfg.get("with_gear", true)):
		bg = add_bg_gear(parent, gear_pos, float(cfg.get("gear_radius", 55.0)), 0.0)
	var driver := PlatformDriver.new()
	driver.position = gear_pos if bg else pos
	driver.configure(cfg)
	parent.add_child(driver)
	driver.bind(body, bg)
	return body


static func add_backdrop(parent: Node2D, width: float, height: float, floor_top: float = 500.0, roof_top: float = 180.0) -> void:
	## Playfield fill (below sky fire). Far silhouettes read as background, not solids.
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(0, roof_top), Vector2(width, roof_top), Vector2(width, height), Vector2(0, height)
	])
	bg.color = Color(0.06, 0.05, 0.07)
	bg.z_index = -18
	parent.add_child(bg)
	# Distant building silhouettes (desaturated, soft) — clearly non-interactive BG.
	var x := 40.0
	while x < width:
		var sil := Polygon2D.new()
		sil.z_index = -17
		var bw := randf_range(70, 140)
		var bh := randf_range(80, 200)
		sil.polygon = PackedVector2Array([
			Vector2(x, floor_top - 8), Vector2(x + bw, floor_top - 8),
			Vector2(x + bw, floor_top - 8 - bh), Vector2(x, floor_top - 8 - bh)
		])
		sil.color = Color(0.09, 0.08, 0.1, 0.55)
		parent.add_child(sil)
		# Fake distant windows
		for wi in 3:
			var win := Polygon2D.new()
			win.z_index = -16
			var wx := x + 12 + wi * 22
			var wy := floor_top - 40 - wi * 28
			win.polygon = PackedVector2Array([
				Vector2(wx, wy), Vector2(wx + 8, wy), Vector2(wx + 8, wy - 10), Vector2(wx, wy - 10)
			])
			win.color = Color(0.35, 0.28, 0.15, 0.15)
			parent.add_child(win)
		x += bw + randf_range(30, 80)
	var sky := BlackFireSky.new()
	sky.setup(width, floor_top, roof_top)
	parent.add_child(sky)


static func spawn_player(parent: Node2D, pos: Vector2) -> Player:
	var p: Player = PLAYER_SCENE.instantiate()
	p.global_position = pos
	parent.add_child(p)
	GameState.last_position = pos
	# Heal-reset checkpoint only on first spawn of a new run.
	if GameState.checkpoint_position == Vector2.ZERO:
		GameState.set_checkpoint(pos)
	return p


static func spawn_ui(parent: Node) -> void:
	if parent.get_node_or_null("GameUI") != null:
		return
	parent.add_child(UI_SCENE.instantiate())
	if GameState.editor_playtesting and parent.get_node_or_null("EditorPlaytestHud") == null:
		var hud := CanvasLayer.new()
		hud.name = "EditorPlaytestHud"
		hud.set_script(preload("res://scripts/ui/EditorPlaytestHud.gd"))
		parent.add_child(hud)


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
