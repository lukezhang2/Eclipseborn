extends Node2D
## Vertical Clockwork Tower climb — lobby through dial arena + Wickwright.


const MAP_W := 780.0
const FLOOR_H := 36.0
## Bottom lobby floor center Y (player climbs upward toward smaller Y).
const LOBBY_FLOOR := 2680.0
const LOBBY_TOP := LOBBY_FLOOR - FLOOR_H * 0.5
const ARENA_FLOOR := 420.0
const ARENA_TOP := ARENA_FLOOR - FLOOR_H * 0.5
const ROOF_TOP := 40.0

const WickwrightScript := preload("res://scripts/enemies/Wickwright.gd")
const RivetMiteScript := preload("res://scripts/enemies/RivetMite.gd")
const FuseBeetleScript := preload("res://scripts/enemies/FuseBeetle.gd")
const PendulumScript := preload("res://scripts/enemies/PendulumSentinel.gd")
const RewardChestScript := preload("res://scripts/world/RewardChest.gd")
const VillageDoorScript := preload("res://scripts/world/TowerVillageDoor.gd")

var _boss: Node = null
var _cutscene_running: bool = false


func _ready() -> void:
	GameState.current_zone_id = "clockwork_tower"
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 40.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	_build_shell()
	_build_lobby()
	_build_climb_a()
	_build_pendulum_cloister()
	_build_steam_flue()
	_build_switch_gallery()
	_build_arena()
	_build_exit_trigger()

	var spawn := _resolve_spawn()
	var player := LevelCommon.spawn_player(self, spawn)
	_configure_tower_camera(player)
	GameState.enter_room("clockwork_tower", _room_for_y(spawn.y))
	if not GameState.editor_playtesting:
		SaveManager.autosave()


func _room_for_y(y: float) -> String:
	if y > 2300.0:
		return "lobby"
	if y > 1800.0:
		return "climb"
	if y > 1300.0:
		return "pendulum"
	if y > 900.0:
		return "flue"
	if y > 550.0:
		return "gallery"
	return "arena"


func _resolve_spawn() -> Vector2:
	var spawn := Vector2(MAP_W * 0.5, LOBBY_TOP - 40.0)
	if GameState.pending_spawn != Vector2.ZERO:
		spawn = GameState.pending_spawn
		GameState.pending_spawn = Vector2.ZERO
	elif GameState.last_position != Vector2.ZERO and GameState.current_zone_id == "clockwork_tower":
		spawn = GameState.last_position
	elif GameState.checkpoint_position != Vector2.ZERO and GameState.current_zone_id == "clockwork_tower":
		spawn = GameState.checkpoint_position
	spawn.x = clampf(spawn.x, 80.0, MAP_W - 80.0)
	spawn.y = clampf(spawn.y, ROOF_TOP + 80.0, LOBBY_TOP - 20.0)
	GameState.last_position = spawn
	if GameState.checkpoint_position == Vector2.ZERO or GameState.editor_playtesting:
		GameState.checkpoint_position = spawn
	return spawn


func _configure_tower_camera(player: Node2D) -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_top = int(ROOF_TOP)
	cam.limit_bottom = int(LOBBY_FLOOR + FLOOR_H * 0.5 + 80.0)
	cam.limit_left = int(GameState.map_min_x - 20)
	cam.limit_right = int(GameState.map_max_x + 20)
	cam.position = Vector2(0, -30)
	cam.zoom = Vector2(1.25, 1.25)


