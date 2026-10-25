extends Node2D
## Vertical Clockwork Tower — climb connected by jump-reachable ledges + side rooms.


## Player JUMP_VELOCITY=-360, GRAVITY=980 → theoretical peak ≈66px. Design under that.
const JUMP_REACH_Y := 52.0
const JUMP_SAFE_GAP_X := 90.0
const LEDGE_W := 140.0
const FLOOR_H := 36.0

const MAP_W := 1100.0 ## Wide enough for horizontal side rooms.
const SHAFT_L := 80.0
const SHAFT_R := 780.0
const LOBBY_FLOOR := 2680.0
const LOBBY_TOP := LOBBY_FLOOR - FLOOR_H * 0.5
const ANTECHAMBER_FLOOR := 620.0
const ANTECHAMBER_TOP := ANTECHAMBER_FLOOR - FLOOR_H * 0.5
const ARENA_FLOOR := 360.0
const ARENA_TOP := ARENA_FLOOR - FLOOR_H * 0.5
const ROOF_TOP := 20.0
const ENTRY_SPAWN := Vector2(140.0, LOBBY_TOP - 40.0) ## Bottom-left door spawn.

const WickwrightScript := preload("res://scripts/enemies/Wickwright.gd")
const RivetMiteScript := preload("res://scripts/enemies/RivetMite.gd")
const FuseBeetleScript := preload("res://scripts/enemies/FuseBeetle.gd")
const PendulumScript := preload("res://scripts/enemies/PendulumSentinel.gd")
const RewardChestScript := preload("res://scripts/world/RewardChest.gd")
const VillageDoorScript := preload("res://scripts/world/TowerVillageDoor.gd")

var _boss: Node = null
var _cutscene_running: bool = false
var _arena_gate: StaticBody2D = null
var _boss_awake: bool = false


func _ready() -> void:
	GameState.current_zone_id = "clockwork_tower"
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 40.0
	## Fixed lamps hang chains to this overhead rail.
	set_meta("ceiling_y", ROOF_TOP + 30.0)
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	_build_shell()
	_build_lobby()
	_build_main_shaft()
	_build_side_workshop()
	_build_pendulum_cloister()
	_build_steam_flue()
	_build_side_archive()
	_build_switch_gallery()
	_build_antechamber()
	_build_arena()
	## Editor overlays (non-builtin pieces) + prune catalog removals.
	LevelData.apply(self, "clockwork_tower")

	var spawn := _resolve_spawn()
	var player := LevelCommon.spawn_player(self, spawn)
	_configure_tower_camera(player)
	GameState.enter_room("clockwork_tower", _room_for_y(spawn.y))
	if not GameState.editor_playtesting:
		SaveManager.autosave()


func _room_for_y(y: float) -> String:
	if y > 2400.0:
		return "lobby"
	if y > 1900.0:
		return "climb"
	if y > 1400.0:
		return "pendulum"
	if y > 1000.0:
		return "flue"
	if y > 720.0:
		return "gallery"
	if y > 480.0:
		return "antechamber"
	return "arena"


func _resolve_spawn() -> Vector2:
	var spawn := ENTRY_SPAWN
	if GameState.pending_spawn != Vector2.ZERO:
		spawn = GameState.pending_spawn
		GameState.pending_spawn = Vector2.ZERO
	elif GameState.checkpoint_position != Vector2.ZERO \
			and GameState.current_zone_id == "clockwork_tower" \
			and GameState.checkpoint_path != "":
		## Death / continue at last tower hearth — never a mid-air last_position.
		spawn = GameState.checkpoint_position
	spawn.x = clampf(spawn.x, 80.0, MAP_W - 80.0)
	spawn.y = clampf(spawn.y, ROOF_TOP + 80.0, LOBBY_TOP - 20.0)
	GameState.last_position = spawn
	## Do not auto-claim a random spawn as the death hearth.
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
	cam.zoom = Vector2(1.2, 1.2)


