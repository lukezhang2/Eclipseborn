extends Node2D
## Compact cottage: roof at top of vision, occluding platforms, pull-wall puzzle.


## Camera zoom ~1.35 → visible height ≈ 533. Floor near bottom, roof near top.
const FLOOR_CENTER := 500.0
const FLOOR_H := 36.0
const FLOOR_TOP := FLOOR_CENTER - FLOOR_H * 0.5  # 482
const ROOF_CENTER := 200.0
const ROOF_H := 36.0
const ROOF_BOTTOM := ROOF_CENTER + ROOF_H * 0.5  # 218 — lines up with top of view
const MAP_W := 4000.0


func _ready() -> void:
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 100.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, MAP_W, 720, FLOOR_TOP, ROOF_CENTER - ROOF_H * 0.5)

	LevelCommon.add_steel_floor(self, MAP_W * 0.5, FLOOR_CENTER, MAP_W, FLOOR_H)
	LevelCommon.add_wall(self, -20, 360, 40, 360)
	LevelCommon.add_wall(self, MAP_W - 20, 360, 40, 360)
	# Roof — sits at top of player vision
	LevelCommon.add_wall(self, MAP_W * 0.5, ROOF_CENTER, MAP_W, ROOF_H)

	for i in 5:
		var face_h := FLOOR_TOP - ROOF_BOTTOM - 10.0
		var face_y := ROOF_BOTTOM + face_h * 0.5
		LevelCommon.add_brick_wall_face(self, 400.0 + i * 800.0, face_y, 800.0, face_h)

	LevelCommon.add_pipe(self, Vector2(40, ROOF_BOTTOM + 20), Vector2(MAP_W - 100, ROOF_BOTTOM + 20), 12.0)
	LevelCommon.add_pipe(self, Vector2(220, ROOF_BOTTOM + 20), Vector2(220, ROOF_BOTTOM + 90), 10.0)
	LevelCommon.add_valve(self, Vector2(220, ROOF_BOTTOM + 90))
	LevelCommon.add_window(self, 180, ROOF_BOTTOM + 100, 48, 56, true)
	LevelCommon.add_window(self, 980, ROOF_BOTTOM + 100, 48, 56, true)
	LevelCommon.add_window(self, 1780, ROOF_BOTTOM + 100, 48, 56, true)
	LevelCommon.add_window(self, 2580, ROOF_BOTTOM + 100, 52, 56, true)
	LevelCommon.add_window(self, 3380, ROOF_BOTTOM + 100, 48, 56, true)

	LevelCommon.add_bench(self, Vector2(300, FLOOR_TOP - 4))
	LevelCommon.add_steam_vent(self, Vector2(860, FLOOR_TOP - 4))
	LevelCommon.add_crate_prop(self, Vector2(520, FLOOR_TOP - 14), Vector2(36, 28))
	LevelCommon.add_crate_prop(self, Vector2(2920, FLOOR_TOP - 15), Vector2(40, 30))

	_build_room_triggers()
	_build_crate_room()
	_build_pull_room()
	_build_jump_room()
	_build_hatch_room()
	_build_ambient_lamps()
	_build_currency_breakables()

	LevelData.apply(self, "cursed_cottage")

	var spawn := Vector2(120, FLOOR_TOP - 40)
	if not GameState.needs_intro_cutscene and GameState.current_zone_id == "cursed_cottage":
		if GameState.last_position != Vector2.ZERO:
			spawn = GameState.last_position
		elif GameState.checkpoint_position != Vector2.ZERO:
			spawn = GameState.checkpoint_position
	var player := LevelCommon.spawn_player(self, spawn)
	LevelCommon.configure_camera(player, ROOF_CENTER - ROOF_H * 0.5, FLOOR_CENTER + FLOOR_H * 0.5 + 20.0, GameState.map_min_x, GameState.map_max_x)
	GameState.enter_room("cursed_cottage", "hall")
	SaveManager.autosave()


func _box_y(size_y: float = 48.0) -> float:
	return FLOOR_TOP - size_y * 0.5


