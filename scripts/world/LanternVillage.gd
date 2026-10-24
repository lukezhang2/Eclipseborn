extends Node2D
## Early hub. Floors are the shadow world; lamps cast burning light. Boxes block light.


const FLOOR_CENTER := 520.0
const FLOOR_H := 40.0
const FLOOR_TOP := FLOOR_CENTER - FLOOR_H * 0.5  # 500
const ROOF_TOP := 160.0
const MAP_W := 3200.0
## Canonical entry from the cottage hatch (Y always snapped to floor).
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

	LevelCommon.add_pipe(self, Vector2(40, 90), Vector2(MAP_W - 80, 90), 12.0)
	LevelCommon.add_lamp_post(self, Vector2(280, FLOOR_TOP))
	LevelCommon.add_lamp_post(self, Vector2(720, FLOOR_TOP))
	LevelCommon.add_lamp_post(self, Vector2(1600, FLOOR_TOP))
	LevelCommon.add_window(self, 360, 220, 44, 60, false)
	LevelCommon.add_bench(self, Vector2(450, FLOOR_TOP))
	LevelCommon.add_steam_vent(self, Vector2(1050, FLOOR_TOP))

	_build_houses_and_npcs()
	_build_light_puzzle()
	_build_bg_gears_and_platforms()
	_build_wander_enemies()
	_build_clockwork_tower()

	LevelCommon.make_room_trigger(self, Vector2(300, 360), Vector2(500, 400), "lantern_village", "gate", "Lantern Village", "")
	LevelCommon.make_room_trigger(self, Vector2(900, 360), Vector2(500, 400), "lantern_village", "street_a")
	LevelCommon.make_room_trigger(self, Vector2(1500, 360), Vector2(500, 400), "lantern_village", "street_b", "Push a crate to block the lamp", "")
	LevelCommon.make_room_trigger(self, Vector2(2200, 360), Vector2(500, 400), "lantern_village", "square")
	LevelCommon.make_room_trigger(self, Vector2(2900, 360), Vector2(500, 400), "lantern_village", "tower", "Ascend the Clockwork Tower", "")

	var street_lamp := LightSource.new()
	street_lamp.position = Vector2(700, 280)
	street_lamp.light_kind = GameState.LightKind.HEARTH
	street_lamp.radius = 280.0
	street_lamp.shadow_length = 320.0
	street_lamp.pushable = false
	street_lamp.name = "StreetLamp"
	add_child(street_lamp)

	var switch := LightSwitch.new()
	switch.position = Vector2(800, FLOOR_TOP - 20)
	add_child(switch)
	switch.target_light_paths = [NodePath("../StreetLamp")]

	add_child(_make_shade_heart(Vector2(2100, FLOOR_TOP - 100)))

	var cp := Checkpoint.new()
	cp.position = Vector2(200, FLOOR_TOP)
	cp.checkpoint_id = "village_gate"
	add_child(cp)

	LevelData.apply(self, "lantern_village")

	var spawn := _resolve_spawn()
	var player := LevelCommon.spawn_player(self, spawn)
	LevelCommon.configure_camera(player, ROOF_TOP, FLOOR_CENTER + FLOOR_H * 0.5 + 40.0, GameState.map_min_x, GameState.map_max_x)
	GameState.enter_room("lantern_village", "gate")
	SaveManager.autosave()

	# Fade in after hatch transition (black screen → village).
	var fx := preload("res://scripts/ui/ZoneTransition.gd").new()
	add_child(fx)
	fx.play_in()


func _resolve_spawn() -> Vector2:
	## Always plant feet on this village's floor — cottage Y must not carry over.
	var spawn := HATCH_SPAWN
	if GameState.last_position != Vector2.ZERO and GameState.current_zone_id == "lantern_village":
		spawn.x = GameState.last_position.x
	elif GameState.checkpoint_position != Vector2.ZERO:
		spawn.x = GameState.checkpoint_position.x
	spawn.x = clampf(spawn.x, GameState.map_min_x + 40.0, GameState.map_max_x - 40.0)
	spawn.y = FLOOR_TOP - 40.0
	GameState.last_position = spawn
	GameState.checkpoint_position = spawn
	return spawn


