extends Node2D
## Early hub. Floors are the shadow world; lamps cast burning light.


const FLOOR_CENTER := 520.0
const FLOOR_H := 40.0
const FLOOR_TOP := FLOOR_CENTER - FLOOR_H * 0.5  # 500
const ROOF_TOP := 160.0
const MAP_W := 3200.0
const HATCH_SPAWN := Vector2(160, 460)


func _ready() -> void:
	GameState.current_zone_id = "lantern_village"
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 80.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, MAP_W, 780, FLOOR_TOP, ROOF_TOP)
	LevelCommon.add_underfloor_fill(self, MAP_W, FLOOR_CENTER + FLOOR_H * 0.5)

	LevelCommon.add_cobble_floor(self, MAP_W * 0.5, FLOOR_CENTER, MAP_W, FLOOR_H)
	LevelCommon.add_border_walls(self, MAP_W, FLOOR_TOP, ROOF_TOP)

	LevelCommon.add_brick_wall_face(self, 400, 280, 900, 360)
	LevelCommon.add_brick_wall_face(self, 1500, 280, 900, 360)
	LevelCommon.add_brick_wall_face(self, 2500, 280, 800, 360)

	var wire_y := 90.0
	LevelCommon.add_pipe(self, Vector2(40, wire_y), Vector2(MAP_W - 80, wire_y), 12.0)
	LevelCommon.add_window(self, 360, 220, 44, 60, false)
	LevelCommon.add_bench(self, Vector2(660, FLOOR_TOP))
	LevelCommon.add_steam_vent(self, Vector2(1050, FLOOR_TOP))

	_build_houses()
	_build_all_lights()
	_build_light_puzzle()
	_build_bg_gears_and_platforms()
	_build_wander_enemies()
	_build_clockwork_tower()

	LevelCommon.make_room_trigger(self, Vector2(300, 360), Vector2(500, 400), "lantern_village", "gate", "Lantern Village", "")
	LevelCommon.make_room_trigger(self, Vector2(900, 360), Vector2(500, 400), "lantern_village", "street_a")
	LevelCommon.make_room_trigger(self, Vector2(1500, 360), Vector2(500, 400), "lantern_village", "street_b", "Push a crate to block the lamp", "")
	LevelCommon.make_room_trigger(self, Vector2(2200, 360), Vector2(500, 400), "lantern_village", "square")
	LevelCommon.make_room_trigger(self, Vector2(2900, 360), Vector2(500, 400), "lantern_village", "tower", "Ascend the Clockwork Tower", "")

	if not GameState.is_collected("shade_heart"):
		var crystal := ShadowCrystal.new()
		crystal.position = Vector2(2100, FLOOR_TOP - 100)
		crystal.pickup_id = "shade_heart"
		crystal.display_name = "Shadow Crystal Fragment"
		LevelData.tag(crystal, "shade_heart")
		add_child(crystal)

	if not LevelData.is_removed("lantern_village", "checkpoint_gate"):
		var cp := Checkpoint.new()
		cp.position = Vector2(200, FLOOR_TOP)
		cp.checkpoint_id = "village_gate"
		cp.checkpoint_name = "Village Gate"
		LevelData.tag(cp, "checkpoint_gate")
		add_child(cp)

	LevelData.apply(self, "lantern_village")
	LevelData.prune_removed(self, "lantern_village")

	var spawn := _resolve_spawn()
	var player := LevelCommon.spawn_player(self, spawn)
	LevelCommon.configure_camera(player, ROOF_TOP, FLOOR_CENTER + FLOOR_H * 0.5 + 40.0, GameState.map_min_x, GameState.map_max_x)
	GameState.enter_room("lantern_village", "gate")
	if not GameState.editor_playtesting:
		SaveManager.autosave()