func _build_shell() -> void:
	## Tall backdrop + side walls + underfloor.
	var bg := Polygon2D.new()
	bg.z_index = -20
	bg.color = Color(0.09, 0.08, 0.1)
	bg.polygon = PackedVector2Array([
		Vector2(0, ROOF_TOP - 40), Vector2(MAP_W, ROOF_TOP - 40),
		Vector2(MAP_W, LOBBY_FLOOR + 200), Vector2(0, LOBBY_FLOOR + 200)
	])
	add_child(bg)
	## Brick faces
	for y in [2400.0, 1900.0, 1400.0, 900.0, 500.0]:
		LevelCommon.add_brick_wall_face(self, MAP_W * 0.5, y - 80.0, MAP_W - 80.0, 220.0)
	LevelCommon.add_wall(self, 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	LevelCommon.add_wall(self, MAP_W - 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	LevelCommon.add_underfloor_fill(self, MAP_W, LOBBY_FLOOR + FLOOR_H * 0.5)
	## Pipe spine
	LevelCommon.add_pipe(self, Vector2(60, LOBBY_TOP - 40), Vector2(60, ARENA_TOP + 40), 10.0)
	LevelCommon.add_pipe(self, Vector2(MAP_W - 60, LOBBY_TOP - 40), Vector2(MAP_W - 60, ARENA_TOP + 40), 10.0)


func _floor_at(y_center: float, width: float = MAP_W, x: float = -1.0) -> void:
	var cx := MAP_W * 0.5 if x < 0.0 else x
	LevelCommon.add_steel_floor(self, cx, y_center, width, FLOOR_H)


func _ledge(x: float, top_y: float, w: float = 120.0) -> void:
	LevelCommon.add_steel_floor(self, x, top_y + FLOOR_H * 0.5, w, FLOOR_H)


func _build_lobby() -> void:
	_floor_at(LOBBY_FLOOR)
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, LOBBY_TOP - 120), Vector2(MAP_W - 80, 200), "clockwork_tower", "lobby", "Clockwork Lobby", "")
	## Entrance lamp + vent
	var lamp := _make_lamp("lobby_lamp", Vector2(MAP_W * 0.5, LOBBY_TOP - 160), 200.0, true)
	add_child(lamp)
	LevelCommon.add_steam_vent(self, Vector2(220, LOBBY_TOP))
	LevelCommon.add_bench(self, Vector2(140, LOBBY_TOP))
	## Grubs
	_spawn_grub(Vector2(360, LOBBY_TOP - 20))
	_spawn_grub(Vector2(520, LOBBY_TOP - 20))
	## First climb ledges
	_ledge(220, LOBBY_TOP - 140, 140)
	_ledge(520, LOBBY_TOP - 240, 140)
	_ledge(300, LOBBY_TOP - 360, 130)
	_spawn_mite(Vector2(520, LOBBY_TOP - 262))
	_spawn_mite(Vector2(300, LOBBY_TOP - 382))
	## Exit door back to village (left niche)
	_make_village_exit(Vector2(100, LOBBY_TOP - 20))


func _build_climb_a() -> void:
	## Mid shaft platforms ~2200–1900
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, 2100), Vector2(MAP_W - 100, 280), "clockwork_tower", "climb", "Gear Shaft", "")
	for i in 5:
		var y := LOBBY_TOP - 480.0 - float(i) * 130.0
		var x := 200.0 if i % 2 == 0 else MAP_W - 200.0
		_ledge(x, y, 150.0)
		if i % 2 == 0:
			_spawn_mite(Vector2(x, y - 18))
		else:
			_spawn_grub(Vector2(x, y - 18))
	_spawn_beetle(Vector2(MAP_W * 0.5, LOBBY_TOP - 700))
	var mid_lamp := _make_lamp("climb_lamp", Vector2(MAP_W * 0.5, LOBBY_TOP - 620), 160.0, true)
	add_child(mid_lamp)


func _build_pendulum_cloister() -> void:
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, 1600), Vector2(MAP_W - 100, 320), "clockwork_tower", "pendulum", "Pendulum Cloister", "")
	## Partial floors with gaps
	_floor_at(1720.0, 260.0, 180.0)
	_floor_at(1720.0, 260.0, MAP_W - 180.0)
	_ledge(MAP_W * 0.5, 1580.0, 160.0)
	_ledge(220, 1450.0, 140.0)
	_ledge(MAP_W - 220, 1450.0, 140.0)
	var cloister_lamp := _make_lamp("cloister_lamp", Vector2(MAP_W * 0.5, 1520), 170.0, true)
	add_child(cloister_lamp)
	var sw := LightSwitch.new()
	sw.position = Vector2(140, 1702)
	sw.name = "cloister_switch"
	sw.starts_on = true
	sw.target_ids = PackedStringArray(["cloister_lamp"])
	LevelData.tag(sw, "cloister_switch")
	add_child(sw)
	var pend: Node = PendulumScript.new()
	pend.position = Vector2(MAP_W * 0.5 - 40, 1380)
	pend.set("lamp_id", "cloister_lamp")
	pend.set("arm_length", 130.0)
	add_child(pend)
	var pend2: Node = PendulumScript.new()
	pend2.position = Vector2(MAP_W * 0.5 + 80, 1280)
	pend2.set("lamp_id", "cloister_lamp")
	pend2.set("arm_length", 110.0)
	pend2.set("swing_speed", 1.4)
	add_child(pend2)
	_spawn_beetle(Vector2(220, 1432))
	_spawn_jar(Vector2(MAP_W - 200, 1432))


