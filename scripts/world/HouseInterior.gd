extends Node2D
## Playable interior zone for a village house — desk + shopkeeper behind it.
## Dialogue defaults: HouseProfiles. Overrides: LevelData / editor save for npc_shop.


const FLOOR_Y := 500.0
const MAP_W := 720.0

var house_id: String = "house_keep"
var house_title: String = "Shop"
var keeper_name: String = "Keeper"
var keeper_lines: PackedStringArray = PackedStringArray([])
var return_spawn: Vector2 = Vector2(520, 460)
var _npc_id: String = "npc_shop"


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
	LevelData.apply(self, house_id)
	LevelData.prune_removed(self, house_id)

	## Spawn near the left exit, clear of the walk pad so we don't bounce out.
	var spawn := Vector2(160, FLOOR_Y - 40)
	if GameState.pending_spawn != Vector2.ZERO:
		spawn = Vector2(clampf(GameState.pending_spawn.x, 140.0, MAP_W - 80.0), FLOOR_Y - 40)
		GameState.pending_spawn = Vector2.ZERO
	GameState.lock_interact(0.9)
	var player := LevelCommon.spawn_player(self, spawn)
	LevelCommon.configure_camera(player, 160.0, FLOOR_Y + 60.0, GameState.map_min_x, GameState.map_max_x)
	GameState.enter_room(house_id, "interior")


func _apply_house_profile() -> void:
	var profile := HouseProfiles.get_profile(house_id)
	house_title = str(profile.get("title", "Shop"))
	keeper_name = str(profile.get("keeper_name", "Keeper"))
	return_spawn = profile.get("return_spawn", Vector2(520, 460))
	_npc_id = str(profile.get("npc_id", "npc_shop"))
	keeper_lines = HouseProfiles.lines_to_packed(profile.get("lines", []))
	## Editor / LevelData overrides for this shopkeeper.
	var saved := LevelData.merged_piece(house_id, _npc_id)
	if not saved.is_empty():
		if saved.has("lines"):
			keeper_lines = HouseProfiles.lines_to_packed(saved.get("lines"))
		if saved.has("name") and str(saved.get("name", "")) != "":
			keeper_name = str(saved.get("name"))


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

	if LevelData.is_removed(house_id, _npc_id):
		return
	var npc := NPC.new()
	# Behind the desk (deeper into the room than the desk face).
	var profile := HouseProfiles.get_profile(house_id)
	var npc_pos := Vector2(MAP_W * 0.5, float(profile.get("npc_y", FLOOR_Y - 40)))
	var saved := LevelData.merged_piece(house_id, _npc_id)
	if saved.has("x"):
		npc_pos.x = float(saved.get("x"))
	if saved.has("y"):
		npc_pos.y = float(saved.get("y"))
	npc.position = npc_pos
	npc.npc_name = keeper_name
	npc.lines = keeper_lines
	npc.z_index = -1
	LevelData.tag(npc, _npc_id)
	add_child(npc)


func _build_exit() -> void:
	## Exit is always on the LEFT wall (street door) — clear of the border pillar.
	var door := HouseExitDoor.new()
	door.position = Vector2(88, FLOOR_Y)
	door.name = "ExitDoor"
	door.z_index = 3
	add_child(door)