func _resolve_spawn() -> Vector2:
	var spawn := Vector2(HATCH_SPAWN.x, FLOOR_TOP - 40.0)
	if GameState.pending_spawn != Vector2.ZERO:
		spawn.x = GameState.pending_spawn.x
		GameState.pending_spawn = Vector2.ZERO
	elif GameState.editor_playtesting:
		spawn.x = HATCH_SPAWN.x
	elif GameState.last_position != Vector2.ZERO:
		## Continue / logout position — death still uses checkpoint_position (hearth).
		var lx := GameState.last_position.x
		if lx >= 40.0 and lx <= MAP_W - 80.0:
			spawn.x = lx
	elif GameState.checkpoint_position != Vector2.ZERO:
		var cx := GameState.checkpoint_position.x
		if cx >= 40.0 and cx <= MAP_W - 80.0:
			spawn.x = cx
	spawn.x = clampf(spawn.x, GameState.map_min_x + 40.0, MAP_W - 80.0)
	spawn.y = FLOOR_TOP - 40.0
	GameState.last_position = spawn
	## Never overwrite a real rest hearth with the continue spawn point.
	if GameState.checkpoint_position == Vector2.ZERO or GameState.editor_playtesting:
		GameState.checkpoint_position = spawn
	return spawn


func _build_all_lights() -> void:
	## Rebuild every village lantern so washes + burn share the new occluder path.
	var wire_y := 90.0
	## Hanging candles along the wire (burn, short reach).
	for x in [280.0, 720.0, 1180.0, 1600.0, 2100.0, 2600.0]:
		LevelCommon.add_hanging_lantern(self, Vector2(x, wire_y), 70.0, 150.0)

	## Street hearth by Lantern Keep — houses must actually cover this wash.
	var street_lamp := _make_hearth_lamp("lamp_street", Vector2(748, 312), 250.0)
	street_lamp.name = "StreetLamp"
	add_child(street_lamp)

	## Square hearth near the inn / tower approach.
	var square_lamp := _make_hearth_lamp("lamp_square", Vector2(2000, 300), 260.0)
	square_lamp.name = "SquareLamp"
	add_child(square_lamp)

	var switch := LightSwitch.new()
	switch.position = Vector2(372, 488)
	switch.name = "StreetLampSwitch"
	switch.starts_on = true
	switch.target_ids = PackedStringArray(["lamp_street", "lamp_square"])
	LevelData.tag(switch, "switch_street")
	add_child(switch)
	## door_street_a removed in editor — kept out of play via removed_ids.


func _build_houses() -> void:
	## Shopkeepers live inside — street only shows doors.
	_spawn_house("house_keep", "Lantern Keep", Vector2(520, FLOOR_TOP), 130.0, 100.0)
	_spawn_house("house_gear", "Gearwright", Vector2(980, FLOOR_TOP), 110.0, 88.0)
	_spawn_house("house_inn", "Shade Inn", Vector2(1780, FLOOR_TOP), 140.0, 110.0)


func _spawn_house(id: String, title: String, pos: Vector2, w: float, h: float) -> void:
	if LevelData.is_removed("lantern_village", id):
		return
	var house := House.new()
	house.position = pos
	house.house_name = title
	house.house_id = id
	house.width = w
	house.height = h
	house.blocks_light = true
	var saved := LevelData.merged_piece("lantern_village", id)
	if saved.has("blocks_light"):
		house.blocks_light = bool(saved.get("blocks_light"))
	if saved.has("layer"):
		house.z_index = int(saved.get("layer"))
	if saved.has("x"):
		house.position.x = float(saved.get("x"))
	if saved.has("y"):
		house.position.y = float(saved.get("y"))
	LevelData.tag(house, id)
	add_child(house)


func _make_hearth_lamp(catalog_id: String, fallback_pos: Vector2, fallback_r: float) -> LightSource:
	var lamp := LightSource.new()
	lamp.position = fallback_pos
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = fallback_r
	lamp.shadow_length = fallback_r + 50.0
	lamp.pushable = false
	var saved := LevelData.merged_piece("lantern_village", catalog_id)
	if not saved.is_empty():
		if saved.has("x") and saved.has("y"):
			lamp.position = Vector2(float(saved.get("x")), float(saved.get("y")))
		if saved.has("radius"):
			lamp.set_radius(float(saved.get("radius")))
		if saved.has("intensity"):
			lamp.set_intensity(float(saved.get("intensity")))
	LevelData.tag(lamp, catalog_id)
	return lamp