func _build_shell() -> void:
	var bg := Polygon2D.new()
	bg.z_index = -20
	bg.color = Color(0.09, 0.08, 0.1)
	bg.polygon = PackedVector2Array([
		Vector2(0, ROOF_TOP - 40), Vector2(MAP_W, ROOF_TOP - 40),
		Vector2(MAP_W, LOBBY_FLOOR + 200), Vector2(0, LOBBY_FLOOR + 200)
	])
	add_child(bg)
	for y in [2400.0, 1900.0, 1400.0, 1000.0, 650.0, 300.0]:
		LevelCommon.add_brick_wall_face(self, MAP_W * 0.45, y - 40.0, 700.0, 200.0)
	LevelCommon.add_wall(self, 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	LevelCommon.add_wall(self, MAP_W - 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	LevelCommon.add_underfloor_fill(self, MAP_W, LOBBY_FLOOR + FLOOR_H * 0.5)
	## Overhead rail so hanging lanterns attach to something.
	LevelCommon.add_pipe(self, Vector2(60, ROOF_TOP + 30), Vector2(MAP_W - 60, ROOF_TOP + 30), 12.0)
	LevelCommon.add_pipe(self, Vector2(50, LOBBY_TOP - 40), Vector2(50, ARENA_TOP + 20), 10.0)
	LevelCommon.add_pipe(self, Vector2(SHAFT_R + 20, LOBBY_TOP - 40), Vector2(SHAFT_R + 20, ARENA_TOP + 20), 10.0)


func _floor_at(y_center: float, width: float = MAP_W, x: float = -1.0) -> void:
	var cx := MAP_W * 0.5 if x < 0.0 else x
	LevelCommon.add_steel_floor(self, cx, y_center, width, FLOOR_H)


func _ledge(x: float, top_y: float, w: float = LEDGE_W) -> void:
	LevelCommon.add_steel_floor(self, x, top_y + FLOOR_H * 0.5, w, FLOOR_H)


## Build a zig-zag of jump-reachable ledges from bottom_top_y upward.
func _climb_run(bottom_top_y: float, steps: int, left_x: float, right_x: float) -> float:
	var y := bottom_top_y
	for i in steps:
		y -= JUMP_REACH_Y
		var x := left_x if i % 2 == 0 else right_x
		_ledge(x, y, LEDGE_W)
		if i % 3 == 1:
			_spawn_mite(Vector2(x, y - 16))
		elif i % 3 == 2:
			_spawn_grub(Vector2(x, y - 16))
	return y


func _build_lobby() -> void:
	_floor_at(LOBBY_FLOOR, SHAFT_R - SHAFT_L + 80.0, (SHAFT_L + SHAFT_R) * 0.5)
	LevelCommon.make_room_trigger(self, Vector2((SHAFT_L + SHAFT_R) * 0.5, LOBBY_TOP - 100), Vector2(SHAFT_R - SHAFT_L, 180), "clockwork_tower", "lobby", "Clockwork Lobby", "")
	## Bottom rest hearth — death returns here until antechamber is rested.
	if not LevelData.is_removed("clockwork_tower", "checkpoint_lobby"):
		var cp := Checkpoint.new()
		var cp_pos := _piece_pos("checkpoint_lobby", Vector2(260, LOBBY_TOP))
		cp.position = cp_pos
		cp.checkpoint_id = "tower_lobby"
		cp.checkpoint_name = "Tower Lobby"
		LevelData.tag(cp, "checkpoint_lobby")
		add_child(cp)
		## Auto-rest on first entry so dying before any rest isn't a soft-lock at apex.
		if not GameState.is_checkpoint_activated("tower_lobby", "clockwork_tower"):
			GameState.activate_checkpoint("tower_lobby", "clockwork_tower", cp.position, "Tower Lobby")

	var lobby_lamp := _make_hanging_lamp("lobby_lamp", Vector2(420, LOBBY_TOP - 120), 180.0, true)
	if lobby_lamp:
		add_child(lobby_lamp)
	if not LevelData.is_removed("clockwork_tower", "vent_lobby"):
		LevelCommon.add_steam_vent(self, _piece_pos("vent_lobby", Vector2(520, LOBBY_TOP)))
	if not LevelData.is_removed("clockwork_tower", "bench_lobby"):
		LevelCommon.add_bench(self, _piece_pos("bench_lobby", Vector2(340, LOBBY_TOP)))
	_spawn_grub(Vector2(480, LOBBY_TOP - 18))
	_spawn_grub(Vector2(620, LOBBY_TOP - 18))
	## Village door — bottom left.
	_make_village_exit(_piece_pos("exit_village", Vector2(110, LOBBY_TOP - 8)))


func _build_main_shaft() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 2200), Vector2(600, 360), "clockwork_tower", "climb", "Gear Shaft", "")
	## Continuous climb from lobby into the shaft (no sealed gap).
	var y := _climb_run(LOBBY_TOP - 20.0, 10, 220.0, 560.0)
	## Landing that opens into the side workshop.
	_floor_at(y - 10.0 + FLOOR_H * 0.5, 420.0, 400.0)
	_ledge(700, y - JUMP_REACH_Y, 160.0) ## doorway toward side room
	var mid_lamp := _make_hanging_lamp("climb_lamp", Vector2(400, y - 80), 150.0, true)
	if mid_lamp:
		add_child(mid_lamp)
	_spawn_beetle(Vector2(400, y - 28))


