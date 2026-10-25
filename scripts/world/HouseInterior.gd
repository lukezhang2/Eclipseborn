extends Node2D
## Playable interior zone for a village house — desk + shopkeeper behind it.
## Shopkeeper defaults: HouseProfiles. Overrides: LevelData / editor save for npc_shop.


const FLOOR_Y := 500.0
const MAP_W := 720.0

var house_id: String = "house_keep"
var house_title: String = "Shop"
var keeper_name: String = "Keeper"
var keeper_lines: PackedStringArray = PackedStringArray([])
var keeper_shop_items: Array = []
var return_spawn: Vector2 = Vector2(520, 460)
var _npc_id: String = "npc_shop"

## Per-shop look: WorldArt INTERIOR / DESK / SIGN styles.
const SHOP_LOOK := {
	"house_keep": {"interior": 0, "desk": 2, "sign": 0},
	"house_gear": {"interior": 3, "desk": 2, "sign": 0},
	"house_inn": {"interior": 7, "desk": 2, "sign": 0},
}


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
	LevelCommon.add_backdrop(
		self, MAP_W, 720, FLOOR_Y, 160.0, true, LevelData.backdrop_for(GameState.current_zone_id)
	)
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
	keeper_shop_items = ShopCatalog.normalize_shop_items(profile.get("shop_items", ShopCatalog.default_shop_stock()))
	## Editor / LevelData overrides for this shopkeeper.
	var saved := LevelData.merged_piece(house_id, _npc_id)
	if not saved.is_empty():
		if saved.has("lines"):
			keeper_lines = HouseProfiles.lines_to_packed(saved.get("lines"))
		if saved.has("name") and str(saved.get("name", "")) != "":
			keeper_name = str(saved.get("name"))
		if saved.has("shop_items"):
			keeper_shop_items = ShopCatalog.normalize_shop_items(saved.get("shop_items"))
		elif bool(saved.get("is_shopkeeper", true)) and keeper_shop_items.is_empty():
			keeper_shop_items = ShopCatalog.default_shop_stock()


func _look() -> Dictionary:
	var look: Dictionary = SHOP_LOOK.get(house_id, {"interior": 0, "desk": 0, "sign": 0}).duplicate()
	## Review tool only: GameState meta "preview_shop_look" overrides SHOP_LOOK.
	if GameState.has_meta("preview_shop_look"):
		look.merge(GameState.get_meta("preview_shop_look"), true)
	return look


func _build_room() -> void:
	# Themed back wall (shelves, gears, bar...) matching what the shop is.
	var wall := WorldArt.new()
	wall.kind = WorldArt.Kind.INTERIOR
	wall.style = int(_look()["interior"])
	wall.size = Vector2(MAP_W - 160, FLOOR_Y - 200)
	wall.position = Vector2(MAP_W * 0.5, FLOOR_Y)
	wall.z_index = -8
	add_child(wall)
	_build_title_sign()
	# Dim safe moon lamp in the corner (shop is mostly shade).
	var lamp := LightSource.new()
	lamp.position = Vector2(MAP_W - 100, 260)
	lamp.light_kind = GameState.LightKind.MOON
	lamp.radius = 140.0
	lamp.pushable = false
	lamp.show_radius_ring = true
	add_child(lamp)


func _build_desk_and_keeper() -> void:
	# Walk-through counter (no collision). Draw order: keeper (-2) behind the counter (-1),
	# and the player (0) passes in front of it.
	var desk := Node2D.new()
	desk.position = Vector2(MAP_W * 0.5, FLOOR_Y)
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.DESK
	art.style = int(_look()["desk"])
	art.size = Vector2(200, 26)
	desk.add_child(art)
	desk.z_index = -1
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
	# Standing behind the low counter: visible from the waist up.
	npc_pos.y = FLOOR_Y - 4
	npc.position = npc_pos
	npc.npc_name = keeper_name
	npc.lines = keeper_lines
	npc.is_shopkeeper = true
	## Respect empty stock from the editor (all sales off).
	npc.shop_items = keeper_shop_items
	npc.shop_key = "%s/%s" % [house_id, _npc_id]
	npc.z_index = -2
	LevelData.tag(npc, _npc_id)
	add_child(npc)


## Shop name on a sign hanging from the ceiling, in the steampunk display face.
func _build_title_sign() -> void:
	var title := Label.new()
	title.text = house_title
	title.add_theme_font_override("font", load(UITheme.TITLE_FONT))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("2a1a0e") if int(_look()["sign"]) != 2 else UITheme.BRASS_LIGHT)
	title.add_theme_color_override("font_outline_color", Color(1, 0.9, 0.7, 0.35) if int(_look()["sign"]) != 2 else UITheme.COAL)
	title.add_theme_constant_override("outline_size", 2)
	add_child(title)
	title.reset_size()  # Measure after it is in the tree so the steampunk font is used.
	var sign := WorldArt.new()
	sign.kind = WorldArt.Kind.SIGN
	sign.style = int(_look()["sign"])
	sign.size = Vector2(title.size.x + 48, title.size.y + 10)
	sign.position = Vector2(MAP_W * 0.5, 198)
	add_child(sign)
	title.position = Vector2(MAP_W * 0.5 - title.size.x * 0.5, 198 + 22 + 5)
	move_child(title, -1)


func _build_exit() -> void:
	## Exit is always on the LEFT wall (street door) — clear of the border pillar.
	if LevelData.is_removed(house_id, "exit_door"):
		return
	var door := HouseExitDoor.new()
	door.position = Vector2(88, FLOOR_Y)
	door.name = "ExitDoor"
	door.z_index = 3
	door.target_zone = "lantern_village"
	door.spawn_pos = return_spawn
	door.travel_caption = "Back to the street…"
	var saved := LevelData.merged_piece(house_id, "exit_door")
	if not saved.is_empty():
		if saved.has("x") and saved.has("y"):
			door.position = Vector2(float(saved.get("x")), float(saved.get("y")))
		if saved.has("target_zone") and str(saved.get("target_zone", "")) != "":
			door.target_zone = str(saved.get("target_zone"))
		if saved.has("spawn_x") or saved.has("spawn_y"):
			door.spawn_pos = Vector2(
				float(saved.get("spawn_x", door.spawn_pos.x)),
				float(saved.get("spawn_y", door.spawn_pos.y))
			)
		if saved.has("caption") and str(saved.get("caption", "")) != "":
			door.travel_caption = str(saved.get("caption"))
	LevelData.tag(door, "exit_door")
	add_child(door)
