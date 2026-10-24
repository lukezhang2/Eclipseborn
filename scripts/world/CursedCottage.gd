extends Node2D
## Four-room boiler-house tutorial with brick walls, pipes, and props.


func _ready() -> void:
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, 3200, 720)

	# Continuous floor and ceiling.
	LevelCommon.add_steel_floor(self, 1600, 520, 3200, 40)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_wall(self, 1600, 40, 3200, 40)

	# Brick faces per room stretch.
	LevelCommon.add_brick_wall_face(self, 350, 280, 700, 360)
	LevelCommon.add_brick_wall_face(self, 1050, 280, 700, 360)
	LevelCommon.add_brick_wall_face(self, 1750, 280, 700, 360)
	LevelCommon.add_brick_wall_face(self, 2450, 280, 700, 360)

	# Overhead pipe runs and valves.
	LevelCommon.add_pipe(self, Vector2(40, 90), Vector2(3100, 90), 14.0)
	LevelCommon.add_pipe(self, Vector2(220, 90), Vector2(220, 210), 10.0)
	LevelCommon.add_pipe(self, Vector2(980, 90), Vector2(980, 200), 10.0)
	LevelCommon.add_pipe(self, Vector2(1680, 90), Vector2(1680, 220), 10.0)
	LevelCommon.add_pipe(self, Vector2(2380, 90), Vector2(2380, 200), 10.0)
	LevelCommon.add_valve(self, Vector2(220, 210))
	LevelCommon.add_valve(self, Vector2(980, 200))

	# Windows and furniture for readability.
	LevelCommon.add_window(self, 180, 220, 50, 70, true)
	LevelCommon.add_window(self, 520, 220, 50, 70, false)
	LevelCommon.add_window(self, 1400, 210, 56, 74, true)
	LevelCommon.add_window(self, 2100, 210, 50, 70, false)
	LevelCommon.add_bench(self, Vector2(300, 500))
	LevelCommon.add_crate_prop(self, Vector2(600, 492), Vector2(40, 32))
	LevelCommon.add_crate_prop(self, Vector2(640, 492), Vector2(28, 24))
	LevelCommon.add_steam_vent(self, Vector2(860, 500))
	LevelCommon.add_steam_vent(self, Vector2(2000, 500))

	_build_room_triggers()
	_build_crate_room()
	_build_chest_room()
	_build_hatch_room()
	_build_ambient_lamps()

	var spawn := Vector2(120, 480)
	if GameState.checkpoint_position != Vector2.ZERO and GameState.current_zone_id == "cursed_cottage":
		spawn = GameState.checkpoint_position
	LevelCommon.spawn_player(self, spawn)
	GameState.enter_room("cursed_cottage", "hall")


func _build_room_triggers() -> void:
	LevelCommon.make_room_trigger(self, Vector2(350, 360), Vector2(700, 400), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1050, 360), Vector2(700, 400), "cursed_cottage", "crate", "Walk into the crate to push it", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(1750, 360), Vector2(700, 400), "cursed_cottage", "chest", "Jump over what will not move", "jump")
	LevelCommon.make_room_trigger(self, Vector2(2450, 360), Vector2(700, 400), "cursed_cottage", "hatch", "Aim with W/S, press F to break the hatch", "attack")


func _build_crate_room() -> void:
	var box := PushableBox.new()
	box.moveable = true
	box.position = Vector2(1100, 476)
	box.box_size = Vector2(48, 48)
	add_child(box)
	var lamp := LightSource.new()
	lamp.position = Vector2(980, 300)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 280.0
	lamp.shadow_length = 360.0
	lamp.pushable = true
	add_child(lamp)
	LevelCommon.add_crate_prop(self, Vector2(1200, 492))


func _build_chest_room() -> void:
	var chest := PushableBox.new()
	chest.moveable = false
	chest.position = Vector2(1750, 460)
	chest.box_size = Vector2(64, 64)
	add_child(chest)
	LevelCommon.add_steel_floor(self, 1680, 500, 40, 20)
	LevelCommon.add_pipe(self, Vector2(1600, 400), Vector2(1900, 400), 8.0)


func _build_hatch_room() -> void:
	var door := BreakableDoor.new()
	door.position = Vector2(2550, 448)
	door.door_size = Vector2(24, 80)
	door.next_scene = "res://scenes/rooms/LanternVillage.tscn"
	add_child(door)
	var cp := Checkpoint.new()
	cp.position = Vector2(2300, 500)
	cp.checkpoint_id = "cottage_hatch"
	add_child(cp)
	LevelCommon.add_crate_prop(self, Vector2(2420, 492), Vector2(32, 28))


func _build_ambient_lamps() -> void:
	var moon := LightSource.new()
	moon.position = Vector2(400, 120)
	moon.light_kind = GameState.LightKind.MOON
	moon.radius = 160.0
	moon.shadow_length = 200.0
	moon.pushable = false
	add_child(moon)