func _build_steam_flue() -> void:
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, 1100), Vector2(MAP_W - 100, 300), "clockwork_tower", "flue", "Steam Flue", "")
	for i in 4:
		var y := 1280.0 - float(i) * 115.0
		var x := 240.0 if i % 2 == 0 else MAP_W - 240.0
		_ledge(x, y, 130.0)
		LevelCommon.add_steam_vent(self, Vector2(x, y))
		if i == 1 or i == 3:
			_spawn_beetle(Vector2(x, y - 18))
		else:
			_spawn_grub(Vector2(x, y - 18))
	_ledge(MAP_W * 0.5, 900.0, 180.0)
	var flue_lamp := _make_lamp("flue_lamp", Vector2(MAP_W * 0.5, 820), 150.0, false)
	add_child(flue_lamp)
	var fsw := LightSwitch.new()
	fsw.position = Vector2(MAP_W * 0.5 - 80, 882)
	fsw.starts_on = false
	fsw.target_ids = PackedStringArray(["flue_lamp"])
	add_child(fsw)


func _build_switch_gallery() -> void:
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, 700), Vector2(MAP_W - 100, 240), "clockwork_tower", "gallery", "Switch Gallery", "")
	_floor_at(780.0, MAP_W - 80.0)
	## Practice dial lamps (teach Match the Hour)
	var la := _make_lamp("practice_a", Vector2(220, 680), 100.0, true)
	var lb := _make_lamp("practice_b", Vector2(390, 680), 100.0, false)
	var lc := _make_lamp("practice_c", Vector2(560, 680), 100.0, true)
	add_child(la)
	add_child(lb)
	add_child(lc)
	for pair in [["practice_sw_a", "practice_a", 180.0, true], ["practice_sw_b", "practice_b", 350.0, false], ["practice_sw_c", "practice_c", 520.0, true]]:
		var s := LightSwitch.new()
		s.position = Vector2(float(pair[2]), 762)
		s.name = str(pair[0])
		s.starts_on = bool(pair[3])
		s.target_ids = PackedStringArray([str(pair[1])])
		add_child(s)
	var hint := Label.new()
	hint.text = "Match the Hour — flip levers so the lamps match the dial before the apex."
	hint.position = Vector2(120, 620)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.5))
	add_child(hint)
	## Elite: winding knight stand-in — tougher fuse beetle + mites
	_spawn_beetle(Vector2(300, 762))
	_spawn_beetle(Vector2(480, 762))
	_spawn_mite(Vector2(390, 640))
	## Climb to arena
	_ledge(MAP_W * 0.5, 600.0, 160.0)
	_ledge(260, 520.0, 140.0)
	_ledge(MAP_W - 260, 520.0, 140.0)


func _build_arena() -> void:
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, ARENA_TOP - 100), Vector2(MAP_W - 60, 260), "clockwork_tower", "arena", "Dial Arena", "The Wickwright waits.")
	_floor_at(ARENA_FLOOR, MAP_W - 40.0)
	## Clock mosaic hint
	var mosaic := Polygon2D.new()
	mosaic.z_index = -5
	mosaic.position = Vector2(MAP_W * 0.5, ARENA_TOP - 2)
	mosaic.color = Color(0.35, 0.28, 0.18, 0.55)
	var mpts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		mpts.append(Vector2(cos(a), sin(a)) * 70.0)
	mosaic.polygon = mpts
	add_child(mosaic)

	## Checkpoint at top
	var cp := Checkpoint.new()
	cp.position = Vector2(120, ARENA_TOP)
	cp.checkpoint_id = "tower_apex"
	cp.checkpoint_name = "Tower Apex"
	add_child(cp)

	## Boss lamps + switches (gallery height)
	var ids := ["tower_lamp_a", "tower_lamp_b", "tower_lamp_c"]
	var xs := [200.0, MAP_W * 0.5, MAP_W - 200.0]
	var starts := [true, false, true]
	for i in 3:
		var lamp := _make_lamp(ids[i], Vector2(xs[i], ARENA_TOP - 150), 140.0, starts[i])
		add_child(lamp)
		var sw := LightSwitch.new()
		sw.position = Vector2(xs[i], ARENA_TOP - 8)
		sw.name = ["tower_switch_a", "tower_switch_b", "tower_switch_c"][i]
		sw.starts_on = starts[i]
		sw.target_ids = PackedStringArray([ids[i]])
		LevelData.tag(sw, sw.name)
		add_child(sw)

	if GameState.wickwright_defeated():
		## Already beaten — leave chest if crystal not taken; no boss.
		if not GameState.is_collected("tower_crystal_piece"):
			var chest: Node = RewardChestScript.new()
			chest.position = Vector2(MAP_W * 0.5, ARENA_TOP - 8)
			add_child(chest)
		_spawn_broken_wall_decor(Vector2(MAP_W - 40, ARENA_TOP - 120))
	else:
		_boss = WickwrightScript.new()
		_boss.position = Vector2(MAP_W * 0.5, ARENA_TOP - 160)
		add_child(_boss)
		if _boss.has_signal("defeated"):
			_boss.connect("defeated", _on_boss_defeated)


