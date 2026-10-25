extends Node
## Level overlay I/O + spawning.
##
## AI / human entry point for the level format:
##   docs/LEVEL_EDITOR.md
##   scripts/editor/PieceSpecs.gd   (sizes + anchors)
##   scripts/editor/ZoneCatalog.gd  (builtin seeds)
##   data/levels/<zone>.json        (repo overlays)
##
## Runtime load order: room script builds builtins → apply() adds non-builtins
## → prune_removed() deletes catalog ids listed in removed_ids.
## Editor "Copy Save Code" exports the full JSON schema (schema: 1).


const USER_DIR := "user://editor/"
const RES_DIR := "res://data/levels/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(USER_DIR)


static func path_for(zone_id: String, prefer_user: bool = true) -> String:
	var user_path := USER_DIR + zone_id + ".json"
	var res_path := RES_DIR + zone_id + ".json"
	if prefer_user and FileAccess.file_exists(user_path):
		return user_path
	if FileAccess.file_exists(res_path):
		return res_path
	return user_path


static func load_raw(zone_id: String) -> Dictionary:
	var path := path_for(zone_id)
	if not FileAccess.file_exists(path):
		return {"schema": PieceSpecs.SCHEMA_VERSION, "zone": zone_id, "pieces": [], "removed_ids": []}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"schema": PieceSpecs.SCHEMA_VERSION, "zone": zone_id, "pieces": [], "removed_ids": []}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"schema": PieceSpecs.SCHEMA_VERSION, "zone": zone_id, "pieces": [], "removed_ids": []}
	return parsed


## Standard void #0d020f (r,g,b in 0–1).
const VOID_PURPLE := [13.0 / 255.0, 2.0 / 255.0, 15.0 / 255.0, 1.0]


static func default_backdrop(zone_id: String) -> Dictionary:
	## Universal standard: #0d020f void + top black-fire fringe.
	## Zones may cover it with brick/city art; JSON can override or disable.
	var base := {
		"kind": "black_fire",
		"enabled": true,
		"flame_band_offset": 12.0,
		"flame_count": 48,
		"void_color": VOID_PURPLE.duplicate(),
	}
	match zone_id:
		"cursed_cottage", "house_keep", "house_gear", "house_inn":
			base["flame_band_offset"] = 22.0
			base["flame_count"] = 40
		"clockwork_tower":
			base["flame_band_offset"] = 16.0
			base["flame_count"] = 36
		_:
			pass
	return base


static func backdrop_for(zone_id: String) -> Dictionary:
	var base := default_backdrop(zone_id)
	var data := load_raw(zone_id)
	var saved: Variant = data.get("backdrop", {})
	if typeof(saved) != TYPE_DICTIONARY or (saved as Dictionary).is_empty():
		return base
	var out := base.duplicate(true)
	for key in (saved as Dictionary).keys():
		out[key] = saved[key]
	return out


static func save_raw(zone_id: String, data: Dictionary, to_res: bool = false) -> Error:
	if not data.has("schema"):
		data["schema"] = PieceSpecs.SCHEMA_VERSION
	var path := (RES_DIR if to_res else USER_DIR) + zone_id + ".json"
	if to_res:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RES_DIR))
	else:
		DirAccess.make_dir_recursive_absolute(USER_DIR)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_CREATE
	f.store_string(JSON.stringify(data, "\t"))
	return OK


static func is_removed(zone_id: String, catalog_id: String) -> bool:
	if catalog_id == "":
		return false
	var data := load_raw(zone_id)
	var removed: Array = data.get("removed_ids", [])
	return removed.has(catalog_id)


static func tag(node: Node, catalog_id: String) -> void:
	if node:
		node.set_meta("catalog_id", catalog_id)


static func prune_removed(parent: Node, zone_id: String) -> void:
	var data := load_raw(zone_id)
	var removed: Array = data.get("removed_ids", [])
	if removed.is_empty():
		return
	for child in parent.get_children():
		if child.has_meta("catalog_id") and removed.has(str(child.get_meta("catalog_id"))):
			child.queue_free()


