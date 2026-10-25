extends Node2D
## Vertical Clockwork Tower — story floors linked by climb ladders (hold W) + side rooms.


const FLOOR_H := 36.0
const STORY_GAP := 200.0 ## Typical ladder span between story tops.

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

## Story tops (walkable surface Y), bottom → top. Ladders span between consecutive stories.
const STORY_SHAFT_1 := LOBBY_TOP - STORY_GAP ## 2462
const STORY_SHAFT_2 := STORY_SHAFT_1 - STORY_GAP ## 2262
const STORY_CLOISTER := STORY_SHAFT_2 - STORY_GAP ## 2062
const STORY_PENDULUM := STORY_CLOISTER - STORY_GAP ## 1862
const STORY_FLUE_1 := STORY_PENDULUM - STORY_GAP ## 1662
const STORY_FLUE_2 := STORY_FLUE_1 - STORY_GAP ## 1462
const STORY_ARCHIVE := STORY_FLUE_2 - STORY_GAP ## 1262
const STORY_GALLERY := STORY_ARCHIVE - STORY_GAP ## 1062
const STORY_PRE_GATE := STORY_GALLERY - STORY_GAP ## 862

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
var _hinted_ladder: bool = false


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
	call_deferred("_maybe_hint_ladder")


func _maybe_hint_ladder() -> void:
	if _hinted_ladder:
		return
	_hinted_ladder = true
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Hold W on a ladder to climb", 3.5)


func _room_for_y(y: float) -> String:
	if y > 2400.0:
		return "lobby"
	if y > 2100.0:
		return "climb"
	if y > 1600.0:
		return "pendulum"
	if y > 1200.0:
		return "flue"
	if y > 900.0:
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
	## Universal #0d020f fire-sky; brick faces cover it where the shaft is built.
	LevelCommon.add_backdrop(
		self, MAP_W, LOBBY_FLOOR + 200.0, LOBBY_TOP, ROOF_TOP, false,
		LevelData.backdrop_for("clockwork_tower")
	)
	## Dense brick faces — fills the tall void so the shaft reads as a built tower.
	var y := LOBBY_TOP - 80.0
	while y > ROOF_TOP + 40.0:
		LevelCommon.add_brick_wall_face(self, MAP_W * 0.42, y, 720.0, 180.0)
		LevelCommon.add_brick_wall_face(self, MAP_W * 0.72, y - 40.0, 380.0, 140.0)
		y -= 160.0
	## Decorative gears on a few stories.
	for gy in [STORY_SHAFT_1 - 60.0, STORY_CLOISTER - 80.0, STORY_FLUE_1 - 70.0, STORY_GALLERY - 60.0]:
		LevelCommon.add_bg_gear(self, Vector2(180, gy), 55.0, 10.0 + randf() * 6.0)
		LevelCommon.add_bg_gear(self, Vector2(700, gy - 30.0), 40.0, -8.0 - randf() * 5.0)
	LevelCommon.add_wall(self, 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	LevelCommon.add_wall(self, MAP_W - 20, (ROOF_TOP + LOBBY_FLOOR) * 0.5, 40, LOBBY_FLOOR - ROOF_TOP + 120)
	## Full-width underfloor so nothing reads as a hole under the lobby.
	LevelCommon.add_underfloor_fill(self, MAP_W, LOBBY_FLOOR + FLOOR_H * 0.5)
	## Overhead rail so hanging lanterns attach to something.
	LevelCommon.add_pipe(self, Vector2(60, ROOF_TOP + 30), Vector2(MAP_W - 60, ROOF_TOP + 30), 12.0)
	LevelCommon.add_pipe(self, Vector2(50, LOBBY_TOP - 40), Vector2(50, ARENA_TOP + 20), 10.0)
	LevelCommon.add_pipe(self, Vector2(SHAFT_R + 20, LOBBY_TOP - 40), Vector2(SHAFT_R + 20, ARENA_TOP + 20), 10.0)


func _floor_at(y_center: float, width: float = MAP_W, x: float = -1.0) -> void:
	var cx := MAP_W * 0.5 if x < 0.0 else x
	LevelCommon.add_steel_floor(self, cx, y_center, width, FLOOR_H)


func _story(top_y: float, width: float = 640.0, x: float = 400.0, hatches: Array = []) -> void:
	## Optional hatch X positions leave gaps so ladders pass through the floor plate.
	if hatches.is_empty():
		_floor_at(top_y + FLOOR_H * 0.5, width, x)
		return
	var left := x - width * 0.5
	var right := x + width * 0.5
	var gaps: Array = hatches.duplicate()
	gaps.sort()
	var cursor := left
	for hx in gaps:
		var gap_l := float(hx) - 22.0
		var gap_r := float(hx) + 22.0
		if gap_l > cursor + 28.0:
			var w := gap_l - cursor
			_floor_at(top_y + FLOOR_H * 0.5, w, cursor + w * 0.5)
		cursor = maxf(cursor, gap_r)
	if right > cursor + 28.0:
		var w2 := right - cursor
		_floor_at(top_y + FLOOR_H * 0.5, w2, cursor + w2 * 0.5)


func _ledge(x: float, top_y: float, w: float = 140.0) -> void:
	LevelCommon.add_steel_floor(self, x, top_y + FLOOR_H * 0.5, w, FLOOR_H)


func _ladder(x: float, bottom_top: float, top_top: float) -> void:
	var h := bottom_top - top_top
	if h < 40.0:
		return
	LevelCommon.add_ladder(self, Vector2(x, bottom_top), h)


func _build_lobby() -> void:
	## Full-width lobby floor — seals the gaping hole toward the map edges.
	_floor_at(LOBBY_FLOOR, MAP_W - 80.0, MAP_W * 0.5)
	LevelCommon.make_room_trigger(self, Vector2(MAP_W * 0.5, LOBBY_TOP - 100), Vector2(MAP_W - 120.0, 180), "clockwork_tower", "lobby", "Clockwork Lobby", "")
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
	_spawn_grub(Vector2(720, LOBBY_TOP - 18))
	## First ladder up into the shaft (right of hearth).
	_ladder(600, LOBBY_TOP, STORY_SHAFT_1)
	## Village door — bottom left.
	_make_village_exit(_piece_pos("exit_village", Vector2(110, LOBBY_TOP - 8)))


func _build_main_shaft() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 2360), Vector2(640, 280), "clockwork_tower", "climb", "Gear Shaft", "")
	## Story landings + alternating ladders (readable climb, no jump spam).
	## Hatch at 600 matches lobby ladder arrival.
	_story(STORY_SHAFT_1, 560.0, 400.0, [600.0])
	_ladder(220, STORY_SHAFT_1, STORY_SHAFT_2)
	_spawn_mite(Vector2(360, STORY_SHAFT_1 - 16))

	_story(STORY_SHAFT_2, 560.0, 400.0, [220.0])
	_ladder(580, STORY_SHAFT_2, STORY_CLOISTER)
	_ledge(720, STORY_SHAFT_2, 140.0) ## doorway toward workshop
	var mid_lamp := _make_hanging_lamp("climb_lamp", Vector2(400, STORY_SHAFT_2 - 90), 150.0, true)
	if mid_lamp:
		add_child(mid_lamp)
	_spawn_beetle(Vector2(400, STORY_SHAFT_2 - 28))