func _build_exit_trigger() -> void:
	pass


func _make_village_exit(pos: Vector2) -> void:
	var exit: Node = VillageDoorScript.new()
	exit.position = pos
	add_child(exit)


func _make_lamp(id: String, pos: Vector2, radius: float, on: bool) -> LightSource:
	var lamp := LightSource.new()
	lamp.name = id
	lamp.position = pos
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = radius
	lamp.shadow_length = radius + 40.0
	lamp.pushable = false
	lamp.is_enabled = on
	LevelData.tag(lamp, id)
	return lamp


func _spawn_grub(pos: Vector2) -> void:
	var scene := preload("res://scenes/enemies/WanderEnemy.tscn")
	var e = scene.instantiate()
	e.position = pos
	add_child(e)


func _spawn_mite(pos: Vector2) -> void:
	var m: Node = RivetMiteScript.new()
	m.position = pos
	add_child(m)


func _spawn_beetle(pos: Vector2) -> void:
	var b: Node = FuseBeetleScript.new()
	b.position = pos
	add_child(b)


func _spawn_jar(pos: Vector2) -> void:
	var jar := BreakableProp.new()
	jar.position = pos
	jar.breakable_id = "tower_jar_%d_%d" % [int(pos.x), int(pos.y)]
	add_child(jar)


func _spawn_broken_wall_decor(pos: Vector2) -> void:
	var hole := Polygon2D.new()
	hole.position = pos
	hole.z_index = -4
	hole.color = Color(0.05, 0.05, 0.07)
	hole.polygon = PackedVector2Array([
		Vector2(-10, -80), Vector2(50, -100), Vector2(60, 40), Vector2(-20, 50)
	])
	add_child(hole)
	var rubble := Polygon2D.new()
	rubble.position = pos + Vector2(10, 30)
	rubble.color = Color(0.3, 0.25, 0.2)
	rubble.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(30, -10), Vector2(40, 20), Vector2(-10, 25)
	])
	add_child(rubble)


func _on_boss_defeated() -> void:
	if _cutscene_running:
		return
	_cutscene_running = true
	await _play_defeat_cutscene()


func _play_defeat_cutscene() -> void:
	GameState.intro_cutscene_playing = true
	var player := GameState.player as Player
	if player:
		player.set_control_locked(true)
	var cam := player.get_node_or_null("Camera2D") as Camera2D if player else null
	var boss := _boss
	if boss == null or not is_instance_valid(boss):
		GameState.intro_cutscene_playing = false
		if player:
			player.set_control_locked(false)
		return

	## Drop reward chest at boss feet before the throw.
	var chest: Node = RewardChestScript.new()
	chest.position = Vector2(boss.global_position.x, ARENA_TOP - 8)
	add_child(chest)

	## Lock camera on boss
	var saved_zoom := Vector2(1.25, 1.25)
	if cam and player:
		saved_zoom = cam.zoom
		cam.reparent(boss)
		cam.position = Vector2(0, -20)
		var tw := create_tween()
		tw.tween_property(cam, "zoom", Vector2(1.55, 1.55), 0.5)
		await tw.finished

	await get_tree().create_timer(0.4).timeout

	## Broken wall appears; boss flies through and falls.
	_spawn_broken_wall_decor(Vector2(MAP_W - 30, ARENA_TOP - 130))
	var tw2 := create_tween()
	tw2.tween_property(boss, "global_position", Vector2(MAP_W + 80, ARENA_TOP - 160), 0.55).set_ease(Tween.EASE_IN)
	await tw2.finished
	var tw3 := create_tween()
	tw3.tween_property(boss, "global_position", Vector2(MAP_W + 160, ARENA_TOP + 400), 0.85).set_ease(Tween.EASE_IN)
	tw3.parallel().tween_property(boss, "rotation", 2.8, 0.85)
	tw3.parallel().tween_property(boss, "modulate:a", 0.0, 0.85)
	await tw3.finished

	GameState.mark_collected("wickwright_defeated")
	SaveManager.autosave()

	## Restore camera to player
	if cam and player and is_instance_valid(player):
		cam.reparent(player)
		cam.position = Vector2(0, -30)
		var tw4 := create_tween()
		tw4.tween_property(cam, "zoom", saved_zoom, 0.4)
		await tw4.finished

	if is_instance_valid(boss):
		boss.queue_free()
	_boss = null

	if player:
		player.set_control_locked(false)
	GameState.intro_cutscene_playing = false
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("The Wickwright falls. A brass pot remains — strike it open.", 4.5)