static func merged_piece(zone_id: String, piece_id: String) -> Dictionary:
	## Catalog seed + saved overlay fields (used for NPC dialogue, positions, etc.).
	if piece_id == "":
		return {}
	var base := {}
	for cat in ZoneCatalog.pieces_for(zone_id):
		if str(cat.get("id", "")) == piece_id:
			base = cat.duplicate(true)
			break
	var data := load_raw(zone_id)
	if data.get("removed_ids", []).has(piece_id):
		return {}
	for raw in data.get("pieces", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if str(raw.get("id", "")) != piece_id:
			continue
		if base.is_empty():
			base = raw.duplicate(true)
		else:
			for key in raw.keys():
				base[key] = raw[key]
		break
	return base


static func apply(parent: Node2D, zone_id: String) -> void:
	var data := load_raw(zone_id)
	var pieces: Array = data.get("pieces", [])
	for p in pieces:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		if bool(p.get("builtin", false)):
			continue  # builtins are spawned by the room script
		var id := str(p.get("id", ""))
		if id != "" and data.get("removed_ids", []).has(id):
			continue
		_spawn_piece(parent, p)
	prune_removed(parent, zone_id)


static func _piece_tint(p: Dictionary) -> Color:
	if p.has("color"):
		return Color.html(str(p.get("color", "#ffffff")))
	return Color.WHITE


static func _apply_tint(node: Node, tint: Color) -> void:
	if node == null or not is_instance_valid(node):
		return
	if tint == Color.WHITE:
		return
	if node is CanvasItem:
		var ci := node as CanvasItem
		## Preserve existing alpha (backgrounds use translucent modulate).
		ci.modulate = Color(tint.r, tint.g, tint.b, ci.modulate.a)


static func _spawn_piece(parent: Node2D, p: Dictionary) -> void:
	var kind: String = str(p.get("kind", "block"))
	var pos := Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
	var size := Vector2(float(p.get("w", 48)), float(p.get("h", 48)))
	var tint := _piece_tint(p)
	match kind:
		"background":
			var bg := LevelCommon.add_brick_wall_face(parent, pos.x, pos.y, size.x, size.y)
			_apply_tint(bg, tint)
		"block", "floor":
			var fl := LevelCommon.add_steel_floor(parent, pos.x, pos.y, size.x, maxf(size.y, 16.0))
			_apply_tint(fl, tint)
		"wall":
			var wl := LevelCommon.add_wall(parent, pos.x, pos.y, size.x, size.y)
			_apply_tint(wl, tint)
		"crate":
			var box := PushableBox.new()
			## Set size before enter tree so _ready/_build uses the editor size.
			if size.x < 50.0 or size.y < 50.0:
				size = PieceSpecs.CRATE_COTTAGE
			box.box_size = size
			box.position = pos
			parent.add_child(box)
			_apply_tint(box, tint)
			LevelData.tag(box, str(p.get("id", "")))
		"light":
			var lamp := LightSource.new()
			lamp.position = pos
			lamp.light_kind = int(p.get("light_kind", GameState.LightKind.HEARTH)) as GameState.LightKind
			lamp.pushable = bool(p.get("pushable", true))
			parent.add_child(lamp)
			lamp.set_radius(float(p.get("radius", 280.0)))
			if p.has("intensity"):
				lamp.set_intensity(float(p.get("intensity", 1.0)))
			LevelData.tag(lamp, str(p.get("id", "")))
			if str(p.get("id", "")) != "":
				lamp.name = str(p.get("id"))
		"prop_bench":
			LevelCommon.add_bench(parent, pos)
		"prop_vent":
			LevelCommon.add_steam_vent(parent, pos)
		"prop_ladder":
			var lad := LevelCommon.add_ladder(parent, pos, maxf(size.y, 40.0), maxf(size.x, 20.0))
			LevelData.tag(lad, str(p.get("id", "")))
		"prop_window":
			LevelCommon.add_window(parent, pos.x, pos.y, size.x, size.y, false)
		"prop_bg_gear":
			var gear := LevelCommon.add_bg_gear(
				parent, pos, maxf(size.x, size.y) * 0.5, float(p.get("spin_speed", 8.0))
			)
			LevelData.tag(gear, str(p.get("id", "")))
		"prop_platform":
			var cfg := {
				"move_amplitude": float(p.get("move_amplitude", p.get("amplitude", 90.0))),
				"move_speed": float(p.get("move_speed", p.get("speed", 0.65))),
				"vertical": bool(p.get("vertical", false)),
				"path_y_amplitude": float(p.get("path_y_amplitude", 0.0)),
				"rotate_while_moving": bool(p.get("rotate_while_moving", p.get("rotate", true))),
				"rotate_speed": float(p.get("rotate_speed", 1.0)),
				"rotate_platform": bool(p.get("rotate_platform", false)),
				"rotation": float(p.get("rotation", 0.0)),
				"with_gear": bool(p.get("with_gear", true)),
				"gear_dx": float(p.get("gear_dx", -90.0)),
				"gear_dy": float(p.get("gear_dy", -80.0)),
				"gear_radius": float(p.get("gear_radius", 55.0)),
			}
			var plat := LevelCommon.add_moving_platform(parent, pos, size, cfg)
			_apply_tint(plat, tint)
			LevelData.tag(plat, str(p.get("id", "")))
		"prop_crate":
			var crate_n := LevelCommon.add_crate_prop(parent, pos, size)
			_apply_tint(crate_n, tint)
		"prop_checkpoint":
			var cp := Checkpoint.new()
			cp.position = pos
			cp.checkpoint_id = str(p.get("id", "editor_cp"))
			cp.checkpoint_name = str(p.get("name", cp.checkpoint_id))
			parent.add_child(cp)
			LevelData.tag(cp, str(p.get("id", "")))
		"prop_switch":
			var sw := LightSwitch.new()
			sw.position = pos
			sw.starts_on = bool(p.get("starts_on", true))
			var tids: PackedStringArray = PackedStringArray()
			for t in p.get("target_ids", []):
				tids.append(str(t))
			sw.target_ids = tids
			parent.add_child(sw)
			LevelData.tag(sw, str(p.get("id", "")))
		"prop_door":
			var door := SwitchDoor.new()
			door.position = pos
			door.door_id = str(p.get("id", "door"))
			door.width = maxf(size.x, 20.0)
			door.height = maxf(size.y, 64.0)
			door.starts_open = bool(p.get("starts_open", false))
			parent.add_child(door)
			LevelData.tag(door, str(p.get("id", "")))
		"prop_npc":
			var npc := NPC.new()
			npc.position = pos
			npc.npc_name = str(p.get("name", "Villager"))
			npc.lines = HouseProfiles.lines_to_packed(p.get("lines", ["…"]))
			npc.is_shopkeeper = bool(p.get("is_shopkeeper", true))
			## Empty shop_items = nothing for sale.
			npc.shop_items = ShopCatalog.normalize_shop_items(p.get("shop_items", []))
			var nid := str(p.get("id", ""))
			npc.shop_key = "%s/%s" % [GameState.current_zone_id, nid if nid != "" else npc.npc_name]
			parent.add_child(npc)
			LevelData.tag(npc, nid)
		"prop_text":
			var col := Color("c4b07a")
			if p.has("color"):
				col = Color.html(str(p.get("color", "#c4b07a")))
			var lbl := LevelCommon.add_world_label(
				parent,
				pos,
				str(p.get("text", p.get("name", "Text"))),
				clampi(int(p.get("font_size", 14)), 8, 72),
				col,
				size
			)
			LevelData.tag(lbl, str(p.get("id", "")))
		"prop_pickup":
			var pid := str(p.get("id", "shadow_crystal"))
			if GameState.is_collected(pid):
				return
			var crystal := ShadowCrystal.new()
			crystal.position = pos
			crystal.pickup_id = pid
			crystal.display_name = str(p.get("name", "Shadow Crystal Fragment"))
			parent.add_child(crystal)
			LevelData.tag(crystal, pid)