func _build_side_workshop() -> void:
	## Horizontal wing off shaft story 2.
	var floor_y := STORY_SHAFT_2 + FLOOR_H * 0.5
	_floor_at(floor_y, 280.0, 960.0)
	LevelCommon.make_room_trigger(self, Vector2(960, STORY_SHAFT_2 - 80), Vector2(260, 160), "clockwork_tower", "workshop", "Gear Workshop", "")
	_ledge(800, STORY_SHAFT_2, 120.0)
	_ledge(880, STORY_SHAFT_2, 100.0)
	LevelCommon.add_bench(self, Vector2(940, STORY_SHAFT_2))
	_spawn_jar(Vector2(1020, STORY_SHAFT_2 - 8))
	_spawn_mite(Vector2(980, STORY_SHAFT_2 - 16))
	_spawn_world_text(
		"text_workshop",
		"Workshop alcove",
		Vector2(980, STORY_SHAFT_2 - 90),
		12,
		Color("a69473"),
		Vector2(160, 24)
	)


func _build_pendulum_cloister() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 1960), Vector2(640, 280), "clockwork_tower", "pendulum", "Pendulum Cloister", "")
	_story(STORY_CLOISTER, 560.0, 400.0, [580.0])
	_ladder(240, STORY_CLOISTER, STORY_PENDULUM)
	_spawn_beetle(Vector2(420, STORY_CLOISTER - 24))

	## Split floors with a jumpable gap under swinging pendulums + hatch at 240 for ladder.
	_floor_at(STORY_PENDULUM + FLOOR_H * 0.5, 180.0, 200.0)
	_floor_at(STORY_PENDULUM + FLOOR_H * 0.5, 220.0, 560.0)
	_ledge(390, STORY_PENDULUM - 4.0, 100.0)
	_ladder(560, STORY_PENDULUM, STORY_FLUE_1)
	var cloister_lamp := _make_hanging_lamp("cloister_lamp", Vector2(390, STORY_PENDULUM - 100), 160.0, true)
	if cloister_lamp:
		add_child(cloister_lamp)
	if not LevelData.is_removed("clockwork_tower", "cloister_switch"):
		var sw := LightSwitch.new()
		sw.position = _piece_pos("cloister_switch", Vector2(160, STORY_PENDULUM))
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
	pend.position = Vector2(320, STORY_PENDULUM - 140)
	pend.set("lamp_id", "cloister_lamp")
	pend.set("arm_length", 120.0)
	add_child(pend)
	var pend2: Node = PendulumScript.new()
	pend2.position = Vector2(480, STORY_PENDULUM - 160)
	pend2.set("lamp_id", "cloister_lamp")
	pend2.set("arm_length", 110.0)
	pend2.set("swing_speed", 1.35)
	add_child(pend2)


