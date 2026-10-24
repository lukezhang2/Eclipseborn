extends Node2D
## Early hub: cobbled street, lamp posts, brick faces, shadow gap puzzle.


func _ready() -> void:
	GameState.current_zone_id = "lantern_village"
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, 2800, 720)

	LevelCommon.add_cobble_floor(self, 600, 520, 1200, 40)
	LevelCommon.add_cobble_floor(self, 1900, 520, 1400, 40)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_wall(self, 2700, 300, 40, 480)

	LevelCommon.add_brick_wall_face(self, 400, 260, 900, 380)
	LevelCommon.add_brick_wall_face(self, 1500, 260, 900, 380)
	LevelCommon.add_brick_wall_face(self, 2300, 260, 700, 380)

	LevelCommon.add_pipe(self, Vector2(40, 70), Vector2(2650, 70), 12.0)
	LevelCommon.add_pipe(self, Vector2(500, 70), Vector2(500, 180), 8.0)
	LevelCommon.add_valve(self, Vector2(500, 180))

	# Street dressing
	LevelCommon.add_lamp_post(self, Vector2(280, 500))
	LevelCommon.add_lamp_post(self, Vector2(720, 500))
	LevelCommon.add_lamp_post(self, Vector2(1600, 500))
	LevelCommon.add_lamp_post(self, Vector2(2200, 500))
	LevelCommon.add_window(self, 360, 200, 44, 60, false)
	LevelCommon.add_window(self, 620, 200, 44, 60, true)
	LevelCommon.add_window(self, 1100, 190, 50, 68, false)
	LevelCommon.add_window(self, 1800, 190, 50, 68, true)
	LevelCommon.add_bench(self, Vector2(450, 500))
	LevelCommon.add_crate_prop(self, Vector2(900, 492))
	LevelCommon.add_crate_prop(self, Vector2(940, 492), Vector2(24, 20))
	LevelCommon.add_steam_vent(self, Vector2(1050, 500))
	LevelCommon.add_steam_vent(self, Vector2(1950, 500))

	_build_gap_puzzle()

	LevelCommon.make_room_trigger(self, Vector2(300, 360), Vector2(500, 400), "lantern_village", "gate", "Lantern Village", "")
	LevelCommon.make_room_trigger(self, Vector2(900, 360), Vector2(500, 400), "lantern_village", "street_a")
	LevelCommon.make_room_trigger(self, Vector2(1500, 360), Vector2(500, 400), "lantern_village", "street_b", "Push the crate — its shadow is the bridge", "")
	LevelCommon.make_room_trigger(self, Vector2(2100, 360), Vector2(500, 400), "lantern_village", "square")

	var enemy_scene := preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.position = Vector2(2000, 470)
	add_child(enemy)

	var platform := LevelCommon.add_steel_floor(self, 2500, 400, 160, 24)
	var gear := Gear.new()
	gear.position = Vector2(2350, 300)
	add_child(gear)
	gear.bind_platform(platform)

	var street_lamp := LightSource.new()
	street_lamp.position = Vector2(700, 280)
	street_lamp.light_kind = GameState.LightKind.HEARTH
	street_lamp.radius = 300.0
	street_lamp.pushable = false
	street_lamp.name = "StreetLamp"
	add_child(street_lamp)

	var switch := LightSwitch.new()
	switch.position = Vector2(800, 480)
	add_child(switch)
	switch.target_light_paths = [NodePath("../StreetLamp")]

	var boss = enemy_scene.instantiate()
	boss.position = Vector2(2480, 470)
	boss.max_hp = 120
	boss.name = "Lamplighter"
	boss.move_speed = 35.0
	boss.attack_damage = 15
	add_child(boss)
	var unlocker := Node.new()
	unlocker.set_script(preload("res://scripts/world/LamplighterWatcher.gd"))
	add_child(unlocker)

	add_child(_make_shade_heart(Vector2(2200, 400)))

	var cp := Checkpoint.new()
	cp.position = Vector2(200, 500)
	cp.checkpoint_id = "village_gate"
	add_child(cp)

	LevelCommon.spawn_player(self, Vector2(100, 480))
	GameState.enter_room("lantern_village", "gate")
	SaveManager.save_game(0)


func _build_gap_puzzle() -> void:
	var lamp := LightSource.new()
	lamp.position = Vector2(1300, 220)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 420.0
	lamp.shadow_length = 520.0
	lamp.pushable = true
	add_child(lamp)

	var crate := PushableBox.new()
	crate.moveable = true
	crate.position = Vector2(1250, 476)
	crate.box_size = Vector2(56, 56)
	add_child(crate)

	var fixed := PushableBox.new()
	fixed.moveable = false
	fixed.position = Vector2(1000, 460)
	fixed.box_size = Vector2(64, 64)
	add_child(fixed)

	# Broken bridge beams over the gap (visual only).
	var beam := Polygon2D.new()
	beam.position = Vector2(1400, 480)
	beam.color = Color(0.3, 0.28, 0.25)
	beam.polygon = PackedVector2Array([
		Vector2(-40, -6), Vector2(80, -10), Vector2(90, 0), Vector2(-50, 4)
	])
	add_child(beam)


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