func _build_light_puzzle() -> void:
	var lamp := _make_hearth_lamp("lamp_puzzle", Vector2(1292, 238), 250.0)
	add_child(lamp)

	var crate := PushableBox.new()
	crate.box_size = Vector2(56, 56)  # editor save size for this puzzle crate
	crate.position = Vector2(1250, FLOOR_TOP - crate.box_size.y * 0.5)
	LevelData.tag(crate, "crate_puzzle")
	add_child(crate)


func _build_bg_gears_and_platforms() -> void:
	_spawn_catalog_platform("platform_gear_a", Vector2(1544, 410), Vector2(140, 20), {
		"move_amplitude": 90.0,
		"move_speed": 0.65,
		"vertical": false,
		"path_y_amplitude": 0.0,
		"rotate_while_moving": true,
		"rotate_speed": 1.0,
		"rotate_platform": false,
		"with_gear": true,
		"gear_dx": -94.0,
		"gear_dy": -110.0,
		"gear_radius": 55.0,
	})
	_spawn_catalog_platform("platform_gear_b", Vector2(2300, FLOOR_TOP - 130), Vector2(120, 20), {
		"move_amplitude": 70.0,
		"move_speed": 0.55,
		"vertical": true,
		"path_y_amplitude": 0.0,
		"rotate_while_moving": true,
		"rotate_speed": 1.2,
		"rotate_platform": false,
		"with_gear": true,
		"gear_dx": -100.0,
		"gear_dy": -110.0,
		"gear_radius": 70.0,
	})
	LevelCommon.add_bg_gear(self, Vector2(800, 240), 40.0, 10.0)
	LevelCommon.add_bg_gear(self, Vector2(2600, 220), 48.0, -8.0)
	_spawn_catalog_bg_gear("bg_gear_a", Vector2(1450, 300), 55.0, 6.0)
	_spawn_catalog_bg_gear("bg_gear_b", Vector2(2200, 260), 70.0, -5.0)


func _spawn_catalog_bg_gear(catalog_id: String, fallback_pos: Vector2, fallback_r: float, spin: float) -> void:
	if LevelData.is_removed("lantern_village", catalog_id):
		return
	var saved := LevelData.merged_piece("lantern_village", catalog_id)
	var pos := fallback_pos
	var r := fallback_r
	if not saved.is_empty():
		pos = Vector2(float(saved.get("x", pos.x)), float(saved.get("y", pos.y)))
		r = maxf(float(saved.get("w", r * 2.0)), float(saved.get("h", r * 2.0))) * 0.5
	var gear := LevelCommon.add_bg_gear(self, pos, r, spin)
	LevelData.tag(gear, catalog_id)


func _spawn_catalog_platform(catalog_id: String, fallback_pos: Vector2, fallback_size: Vector2, defaults: Dictionary) -> void:
	if LevelData.is_removed("lantern_village", catalog_id):
		return
	var saved := LevelData.merged_piece("lantern_village", catalog_id)
	var pos := fallback_pos
	var size := fallback_size
	var cfg := defaults.duplicate(true)
	if not saved.is_empty():
		pos = Vector2(float(saved.get("x", pos.x)), float(saved.get("y", pos.y)))
		size = Vector2(float(saved.get("w", size.x)), float(saved.get("h", size.y)))
		for key in [
			"move_amplitude", "move_speed", "vertical", "path_y_amplitude",
			"rotate_while_moving", "rotate_speed", "rotate_platform", "with_gear",
			"gear_dx", "gear_dy", "gear_radius", "rotation"
		]:
			if saved.has(key):
				cfg[key] = saved.get(key)
	var body := LevelCommon.add_moving_platform(self, pos, size, cfg)
	LevelData.tag(body, catalog_id)


func _build_wander_enemies() -> void:
	var scene := preload("res://scenes/enemies/WanderEnemy.tscn")
	for pos in [Vector2(1500, FLOOR_TOP - 20), Vector2(2050, FLOOR_TOP - 20)]:
		var e = scene.instantiate()
		e.position = pos
		add_child(e)


func _build_clockwork_tower() -> void:
	var tower := ClockworkTower.new()
	tower.position = Vector2(MAP_W - 200, FLOOR_TOP)
	add_child(tower)