func _build_side_workshop() -> void:
	## Horizontal wing off the mid shaft (right side).
	var floor_y := 2140.0
	_floor_at(floor_y, 280.0, 960.0)
	LevelCommon.make_room_trigger(self, Vector2(960, floor_y - 80), Vector2(260, 160), "clockwork_tower", "workshop", "Gear Workshop", "")
	## Connect shaft landing → workshop
	_ledge(780, floor_y - FLOOR_H * 0.5 - 4.0, 120.0)
	_ledge(880, floor_y - FLOOR_H * 0.5 - 4.0, 100.0)
	LevelCommon.add_bench(self, Vector2(940, floor_y - FLOOR_H * 0.5))
	_spawn_jar(Vector2(1020, floor_y - FLOOR_H * 0.5 - 8))
	_spawn_mite(Vector2(980, floor_y - FLOOR_H * 0.5 - 16))
	var note := Label.new()
	note.text = "Workshop alcove"
	note.position = Vector2(900, floor_y - 90)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.65, 0.58, 0.45))
	add_child(note)


func _build_pendulum_cloister() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 1650), Vector2(640, 300), "clockwork_tower", "pendulum", "Pendulum Cloister", "")
	## Continue from shaft landing (~2122) — never leave a sealed vertical gap.
	var start_y := 2124.0
	var y := _climb_run(start_y, 8, 240.0, 540.0)
	## Split floors with jumpable gap (~70px < JUMP_SAFE)
	_floor_at(y - 8.0 + FLOOR_H * 0.5, 220.0, 220.0)
	_floor_at(y - 8.0 + FLOOR_H * 0.5, 220.0, 560.0)
	_ledge(390, y - JUMP_REACH_Y, 120.0)
	var cloister_lamp := _make_hanging_lamp("cloister_lamp", Vector2(390, y - JUMP_REACH_Y - 90), 160.0, true)
	if cloister_lamp:
		add_child(cloister_lamp)
	if not LevelData.is_removed("clockwork_tower", "cloister_switch"):
		var sw := LightSwitch.new()
		sw.position = _piece_pos("cloister_switch", Vector2(160, y - 8.0))
		sw.name = "cloister_switch"
		sw.starts_on = true
		sw.target_ids = PackedStringArray(["cloister_lamp"])
		var csw_saved := LevelData.merged_piece("clockwork_tower", "cloister_switch")
		if csw_saved.has("starts_on"):
			sw.starts_on = bool(csw_saved.get("starts_on"))
		if csw_saved.has("target_ids"):
			var tids: PackedStringArray = PackedStringArray()
			for t in csw_saved.get("target_ids", []):
				tids.append(str(t))
			if not tids.is_empty():
				sw.target_ids = tids
		LevelData.tag(sw, "cloister_switch")
		add_child(sw)
	var pend: Node = PendulumScript.new()
	pend.position = Vector2(320, y - JUMP_REACH_Y - 140)
	pend.set("lamp_id", "cloister_lamp")
	pend.set("arm_length", 120.0)
	add_child(pend)
	var pend2: Node = PendulumScript.new()
	pend2.position = Vector2(480, y - JUMP_REACH_Y * 2.0 - 100)
	pend2.set("lamp_id", "cloister_lamp")
	pend2.set("arm_length", 110.0)
	pend2.set("swing_speed", 1.35)
	add_child(pend2)
	_spawn_beetle(Vector2(220, y - 24))
	## Continue upward into flue
	_climb_run(y - JUMP_REACH_Y * 2.0, 4, 250.0, 530.0)


