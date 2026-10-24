extends Node2D
## Tutorial cottage: floor-aligned props, pull puzzle, lamp cover platform.


const FLOOR_CENTER := 520.0
const FLOOR_H := 40.0
const FLOOR_TOP := FLOOR_CENTER - FLOOR_H * 0.5  # 500
const MAP_W := 4000.0
const CEIL_Y := 40.0


func _ready() -> void:
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 100.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, MAP_W, 720, FLOOR_TOP)

	LevelCommon.add_steel_floor(self, MAP_W * 0.5, FLOOR_CENTER, MAP_W, FLOOR_H)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_wall(self, MAP_W - 20, 300, 40, 480)
	LevelCommon.add_wall(self, MAP_W * 0.5, CEIL_Y, MAP_W, 40)

	for i in 5:
		LevelCommon.add_brick_wall_face(self, 400.0 + i * 800.0, 260.0, 800.0, 320.0)

	LevelCommon.add_pipe(self, Vector2(40, 90), Vector2(MAP_W - 100, 90), 14.0)
	LevelCommon.add_pipe(self, Vector2(220, 90), Vector2(220, 200), 10.0)
	LevelCommon.add_valve(self, Vector2(220, 200))
	LevelCommon.add_window(self, 180, 200, 50, 70, true)
	LevelCommon.add_window(self, 980, 200, 50, 70, true)
	LevelCommon.add_window(self, 1780, 200, 50, 70, true)
	LevelCommon.add_window(self, 2580, 200, 56, 74, true)
	LevelCommon.add_window(self, 3380, 200, 50, 70, true)

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
	LevelCommon.spawn_player(self, spawn)
	GameState.enter_room("cursed_cottage", "hall")
	SaveManager.autosave()


func _box_y(size_y: float = 48.0) -> float:
	return FLOOR_TOP - size_y * 0.5


func _build_room_triggers() -> void:
	LevelCommon.make_room_trigger(self, Vector2(400, 360), Vector2(800, 400), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1200, 360), Vector2(800, 400), "cursed_cottage", "crate", "Walk into the crate to push it under the lamp", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(2000, 360), Vector2(800, 400), "cursed_cottage", "pull", "Hold V beside the crate and walk to pull it from the wall", "pull")
	LevelCommon.make_room_trigger(self, Vector2(2800, 360), Vector2(800, 400), "cursed_cottage", "chest", "Jump the ledges", "jump")
	LevelCommon.make_room_trigger(self, Vector2(3600, 360), Vector2(800, 400), "cursed_cottage", "hatch", "Aim and F to break — crouch for down slash", "attack")


func _build_crate_room() -> void:
	## Hearth lamp above a floating cover platform; push crate for umbra.
	var platform := LevelCommon.add_steel_floor(self, 1120, FLOOR_TOP - 90, 160, 20)
	platform.name = "LampCoverPlatform"
	var lamp := LightSource.new()
	lamp.position = Vector2(1120, FLOOR_TOP - 200)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 260.0
	lamp.shadow_length = 320.0
	lamp.pushable = false
	add_child(lamp)
	var box := PushableBox.new()
	box.position = Vector2(980, _box_y())
	box.box_size = Vector2(48, 48)
	add_child(box)


func _build_pull_room() -> void:
	## Low wall on the LEFT; crate flush against it. Pull right, then jump the wall with the crate as a step.
	var wall_h := 52.0
	var wall_top := FLOOR_TOP - wall_h * 0.5
	LevelCommon.add_wall(self, 1880, wall_top, 28, wall_h)
	var box := PushableBox.new()
	box.position = Vector2(1880 + 14 + 24, _box_y())  # against the right face of the left wall
	box.box_size = Vector2(48, 48)
	box.name = "PullCrate"
	add_child(box)
	# Landmark pipe above
	LevelCommon.add_pipe(self, Vector2(1860, 300), Vector2(2100, 300), 8.0)


func _build_jump_room() -> void:
	LevelCommon.add_steel_floor(self, 2700, FLOOR_TOP - 60, 140, 24)
	LevelCommon.add_steel_floor(self, 2840, FLOOR_TOP - 110, 100, 24)
	LevelCommon.add_pipe(self, Vector2(2580, 380), Vector2(2900, 380), 8.0)


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
	moon.position = Vector2(400, 120)
	moon.light_kind = GameState.LightKind.MOON
	moon.radius = 160.0
	moon.shadow_length = 200.0
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
