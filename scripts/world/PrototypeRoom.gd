extends Node2D
## Phase 0 playground: lamp + moveable + immoveable box, walkable shadows, shade/health.


func _ready() -> void:
	GameState.current_zone_id = "prototype"
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, 1600, 720)

	LevelCommon.add_steel_floor(self, 300, 520, 600, 40)
	LevelCommon.add_steel_floor(self, 1200, 520, 600, 40)
	LevelCommon.add_wall(self, -20, 300, 40, 480)
	LevelCommon.add_wall(self, 1580, 300, 40, 480)

	var lamp := LightSource.new()
	lamp.position = Vector2(500, 200)
	lamp.light_kind = GameState.LightKind.HEARTH
	lamp.radius = 480.0
	lamp.shadow_length = 600.0
	add_child(lamp)

	var moveable := PushableBox.new()
	moveable.moveable = true
	moveable.position = Vector2(520, 476)
	add_child(moveable)

	var immoveable := PushableBox.new()
	immoveable.moveable = false
	immoveable.position = Vector2(280, 460)
	immoveable.box_size = Vector2(64, 64)
	add_child(immoveable)

	# Extra light types for testing (Phase 1).
	var candle := LightSource.new()
	candle.position = Vector2(900, 400)
	candle.light_kind = GameState.LightKind.CANDLE
	candle.radius = 140.0
	candle.shadow_length = 180.0
	candle.pushable = false
	add_child(candle)

	var moon := LightSource.new()
	moon.position = Vector2(1100, 160)
	moon.light_kind = GameState.LightKind.MOON
	moon.radius = 200.0
	moon.shadow_length = 220.0
	moon.pushable = false
	add_child(moon)

	LevelCommon.make_room_trigger(self, Vector2(800, 360), Vector2(1400, 500), "prototype", "puzzle", "Prototype — push boxes and lamps", "")
	var cp := Checkpoint.new()
	cp.position = Vector2(120, 500)
	add_child(cp)

	LevelCommon.spawn_player(self, Vector2(100, 480))
	GameState.enter_room("prototype", "puzzle")