func _build_steam_flue() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 1560), Vector2(640, 280), "clockwork_tower", "flue", "Steam Flue", "")
	_story(STORY_FLUE_1, 560.0, 400.0, [560.0])
	LevelCommon.add_steam_vent(self, Vector2(300, STORY_FLUE_1))
	LevelCommon.add_steam_vent(self, Vector2(500, STORY_FLUE_1))
	_ladder(260, STORY_FLUE_1, STORY_FLUE_2)
	_spawn_grub(Vector2(420, STORY_FLUE_1 - 16))

	_story(STORY_FLUE_2, 560.0, 400.0, [260.0])
	LevelCommon.add_steam_vent(self, Vector2(340, STORY_FLUE_2))
	LevelCommon.add_steam_vent(self, Vector2(480, STORY_FLUE_2))
	_ladder(560, STORY_FLUE_2, STORY_ARCHIVE)
	_spawn_beetle(Vector2(400, STORY_FLUE_2 - 16))
	var flue_lamp := _make_floor_lamp("flue_lamp", Vector2(400, STORY_FLUE_2 - 8), 130.0, false)
	if flue_lamp:
		add_child(flue_lamp)
	if not LevelData.is_removed("clockwork_tower", "flue_switch"):
		var fsw := LightSwitch.new()
		fsw.position = _piece_pos("flue_switch", Vector2(300, STORY_FLUE_2))
		fsw.starts_on = false
		fsw.target_ids = PackedStringArray(["flue_lamp"])
		var fsw_saved := LevelData.merged_piece("clockwork_tower", "flue_switch")
		if fsw_saved.has("starts_on"):
			fsw.starts_on = bool(fsw_saved.get("starts_on"))
		LevelData.tag(fsw, "flue_switch")
		add_child(fsw)


func _build_side_archive() -> void:
	## Left horizontal wing near archive story.
	_story(STORY_ARCHIVE, 560.0, 400.0, [560.0])
	_ladder(240, STORY_ARCHIVE, STORY_GALLERY)
	_floor_at(STORY_ARCHIVE + FLOOR_H * 0.5, 260.0, 160.0)
	_ledge(300, STORY_ARCHIVE, 110.0)
	LevelCommon.make_room_trigger(self, Vector2(160, STORY_ARCHIVE - 70), Vector2(240, 140), "clockwork_tower", "archive", "Ash Archive", "")
	_spawn_jar(Vector2(120, STORY_ARCHIVE - 8))
	_spawn_mite(Vector2(180, STORY_ARCHIVE - 16))
	var lamp := _make_hanging_lamp("archive_lamp", Vector2(160, STORY_ARCHIVE - 100), 120.0, true)
	if lamp:
		add_child(lamp)


func _build_switch_gallery() -> void:
	LevelCommon.make_room_trigger(self, Vector2(430, 960), Vector2(640, 240), "clockwork_tower", "gallery", "Switch Gallery", "")
	_story(STORY_GALLERY, 560.0, 400.0, [240.0])
	_ladder(560, STORY_GALLERY, STORY_PRE_GATE)
	var floor_top := STORY_GALLERY
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
	_spawn_world_text(
		"text_gallery",
		"Practice the Hour — flip levers to match lamp patterns.",
		Vector2(360, floor_top - 70),
		13,
		Color("bfad80"),
		Vector2(320, 28)
	)
	_spawn_beetle(Vector2(320, floor_top - 18))
	_spawn_beetle(Vector2(480, floor_top - 18))

	## Pre-gate landing then ladder into antechamber.
	_story(STORY_PRE_GATE, 520.0, 400.0, [560.0])
	_ladder(320, STORY_PRE_GATE, ANTECHAMBER_TOP)
	_spawn_mite(Vector2(450, STORY_PRE_GATE - 16))


