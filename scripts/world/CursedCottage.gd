extends Node2D
## Tutorial cottage: aligned steel floors, brick courses, and clear lesson landmarks.


const FLOOR_Y := 520.0
const MAP_W := 4000.0
const CEIL_Y := 40.0
const WALL_H := 480.0


func _ready() -> void:
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 100.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, MAP_W, 720)

	# Continuous floor + ceiling + end walls that meet cleanly.
	LevelCommon.add_steel_floor(self, MAP_W * 0.5, FLOOR_Y, MAP_W, 40)
	LevelCommon.add_wall(self, -20, 300, 40, WALL_H)
	LevelCommon.add_wall(self, MAP_W - 20, 300, 40, WALL_H)
	LevelCommon.add_wall(self, MAP_W * 0.5, CEIL_Y, MAP_W, 40)

	# Brick faces: abutting 800px rooms sharing one horizon under the ceiling.
	var face_y := 280.0
	var face_h := 360.0
	for i in 5:
		LevelCommon.add_brick_wall_face(self, 400.0 + i * 800.0, face_y, 800.0, face_h)

	# Continuous pipe run along the upper wall with drops at landmarks.
	LevelCommon.add_pipe(self, Vector2(40, 90), Vector2(MAP_W - 100, 90), 14.0)
	LevelCommon.add_pipe(self, Vector2(220, 90), Vector2(220, 200), 10.0)
	LevelCommon.add_valve(self, Vector2(220, 200))
	LevelCommon.add_window(self, 180, 210, 50, 70, true)
	LevelCommon.add_window(self, 980, 210, 50, 70, true)
	LevelCommon.add_window(self, 1780, 210, 50, 70, true)
	LevelCommon.add_window(self, 2580, 210, 56, 74, true)
	LevelCommon.add_window(self, 3380, 210, 50, 70, true)

	# Props sit on the floor skirting.
	LevelCommon.add_bench(self, Vector2(300, FLOOR_Y - 20))
	LevelCommon.add_steam_vent(self, Vector2(860, FLOOR_Y - 20))
	LevelCommon.add_crate_prop(self, Vector2(520, FLOOR_Y - 18), Vector2(36, 28))
	LevelCommon.add_crate_prop(self, Vector2(2920, FLOOR_Y - 18), Vector2(40, 30))

	_build_room_triggers()
	_build_crate_room()
	_build_pull_room()
	_build_jump_room()
	_build_hatch_room()
	_build_ambient_lamps()

	LevelData.apply(self, "cursed_cottage")

	var spawn := Vector2(120, FLOOR_Y - 40)
	if GameState.checkpoint_position != Vector2.ZERO and GameState.current_zone_id == "cursed_cottage" and not GameState.needs_intro_cutscene:
		spawn = GameState.checkpoint_position
	LevelCommon.spawn_player(self, spawn)
	GameState.enter_room("cursed_cottage", "hall")


func _build_room_triggers() -> void:
	LevelCommon.make_room_trigger(self, Vector2(400, 360), Vector2(800, 400), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1200, 360), Vector2(800, 400), "cursed_cottage", "crate", "Walk into the crate to push it", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(2000, 360), Vector2(800, 400), "cursed_cottage", "pull", "Hold V and walk to pull the crate", "pull")
	LevelCommon.make_room_trigger(self, Vector2(2800, 360), Vector2(800, 400), "cursed_cottage", "chest", "Jump the ledge", "jump")
	LevelCommon.make_room_trigger(self, Vector2(3600, 360), Vector2(800, 400), "cursed_cottage", "hatch", "Crouch (S) then F for down slash — or aim N/E/W", "attack")


func _build_crate_room() -> void:
	var box := PushableBox.new()
	box.position = Vector2(1200, FLOOR_Y - 24)
	box.box_size = Vector2(48, 48)
	add_child(box)
	var lamp := LightSource.new()
	lamp.position = Vector2(1050, 300)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 280.0
	lamp.shadow_length = 360.0
	lamp.pushable = true
	add_child(lamp)


func _build_pull_room() -> void:
	## Open alcove: wall to the right of a free crate so pull has room.
	LevelCommon.add_wall(self, 2200, 430, 36, 140)
	LevelCommon.add_steel_floor(self, 2100, FLOOR_Y - 20, 100, 20)
	var box := PushableBox.new()
	box.position = Vector2(2050, FLOOR_Y - 24)
	box.box_size = Vector2(48, 48)
	box.name = "PullCrate"
	add_child(box)
	LevelCommon.add_pipe(self, Vector2(2140, 300), Vector2(2140, 400), 8.0)


func _build_jump_room() -> void:
	LevelCommon.add_steel_floor(self, 2700, FLOOR_Y - 60, 140, 24)
	LevelCommon.add_steel_floor(self, 2820, FLOOR_Y - 100, 100, 24)
	LevelCommon.add_pipe(self, Vector2(2580, 400), Vector2(2900, 400), 8.0)


func _build_hatch_room() -> void:
	var door := BreakableDoor.new()
	door.position = Vector2(3550, FLOOR_Y - 72)
	door.door_size = Vector2(24, 80)
	door.next_scene = "res://scenes/rooms/LanternVillage.tscn"
	add_child(door)
	var cp := Checkpoint.new()
	cp.position = Vector2(3300, FLOOR_Y - 20)
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
