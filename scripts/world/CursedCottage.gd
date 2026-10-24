extends Node2D
## Four-room tutorial: hall → push crate → jump chest → break hatch → Lantern Village.


func _ready() -> void:
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, 3200, 720)

	# Continuous boiler-house floor across all four rooms.
	LevelCommon.add_steel_floor(self, 1600, 520, 3200, 40)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_pipe(self, Vector2(40, 80), Vector2(3000, 80))
	LevelCommon.add_pipe(self, Vector2(200, 80), Vector2(200, 200))
	LevelCommon.add_pipe(self, Vector2(900, 80), Vector2(900, 180))
	LevelCommon.add_pipe(self, Vector2(1700, 80), Vector2(1700, 200))

	# Ceiling strip
	LevelCommon.add_wall(self, 1600, 40, 3200, 40)

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
	# Room widths ~700px each.
	LevelCommon.make_room_trigger(self, Vector2(350, 360), Vector2(700, 400), "cursed_cottage", "hall", "Walk and hold Shift to run", "run")
	LevelCommon.make_room_trigger(self, Vector2(1050, 360), Vector2(700, 400), "cursed_cottage", "crate", "Walk into the crate to push it", "move_right")
	LevelCommon.make_room_trigger(self, Vector2(1750, 360), Vector2(700, 400), "cursed_cottage", "chest", "Jump over what will not move", "jump")
	LevelCommon.make_room_trigger(self, Vector2(2450, 360), Vector2(700, 400), "cursed_cottage", "hatch", "Press F to break the iron hatch", "attack")


func _build_crate_room() -> void:
	var box := PushableBox.new()
	box.moveable = true
	box.position = Vector2(1100, 476)
	box.box_size = Vector2(48, 48)
	add_child(box)
	# Soft hearth lamp so the crate casts a visible shadow (safe-ish far left).
	var lamp := LightSource.new()
	lamp.position = Vector2(980, 300)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 280.0
	lamp.shadow_length = 360.0
	lamp.pushable = true
	add_child(lamp)


func _build_chest_room() -> void:
	var chest := PushableBox.new()
	chest.moveable = false
	chest.position = Vector2(1750, 460)
	chest.box_size = Vector2(64, 64)
	add_child(chest)
	# Small step so jump reads clearly if needed.
	LevelCommon.add_steel_floor(self, 1680, 500, 40, 20)


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


func _build_ambient_lamps() -> void:
	# Dim moon leak through a broken roof — safe light, refills shade.
	var moon := LightSource.new()
	moon.position = Vector2(400, 120)
	moon.light_kind = GameState.LightKind.MOON
	moon.radius = 160.0
	moon.shadow_length = 200.0
	moon.pushable = false
	add_child(moon)
