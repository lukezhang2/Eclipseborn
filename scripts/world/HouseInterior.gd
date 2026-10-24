extends Node2D
## Playable interior zone for a village house — desk + shopkeeper behind it.


const FLOOR_Y := 500.0
const MAP_W := 720.0

var house_id: String = "house_keep"
var house_title: String = "Shop"
var keeper_name: String = "Keeper"
var keeper_lines: PackedStringArray = PackedStringArray([])
var return_spawn: Vector2 = Vector2(520, 460)


func _ready() -> void:
	if GameState.has_meta("pending_house_id"):
		house_id = str(GameState.get_meta("pending_house_id"))
		GameState.remove_meta("pending_house_id")
	_apply_house_profile()
	GameState.current_zone_id = house_id
	GameState.map_min_x = 40.0
	GameState.map_max_x = MAP_W - 40.0
	LevelCommon.spawn_ui(self)
	LevelCommon.make_shadow_root(self)
	LevelCommon.add_backdrop(self, MAP_W, 720, FLOOR_Y, 160.0)
	LevelCommon.add_underfloor_fill(self, MAP_W, FLOOR_Y + 20.0)
	LevelCommon.add_cobble_floor(self, MAP_W * 0.5, FLOOR_Y + 20.0, MAP_W, 40.0)
	LevelCommon.add_border_walls(self, MAP_W, FLOOR_Y, 160.0)
	LevelCommon.add_wall(self, MAP_W * 0.5, 180.0, MAP_W, 36.0)

	_build_room()
	_build_desk_and_keeper()
	_build_exit()

	var spawn := Vector2(120, FLOOR_Y - 40)
	if GameState.pending_spawn != Vector2.ZERO:
		spawn = Vector2(GameState.pending_spawn.x, FLOOR_Y - 40)
		GameState.pending_spawn = Vector2.ZERO
	var player := LevelCommon.spawn_player(self, spawn)
	LevelCommon.configure_camera(player, 160.0, FLOOR_Y + 60.0, GameState.map_min_x, GameState.map_max_x)
	GameState.enter_room(house_id, "interior")


func _apply_house_profile() -> void:
	match house_id:
		"house_gear":
			house_title = "Gearwright"
			keeper_name = "Gearwright"
			return_spawn = Vector2(980, 460)
			keeper_lines = PackedStringArray([
				"You're the only shade-walker left. The rest of us live in the light fine.",
				"That umbra hunger of yours — it's not natural, traveler.",
				"I can fit gears. I can't fit whatever made you burn in daylight.",
			])
		"house_inn":
			house_title = "Shade Inn"
			keeper_name = "Innkeep"
			return_spawn = Vector2(1780, 460)
			keeper_lines = PackedStringArray([
				"Most guests sit by the hearth. You… flinch from it.",
				"You're the odd one — shade-bound while we walk the lantern streets.",
				"Room's in the dark wing. Figured you'd prefer it that way.",
			])
		_:
			house_title = "Lantern Keep"
			keeper_name = "Keeper"
			return_spawn = Vector2(520, 460)
			keeper_lines = PackedStringArray([
				"Everyone else thrives under lanterns. You alone need the dark.",
				"Spirit, you're marked — the shade clings to you like a second skin.",
				"We tend lamps. You flee them. That makes you the stranger here.",
			])


func _build_room() -> void:
	# Back wall shelves
	var shelf := Polygon2D.new()
	shelf.color = Color(0.2, 0.16, 0.14)
	shelf.polygon = PackedVector2Array([
		Vector2(80, FLOOR_Y - 40), Vector2(MAP_W - 80, FLOOR_Y - 40),
		Vector2(MAP_W - 80, FLOOR_Y - 200), Vector2(80, FLOOR_Y - 200)
	])
	shelf.z_index = -8
	add_child(shelf)
	var title := Label.new()
	title.text = house_title
	title.position = Vector2(MAP_W * 0.5 - 80, 200)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	add_child(title)
	# Dim safe moon lamp in the corner (shop is mostly shade).
	var lamp := LightSource.new()
	lamp.position = Vector2(MAP_W - 100, 260)
	lamp.light_kind = GameState.LightKind.MOON
	lamp.radius = 140.0
	lamp.pushable = false
	lamp.show_radius_ring = true
	add_child(lamp)


func _build_desk_and_keeper() -> void:
	# Desk blocks the mid floor — keeper stands BEHIND it (further from door = higher Y negative / left-right center).
	var desk := StaticBody2D.new()
	desk.position = Vector2(MAP_W * 0.5, FLOOR_Y - 8)
	desk.collision_layer = 1
	var dcs := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(200, 28)
	dcs.shape = drect
	dcs.position = Vector2(0, -14)
	desk.add_child(dcs)
	var top := Polygon2D.new()
	top.color = Color(0.32, 0.24, 0.16)
	top.polygon = PackedVector2Array([
		Vector2(-100, 0), Vector2(100, 0), Vector2(100, -28), Vector2(-100, -28)
	])
	desk.add_child(top)
	var front := Polygon2D.new()
	front.color = Color(0.22, 0.16, 0.12)
	front.polygon = PackedVector2Array([
		Vector2(-96, 0), Vector2(96, 0), Vector2(90, 18), Vector2(-90, 18)
	])
	desk.add_child(front)
	add_child(desk)

	var npc := NPC.new()
	# Behind the desk (deeper into the room than the desk face).
	npc.position = Vector2(MAP_W * 0.5, FLOOR_Y - 40)
	npc.npc_name = keeper_name
	npc.lines = keeper_lines
	npc.z_index = -1
	add_child(npc)


func _build_exit() -> void:
	var door := Area2D.new()
	door.position = Vector2(80, FLOOR_Y)
	door.collision_layer = 0
	door.collision_mask = 2
	door.monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 50)
	cs.shape = rect
	cs.position = Vector2(0, -25)
	door.add_child(cs)
	var visual := Polygon2D.new()
	visual.color = Color(0.1, 0.08, 0.07)
	visual.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(14, -40), Vector2(-14, -40)
	])
	door.add_child(visual)
	var prompt := Label.new()
	prompt.name = "ExitPrompt"
	prompt.text = "F — Leave"
	prompt.position = Vector2(-36, -58)
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7))
	prompt.visible = false
	door.add_child(prompt)
	door.set_meta("prompt", prompt)
	door.set_meta("exit", true)
	add_child(door)
	door.set_script(load("res://scripts/world/HouseExitDoor.gd"))