func _build_steam_flue() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 1180), Vector2(640, 280), "clockwork_tower", "flue", "Steam Flue", "")
	## Pick up from cloister continuation (~1708 after 8 steps from 2124).
	var y := 1710.0
	for i in 10:
		y -= JUMP_REACH_Y
		var x := 250.0 if i % 2 == 0 else 530.0
		_ledge(x, y, LEDGE_W)
		LevelCommon.add_steam_vent(self, Vector2(x, y))
		if i % 2 == 1:
			_spawn_beetle(Vector2(x, y - 16))
		else:
			_spawn_grub(Vector2(x, y - 16))
	_ledge(390, y - JUMP_REACH_Y, 160.0)
	var flue_lamp := _make_floor_lamp("flue_lamp", Vector2(390, y - JUMP_REACH_Y - 8), 130.0, false)
	if flue_lamp:
		add_child(flue_lamp)
	if not LevelData.is_removed("clockwork_tower", "flue_switch"):
		var fsw := LightSwitch.new()
		fsw.position = _piece_pos("flue_switch", Vector2(300, y - JUMP_REACH_Y))
		fsw.starts_on = false
		fsw.target_ids = PackedStringArray(["flue_lamp"])
		var fsw_saved := LevelData.merged_piece("clockwork_tower", "flue_switch")
		if fsw_saved.has("starts_on"):
			fsw.starts_on = bool(fsw_saved.get("starts_on"))
		LevelData.tag(fsw, "flue_switch")
		add_child(fsw)


func _build_side_archive() -> void:
	## Left horizontal wing near flue top.
	var floor_y := 1120.0
	_floor_at(floor_y, 260.0, 160.0)
	_ledge(300, floor_y - FLOOR_H * 0.5 - 4.0, 110.0)
	LevelCommon.make_room_trigger(self, Vector2(160, floor_y - 70), Vector2(240, 140), "clockwork_tower", "archive", "Ash Archive", "")
	_spawn_jar(Vector2(120, floor_y - FLOOR_H * 0.5 - 8))
	_spawn_mite(Vector2(180, floor_y - FLOOR_H * 0.5 - 16))
	var lamp := _make_hanging_lamp("archive_lamp", Vector2(160, floor_y - 100), 120.0, true)
	if lamp:
		add_child(lamp)


func _build_switch_gallery() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 820), Vector2(640, 220), "clockwork_tower", "gallery", "Switch Gallery", "")
	## Flue ends ~1710-520=1190; continue without a sealed gap.
	var y := _climb_run(1192.0, 7, 240.0, 540.0)
	_floor_at(y - 12.0 + FLOOR_H * 0.5, 560.0, 400.0)
	var floor_top := y - 12.0
	var la := _make_floor_lamp("practice_a", Vector2(260, floor_top - 8), 100.0, true)
	var lb := _make_floor_lamp("practice_b", Vector2(400, floor_top - 8), 100.0, false)
	var lc := _make_floor_lamp("practice_c", Vector2(540, floor_top - 8), 100.0, true)
	if la:
		add_child(la)
	if lb:
		add_child(lb)
	if lc:
		add_child(lc)
	for pair in [["practice_sw_a", "practice_a", 220.0, true], ["practice_sw_b", "practice_b", 360.0, false], ["practice_sw_c", "practice_c", 500.0, true]]:
		var sid := str(pair[0])
		if LevelData.is_removed("clockwork_tower", sid):
			continue
		var s := LightSwitch.new()
		s.position = _piece_pos(sid, Vector2(float(pair[2]), floor_top))
		s.name = sid
		s.starts_on = bool(pair[3])
		s.target_ids = PackedStringArray([str(pair[1])])
		LevelData.tag(s, sid)
		add_child(s)
	var hint := Label.new()
	hint.text = "Practice the Hour — flip levers to match lamp patterns."
	hint.position = Vector2(200, floor_top - 70)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.5))
	add_child(hint)
	_spawn_beetle(Vector2(320, floor_top - 18))
	_spawn_beetle(Vector2(480, floor_top - 18))
	## Steps up to antechamber (keep ≤ JUMP_REACH_Y).
	_climb_run(floor_top, 5, 260.0, 520.0)