func _build_antechamber() -> void:
	## Checkpoint BEFORE the boss — death during the fight returns here.
	## Hatch at 320 for pre-gate ladder; hatch at 480 for arena ladder climb-through.
	_story(ANTECHAMBER_TOP, 560.0, 400.0, [320.0])
	LevelCommon.make_room_trigger(self, Vector2(400, ANTECHAMBER_TOP - 80), Vector2(520, 160), "clockwork_tower", "antechamber", "Dial Gate", "Rest before the Wickwright.")
	if not LevelData.is_removed("clockwork_tower", "checkpoint_antechamber"):
		var cp := Checkpoint.new()
		cp.position = _piece_pos("checkpoint_antechamber", Vector2(220, ANTECHAMBER_TOP))
		cp.checkpoint_id = "tower_antechamber"
		cp.checkpoint_name = "Dial Gate"
		LevelData.tag(cp, "checkpoint_antechamber")
		add_child(cp)
	## Ladder into the arena.
	_ladder(480, ANTECHAMBER_TOP, ARENA_TOP)


func _build_arena() -> void:
	LevelCommon.make_room_trigger(self, Vector2(400, ARENA_TOP - 90), Vector2(560, 220), "clockwork_tower", "arena", "Dial Arena", "")
	## Hatch at 480 for antechamber ladder arrival.
	_story(ARENA_TOP, 620.0, 400.0, [480.0])
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
	## Short ladders up to each lever ledge (ledges are open at the ends).
	_ladder(220, ARENA_TOP, lever_y)
	_ladder(400, ARENA_TOP, lever_y)
	_ladder(580, ARENA_TOP, lever_y)
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
	_arena_gate.position = Vector2(400, ANTECHAMBER_TOP - 100.0)
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
	if LevelData.is_removed("clockwork_tower", "exit_village"):
		return
	var exit: ZoneLinkDoor = VillageDoorScript.new()
	exit.position = pos
	exit.target_zone = "lantern_village"
	exit.spawn_pos = Vector2(ClockworkTower.VILLAGE_DOOR_X - 80.0, 460)
	exit.travel_caption = "Back to Lantern Village…"
	exit.verb = "Village"
	exit.show_exit_arrow = false
	var saved := LevelData.merged_piece("clockwork_tower", "exit_village")
	if not saved.is_empty():
		if saved.has("x") and saved.has("y"):
			exit.position = Vector2(float(saved.get("x")), float(saved.get("y")))
		if saved.has("target_zone") and str(saved.get("target_zone", "")) != "":
			exit.target_zone = str(saved.get("target_zone"))
		if saved.has("spawn_x") or saved.has("spawn_y"):
			exit.spawn_pos = Vector2(
				float(saved.get("spawn_x", exit.spawn_pos.x)),
				float(saved.get("spawn_y", exit.spawn_pos.y))
			)
		if saved.has("caption") and str(saved.get("caption", "")) != "":
			exit.travel_caption = str(saved.get("caption"))
	LevelData.tag(exit, "exit_village")
	add_child(exit)


func _piece_pos(catalog_id: String, fallback: Vector2) -> Vector2:
	var saved := LevelData.merged_piece("clockwork_tower", catalog_id)
	if saved.is_empty():
		return fallback
	if saved.has("x") and saved.has("y"):
		return Vector2(float(saved.get("x")), float(saved.get("y")))
	return fallback


func _spawn_world_text(
	catalog_id: String,
	fallback_text: String,
	fallback_pos: Vector2,
	fallback_size: int,
	fallback_color: Color,
	fallback_box: Vector2
) -> void:
	if LevelData.is_removed("clockwork_tower", catalog_id):
		return
	var saved := LevelData.merged_piece("clockwork_tower", catalog_id)
	var pos := fallback_pos
	var text := fallback_text
	var font_size := fallback_size
	var col := fallback_color
	var box := fallback_box
	if not saved.is_empty():
		if saved.has("x") and saved.has("y"):
			pos = Vector2(float(saved.get("x")), float(saved.get("y")))
		if saved.has("text") and str(saved.get("text", "")) != "":
			text = str(saved.get("text"))
		elif saved.has("name") and str(saved.get("name", "")) != "":
			text = str(saved.get("name"))
		if saved.has("font_size"):
			font_size = int(saved.get("font_size"))
		if saved.has("color"):
			col = Color.html(str(saved.get("color")))
		if saved.has("w") and saved.has("h"):
			box = Vector2(float(saved.get("w")), float(saved.get("h")))
	var lbl := LevelCommon.add_world_label(self, pos, text, font_size, col, box)
	LevelData.tag(lbl, catalog_id)


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
