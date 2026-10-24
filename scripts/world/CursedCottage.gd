extends Node2D
## Five-room boiler-house tutorial: run, push, pull (V), jump, break hatch.


func _ready() -> void:
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, 4000, 720)

	LevelCommon.add_steel_floor(self, 2000, 520, 4000, 40)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_wall(self, 2000, 40, 4000, 40)

	for i in 5:
		LevelCommon.add_brick_wall_face(self, 400 + i * 750, 280, 750, 360)

	LevelCommon.add_pipe(self, Vector2(40, 90), Vector2(3900, 90), 14.0)
	LevelCommon.add_pipe(self, Vector2(220, 90), Vector2(220, 210), 10.0)
	LevelCommon.add_pipe(self, Vector2(980, 90), Vector2(980, 200), 10.0)
	LevelCommon.add_pipe(self, Vector2(1750, 90), Vector2(1750, 220), 10.0)
	LevelCommon.add_pipe(self, Vector2(2500, 90), Vector2(2500, 200), 10.0)
	LevelCommon.add_pipe(self, Vector2(3200, 90), Vector2(3200, 210), 10.0)
	LevelCommon.add_valve(self, Vector2(220, 210))
	LevelCommon.add_valve(self, Vector2(1750, 220))

	LevelCommon.add_window(self, 180, 220, 50, 70, true)
	LevelCommon.add_window(self, 520, 220, 50, 70, false)
	LevelCommon.add_window(self, 1400, 210, 56, 74, true)
	LevelCommon.add_window(self, 2200, 210, 50, 70, false)
	LevelCommon.add_window(self, 3000, 210, 50, 70, true)
	LevelCommon.add_bench(self, Vector2(300, 500))
	LevelCommon.add_crate_prop(self, Vector2(600, 492), Vector2(40, 32))
	LevelCommon.add_steam_vent(self, Vector2(860, 500))
	LevelCommon.add_steam_vent(self, Vector2(2600, 500))

	_build_room_triggers()
	_build_crate_room()
	_build_pull_room()
	_build_chest_room()
	_build_hatch_room()
	_build_ambient_lamps()

	var spawn := Vector2(120, 480)
	if GameState.checkpoint_position != Vector2.ZERO and GameState.current_zone_id == "cursed_cottage" and not GameState.needs_intro_cutscene:
		spawn = GameState.checkpoint_position
	LevelCommon.spawn_player(self, spawn)
	GameState.enter_room("cursed_cottage", "hall")


func _build_room_triggers() -> void:
	LevelCommon.make_room_trigger(self, Vector2(350, 360), Vector2(700, 400), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1100, 360), Vector2(700, 400), "cursed_cottage", "crate", "Walk into the crate to push it", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(1850, 360), Vector2(700, 400), "cursed_cottage", "pull", "Hold V and walk to pull the crate out", "pull")
	LevelCommon.make_room_trigger(self, Vector2(2600, 360), Vector2(700, 400), "cursed_cottage", "chest", "Jump over what will not move", "jump")
	LevelCommon.make_room_trigger(self, Vector2(3350, 360), Vector2(700, 400), "cursed_cottage", "hatch", "Aim with W/Down, crouch with S, F to break", "attack")


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


func _build_pull_room() -> void:
	## Crate seated in a wall recess — cannot push forward (blocked), must pull back with V.
	LevelCommon.add_wall(self, 1980, 430, 40, 140)  # blocks pushing further right into alcove
	var alcove_floor := LevelCommon.add_steel_floor(self, 1920, 500, 120, 20)
	alcove_floor.modulate = Color(0.9, 0.85, 0.7)
	var box := PushableBox.new()
	box.moveable = true
	box.position = Vector2(1900, 476)
	box.box_size = Vector2(48, 48)
	box.name = "PullCrate"
	add_child(box)
	# Narrow doorway feel: walls leave a gap that the pulled crate must clear.
	LevelCommon.add_wall(self, 2050, 360, 30, 100)
	LevelCommon.add_crate_prop(self, Vector2(1700, 492))


func _build_chest_room() -> void:
	var chest := PushableBox.new()
	chest.moveable = false
	chest.position = Vector2(2600, 460)
	chest.box_size = Vector2(64, 64)
	add_child(chest)
	LevelCommon.add_steel_floor(self, 2530, 500, 40, 20)
	LevelCommon.add_pipe(self, Vector2(2450, 400), Vector2(2750, 400), 8.0)


func _build_hatch_room() -> void:
	var door := BreakableDoor.new()
	door.position = Vector2(3450, 448)
	door.door_size = Vector2(24, 80)
	door.next_scene = "res://scenes/rooms/LanternVillage.tscn"
	add_child(door)
	var cp := Checkpoint.new()
	cp.position = Vector2(3200, 500)
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