func _build_antechamber() -> void:
	## Checkpoint BEFORE the boss — death during the fight returns here.
	_floor_at(ANTECHAMBER_FLOOR, 560.0, 400.0)
	LevelCommon.make_room_trigger(self, Vector2(400, ANTECHAMBER_TOP - 80), Vector2(520, 160), "clockwork_tower", "antechamber", "Dial Gate", "Rest before the Wickwright.")
	if not LevelData.is_removed("clockwork_tower", "checkpoint_antechamber"):
		var cp := Checkpoint.new()
		cp.position = _piece_pos("checkpoint_antechamber", Vector2(220, ANTECHAMBER_TOP))
		cp.checkpoint_id = "tower_antechamber"
		cp.checkpoint_name = "Dial Gate"
		LevelData.tag(cp, "checkpoint_antechamber")
		add_child(cp)
	## Climb into arena — ~5 jump steps from antechamber floor to arena floor.
	_climb_run(ANTECHAMBER_TOP, 5, 320.0, 480.0)


func _build_arena() -> void:
	LevelCommon.make_room_trigger(self, Vector2(400, ARENA_TOP - 90), Vector2(560, 220), "clockwork_tower", "arena", "Dial Arena", "")
	_floor_at(ARENA_FLOOR, 620.0, 400.0)
	var mosaic := Polygon2D.new()
	mosaic.z_index = -5
	mosaic.position = Vector2(400, ARENA_TOP - 2)
	mosaic.color = Color(0.35, 0.28, 0.18, 0.55)
	var mpts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		mpts.append(Vector2(cos(a), sin(a)) * 70.0)
	mosaic.polygon = mpts
	add_child(mosaic)

	## Floor lanterns (Match the Hour) — no dangling chains.
	var ids := ["tower_lamp_a", "tower_lamp_b", "tower_lamp_c"]
	var xs := [250.0, 400.0, 550.0]
	var starts := [true, false, true]
	for i in 3:
		var lamp := _make_floor_lamp(ids[i], Vector2(xs[i], ARENA_TOP - 8), 130.0, starts[i])
		if lamp:
			add_child(lamp)

	## High levers that control those floor lanterns (boss yanks these).
	var lever_y := ARENA_TOP - 110.0
	_ledge(250, lever_y, 90.0)
	_ledge(400, lever_y, 90.0)
	_ledge(550, lever_y, 90.0)
	var switch_ids := ["tower_switch_a", "tower_switch_b", "tower_switch_c"]
	for i in 3:
		var sw_id: String = str(switch_ids[i])
		if LevelData.is_removed("clockwork_tower", sw_id):
			continue
		var sw := LightSwitch.new()
		sw.position = _piece_pos(sw_id, Vector2(xs[i], lever_y))
		sw.name = sw_id
		sw.starts_on = starts[i]
		sw.target_ids = PackedStringArray([ids[i]])
		LevelData.tag(sw, sw.name)
		add_child(sw)

	## Invisible wake trigger — boss sleeps until player steps in.
	var wake := Area2D.new()
	wake.name = "BossWake"
	wake.collision_layer = 0
	wake.collision_mask = 2
	wake.monitoring = true
	var wcs := CollisionShape2D.new()
	var wr := RectangleShape2D.new()
	wr.size = Vector2(560, 180)
	wcs.shape = wr
	wcs.position = Vector2(400, ARENA_TOP - 70)
	wake.add_child(wcs)
	wake.body_entered.connect(_on_arena_entered)
	add_child(wake)

	## Gate seals the antechamber exit once the fight starts.
	_arena_gate = StaticBody2D.new()
	_arena_gate.name = "ArenaGate"
	_arena_gate.collision_layer = 1
	_arena_gate.collision_mask = 0
	_arena_gate.position = Vector2(400, ANTECHAMBER_TOP - JUMP_REACH_Y * 2.0 + 10.0)
	var gcs := CollisionShape2D.new()
	var grect := RectangleShape2D.new()
	grect.size = Vector2(180, 28)
	gcs.shape = grect
	gcs.disabled = true
	_arena_gate.add_child(gcs)
	var gvis := Polygon2D.new()
	gvis.name = "GateVis"
	gvis.color = Color(0.35, 0.28, 0.2, 0.0)
	gvis.polygon = PackedVector2Array([
		Vector2(-90, -14), Vector2(90, -14), Vector2(90, 14), Vector2(-90, 14)
	])
	_arena_gate.add_child(gvis)
	add_child(_arena_gate)

	if GameState.wickwright_defeated():
		if not GameState.is_collected("tower_crystal_piece"):
			var chest: Node = RewardChestScript.new()
			chest.position = Vector2(400, ARENA_TOP - 8)
			add_child(chest)
		_spawn_broken_wall_decor(Vector2(MAP_W - 80, ARENA_TOP - 100))
	else:
		_boss = WickwrightScript.new()
		_boss.position = Vector2(400, ARENA_TOP - 140)
		add_child(_boss)
		if _boss.has_signal("defeated"):
			_boss.connect("defeated", _on_boss_defeated)