func _build_houses_and_npcs() -> void:
	var h1 := House.new()
	h1.position = Vector2(520, FLOOR_TOP)
	h1.house_name = "Lantern Keep"
	h1.width = 130.0
	h1.height = 100.0
	add_child(h1)

	var h2 := House.new()
	h2.position = Vector2(980, FLOOR_TOP)
	h2.house_name = "Gearwright"
	h2.width = 110.0
	h2.height = 88.0
	add_child(h2)

	var h3 := House.new()
	h3.position = Vector2(1780, FLOOR_TOP)
	h3.house_name = "Shade Inn"
	h3.width = 140.0
	h3.height = 110.0
	add_child(h3)

	var n1 := NPC.new()
	n1.position = Vector2(600, FLOOR_TOP)
	n1.npc_name = "Keeper"
	n1.lines = PackedStringArray([
		"Stay in the umbra, traveler.",
		"The lamps burn shade — duck under platforms.",
		"The Clockwork Tower wakes at the far end.",
	])
	add_child(n1)

	var n2 := NPC.new()
	n2.position = Vector2(1100, FLOOR_TOP)
	n2.npc_name = "Gearwright"
	n2.lines = PackedStringArray([
		"Those background gears spin the walkways.",
		"Push crates — wood drinks the light.",
		"Silver gears buy favors… someday.",
	])
	add_child(n2)

	var n3 := NPC.new()
	n3.position = Vector2(1900, FLOOR_TOP)
	n3.npc_name = "Innkeep"
	n3.lines = PackedStringArray([
		"Rest under the eaves if the hearth bites.",
		"Wanderers stalk the square — careful.",
		"Climb the tower when you're ready.",
	])
	add_child(n3)


func _build_light_puzzle() -> void:
	var lamp := LightSource.new()
	lamp.position = Vector2(1300, 240)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 380.0
	lamp.shadow_length = 460.0
	lamp.pushable = true
	add_child(lamp)

	var crate := PushableBox.new()
	crate.position = Vector2(1250, FLOOR_TOP - 28)
	crate.box_size = Vector2(56, 56)
	add_child(crate)


func _build_bg_gears_and_platforms() -> void:
	## Decorative BG gears (no collision) visually drive moving walkways.
	var bg1 := LevelCommon.add_bg_gear(self, Vector2(1450, 300), 55.0, 18.0)
	var plat1 := LevelCommon.add_steel_floor(self, 1550, FLOOR_TOP - 90, 140, 20)
	var d1 := PlatformDriver.new()
	d1.position = Vector2(1450, 300)
	d1.move_amplitude = 90.0
	d1.move_speed = 0.65
	add_child(d1)
	d1.bind(plat1, bg1)

	var bg2 := LevelCommon.add_bg_gear(self, Vector2(2200, 260), 70.0, -14.0)
	var plat2 := LevelCommon.add_steel_floor(self, 2300, FLOOR_TOP - 130, 120, 20)
	var d2 := PlatformDriver.new()
	d2.position = Vector2(2200, 260)
	d2.move_amplitude = 70.0
	d2.move_speed = 0.55
	d2.vertical = true
	add_child(d2)
	d2.bind(plat2, bg2)

	LevelCommon.add_bg_gear(self, Vector2(800, 240), 40.0, 10.0)
	LevelCommon.add_bg_gear(self, Vector2(2600, 220), 48.0, -8.0)


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


func _make_shade_heart(pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.position = pos
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	cs.shape = circle
	a.add_child(cs)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, 0), Vector2(0, 12), Vector2(-10, 0)
	])
	gem.color = Color(0.55, 0.35, 0.85)
	a.add_child(gem)
	a.body_entered.connect(func(body: Node) -> void:
		if body is Player or body.is_in_group("player"):
			GameState.add_shade_heart()
			a.queue_free()
	)
	return a