func _build_room_triggers() -> void:
	LevelCommon.make_room_trigger(self, Vector2(400, 360), Vector2(800, 320), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1200, 360), Vector2(800, 320), "cursed_cottage", "crate", "Push the crate under the lamp for cover", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(2000, 360), Vector2(800, 320), "cursed_cottage", "pull", "Hold V, pull the crate out, then use it to jump the tall wall", "pull")
	LevelCommon.make_room_trigger(self, Vector2(2800, 360), Vector2(800, 320), "cursed_cottage", "chest", "Jump the ledges", "jump")
	LevelCommon.make_room_trigger(self, Vector2(3600, 360), Vector2(800, 320), "cursed_cottage", "hatch", "Aim and F to break", "attack")


func _build_crate_room() -> void:
	## Lamp above floating platform — platform occludes light so standing under it is safe.
	var platform_y := FLOOR_TOP - 100.0
	LevelCommon.add_steel_floor(self, 1120, platform_y, 180, 22)
	var lamp := LightSource.new()
	lamp.position = Vector2(1120, platform_y - 70.0)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 240.0
	lamp.shadow_length = 300.0
	lamp.pushable = false
	add_child(lamp)
	var box := PushableBox.new()
	box.position = Vector2(980, _box_y())
	box.box_size = Vector2(48, 48)
	add_child(box)


func _build_pull_room() -> void:
	## Tall wall blocks the path (too high to jump from the floor).
	## Crate starts against a left backstop — pull it out, climb it, clear the wall.
	var tall_h := 100.0  # jump alone ≈ 66px; needs the 48px crate as a step
	var tall_x := 2080.0
	LevelCommon.add_wall(self, tall_x, FLOOR_TOP - tall_h * 0.5, 32, tall_h)

	var backstop_h := 40.0
	var backstop_x := 1860.0
	LevelCommon.add_wall(self, backstop_x, FLOOR_TOP - backstop_h * 0.5, 24, backstop_h)

	var box := PushableBox.new()
	# Flush against the right face of the backstop.
	box.position = Vector2(backstop_x + 12 + 24, _box_y())
	box.box_size = Vector2(48, 48)
	box.name = "PullCrate"
	add_child(box)
	LevelCommon.add_pipe(self, Vector2(1840, ROOF_BOTTOM + 80), Vector2(2140, ROOF_BOTTOM + 80), 8.0)


func _build_jump_room() -> void:
	LevelCommon.add_steel_floor(self, 2700, FLOOR_TOP - 55, 140, 22)
	LevelCommon.add_steel_floor(self, 2840, FLOOR_TOP - 100, 100, 22)
	LevelCommon.add_pipe(self, Vector2(2580, ROOF_BOTTOM + 120), Vector2(2900, ROOF_BOTTOM + 120), 8.0)


func _build_hatch_room() -> void:
	var door := BreakableDoor.new()
	door.position = Vector2(3550, FLOOR_TOP - 40)
	door.door_size = Vector2(24, 80)
	door.next_scene = "res://scenes/rooms/LanternVillage.tscn"
	add_child(door)
	var cp := Checkpoint.new()
	cp.position = Vector2(3300, FLOOR_TOP - 4)
	cp.checkpoint_id = "cottage_hatch"
	add_child(cp)


func _build_ambient_lamps() -> void:
	var moon := LightSource.new()
	moon.position = Vector2(400, ROOF_BOTTOM + 40)
	moon.light_kind = GameState.LightKind.MOON
	moon.radius = 140.0
	moon.shadow_length = 180.0
	moon.pushable = false
	add_child(moon)


func _build_currency_breakables() -> void:
	_spawn_breakable("cottage_jar_a", Vector2(640, FLOOR_TOP - 18), 2)
	_spawn_breakable("cottage_jar_b", Vector2(1480, FLOOR_TOP - 18), 3)
	_spawn_breakable("cottage_jar_c", Vector2(2400, FLOOR_TOP - 18), 2)
	_spawn_breakable("cottage_chest", Vector2(3100, FLOOR_TOP - 16), 5, Vector2(40, 32))


func _spawn_breakable(id: String, pos: Vector2, drops: int, size: Vector2 = Vector2(28, 36)) -> void:
	if GameState.is_broken(id):
		return
	var prop := BreakableProp.new()
	prop.breakable_id = id
	prop.position = pos
	prop.prop_size = size
	prop.currency_drops = drops
	add_child(prop)