func _on_arena_entered(body: Node) -> void:
	if _boss_awake or GameState.wickwright_defeated():
		return
	if not (body is Player or (body and body.is_in_group("player"))):
		return
	_boss_awake = true
	## Seal exit back to antechamber.
	if _arena_gate:
		for c in _arena_gate.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = false
			elif c is Polygon2D:
				(c as Polygon2D).color.a = 0.9
	## Force rest hearth to antechamber so death mid-fight resets there.
	GameState.activate_checkpoint(
		"tower_antechamber",
		"clockwork_tower",
		Vector2(220, ANTECHAMBER_TOP),
		"Dial Gate"
	)
	if _boss and _boss.has_method("awaken"):
		_boss.call("awaken")


func _make_village_exit(pos: Vector2) -> void:
	var exit: Node = VillageDoorScript.new()
	exit.position = pos
	add_child(exit)


func _piece_pos(catalog_id: String, fallback: Vector2) -> Vector2:
	var saved := LevelData.merged_piece("clockwork_tower", catalog_id)
	if saved.is_empty():
		return fallback
	if saved.has("x") and saved.has("y"):
		return Vector2(float(saved.get("x")), float(saved.get("y")))
	return fallback


func _make_hanging_lamp(id: String, pos: Vector2, radius: float, on: bool) -> LightSource:
	if LevelData.is_removed("clockwork_tower", id):
		return null
	var saved := LevelData.merged_piece("clockwork_tower", id)
	if not saved.is_empty():
		if saved.has("x") and saved.has("y"):
			pos = Vector2(float(saved.get("x")), float(saved.get("y")))
		if saved.has("radius"):
			radius = float(saved.get("radius"))
	var lamp := LightSource.new()
	lamp.name = id
	lamp.position = pos
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = radius
	lamp.shadow_length = radius + 40.0
	lamp.pushable = false
	lamp.is_enabled = on
	if saved.has("intensity"):
		lamp.set_intensity(float(saved.get("intensity", 1.0)))
	## Let LightSource hang a chain to ceiling_y.
	LevelData.tag(lamp, id)
	return lamp

func _make_floor_lamp(id: String, pos: Vector2, radius: float, on: bool) -> LightSource:
	var lamp := _make_hanging_lamp(id, pos, radius, on)
	if lamp == null:
		return null
	## Skip auto-chain — these sit on the floor / pedestals.
	lamp.set_meta("has_chain", true)
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
	## Open the gate again after victory.
	if _arena_gate:
		for c in _arena_gate.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = true
			elif c is Polygon2D:
				(c as Polygon2D).color.a = 0.0
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

	var chest: Node = RewardChestScript.new()
	chest.position = Vector2(boss.global_position.x, ARENA_TOP - 8)
	add_child(chest)

	var saved_zoom := Vector2(1.2, 1.2)
	if cam and player:
		saved_zoom = cam.zoom
		cam.reparent(boss)
		cam.position = Vector2(0, -20)
		var tw := create_tween()
		tw.tween_property(cam, "zoom", Vector2(1.55, 1.55), 0.5)
		await tw.finished

	await get_tree().create_timer(0.4).timeout
	_spawn_broken_wall_decor(Vector2(MAP_W - 60, ARENA_TOP - 110))
	var tw2 := create_tween()
	tw2.tween_property(boss, "global_position", Vector2(MAP_W + 40, ARENA_TOP - 140), 0.55).set_ease(Tween.EASE_IN)
	await tw2.finished
	var tw3 := create_tween()
	tw3.tween_property(boss, "global_position", Vector2(MAP_W + 120, ARENA_TOP + 360), 0.85).set_ease(Tween.EASE_IN)
	tw3.parallel().tween_property(boss, "rotation", 2.8, 0.85)
	tw3.parallel().tween_property(boss, "modulate:a", 0.0, 0.85)
	await tw3.finished

	GameState.mark_collected("wickwright_defeated")
	SaveManager.autosave()

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
