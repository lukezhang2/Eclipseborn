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

## In-memory editor overlays for this browser/tab session only.
## Refresh clears them — browser IndexedDB copies of user://editor/ are wiped on boot.
static var _session_overlays: Dictionary = {}
## True after this tab writes a session save. Lets load_raw read user:// mid-session
## (playtest) without resurrecting IndexedDB leftovers from a previous page load.
static var _session_disk_trusted: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(USER_DIR)
	## Drop leftover editor JSON from a previous page load (web IDBFS / desktop user://).
	clear_session_editor_overlays(true)
	if OS.has_feature("web"):
		## IDBFS may finish mounting after the first frames — wipe again so restored files die.
		call_deferred("_clear_editor_after_idbfs")


func _clear_editor_after_idbfs() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	## Never erase this tab's live editor saves (playtest disk mirror).
	if _session_disk_trusted:
		return
	clear_user_editor_files_only()
	await get_tree().create_timer(0.75).timeout
	if _session_disk_trusted:
		return
	clear_user_editor_files_only()


## Wipe session memory + on-disk editor overlays (call on boot / refresh).
static func clear_session_editor_overlays(wipe_disk: bool = true) -> void:
	_session_overlays.clear()
	_session_disk_trusted = false
	if wipe_disk:
		clear_user_editor_files_only()


static func clear_user_editor_files_only() -> void:
	var dir := DirAccess.open(USER_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(USER_DIR)
		dir = DirAccess.open(USER_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()
	## Persist the empty editor folder to IndexedDB so a refresh stays clean.
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"(function(){try{if(typeof FS!=='undefined'&&FS.syncfs){FS.syncfs(false,function(){});}}catch(e){}})();",
			true
		)


static func path_for(zone_id: String, prefer_user: bool = true) -> String:
	var user_path := USER_DIR + zone_id + ".json"
	var res_path := RES_DIR + zone_id + ".json"
	if prefer_user and FileAccess.file_exists(user_path):
		return user_path
	if FileAccess.file_exists(res_path):
		return res_path
	return user_path


static func load_raw(zone_id: String) -> Dictionary:
	## Prefer this tab's session overlay (survives playtest, dies on refresh).
	if _session_overlays.has(zone_id):
		return (_session_overlays[zone_id] as Dictionary).duplicate(true)
	## Mid-session disk mirror written by save_raw — only when this tab saved.
	## After a refresh, _session_disk_trusted is false so IndexedDB leftovers are ignored.
	if _session_disk_trusted:
		var user_path := USER_DIR + zone_id + ".json"
		if FileAccess.file_exists(user_path):
			var uf := FileAccess.open(user_path, FileAccess.READ)
			if uf:
				var user_parsed: Variant = JSON.parse_string(uf.get_as_text())
				if typeof(user_parsed) == TYPE_DICTIONARY:
					var user_data := user_parsed as Dictionary
					_session_overlays[zone_id] = user_data.duplicate(true)
					return user_data.duplicate(true)
	## Repo overlays only after refresh / with no session save.
	var path := RES_DIR + zone_id + ".json"
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
	if not to_res:
		## Session-only: playtest in this tab sees edits; refresh discards them.
		_session_overlays[zone_id] = data.duplicate(true)
		_session_disk_trusted = true
		## Mirror to user:// so playtest still works if memory races a scene change.
		DirAccess.make_dir_recursive_absolute(USER_DIR)
		var user_path := USER_DIR + zone_id + ".json"
		var uf := FileAccess.open(user_path, FileAccess.WRITE)
		if uf:
			uf.store_string(JSON.stringify(data, "\t"))
		return OK
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RES_DIR))
	var path := RES_DIR + zone_id + ".json"
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
	var overlay_by_id: Dictionary = {}
	for p in pieces:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var id := str(p.get("id", ""))
		if id != "":
			overlay_by_id[id] = p
		if bool(p.get("builtin", false)):
			continue  # builtins are spawned by the room script; synced below
		if id != "" and data.get("removed_ids", []).has(id):
			continue
		_spawn_piece(parent, p)
	## Push editor fields onto room-built catalog nodes (move lamp, retint crate, …).
	_sync_tagged_from_overlay(parent, overlay_by_id)
	prune_removed(parent, zone_id)


static func _sync_tagged_from_overlay(parent: Node, overlay_by_id: Dictionary) -> void:
	if overlay_by_id.is_empty() or parent == null:
		return
	_sync_tagged_recursive(parent, overlay_by_id)


static func _sync_tagged_recursive(node: Node, overlay_by_id: Dictionary) -> void:
	if node.has_meta("catalog_id"):
		var cid := str(node.get_meta("catalog_id"))
		if overlay_by_id.has(cid):
			_apply_overlay_to_node(node, overlay_by_id[cid] as Dictionary)
	for child in node.get_children():
		_sync_tagged_recursive(child, overlay_by_id)


static func _apply_overlay_to_node(node: Node, p: Dictionary) -> void:
	if node is Node2D and p.has("x") and p.has("y"):
		(node as Node2D).position = Vector2(float(p.get("x")), float(p.get("y")))
	if node is LightSource:
		var lamp := node as LightSource
		if p.has("radius"):
			lamp.set_radius(float(p.get("radius")))
		if p.has("intensity"):
			lamp.set_intensity(float(p.get("intensity")))
		if p.has("light_kind"):
			lamp.light_kind = int(p.get("light_kind")) as GameState.LightKind
		lamp.pushable = false
		return
	if node is PushableBox:
		var box := node as PushableBox
		if p.has("w") and p.has("h"):
			box.box_size = Vector2(float(p.get("w")), float(p.get("h")))
		return
	if node is LightSwitch:
		var sw := node as LightSwitch
		if p.has("starts_on"):
			sw.starts_on = bool(p.get("starts_on"))
		if p.has("target_ids"):
			var tids := PackedStringArray()
			for t in p.get("target_ids", []):
				tids.append(str(t))
			sw.target_ids = tids
		return
	if node is SwitchDoor:
		var door := node as SwitchDoor
		if p.has("starts_open"):
			door.starts_open = bool(p.get("starts_open"))
		if p.has("w"):
			door.width = maxf(float(p.get("w")), 20.0)
		if p.has("h"):
			door.height = maxf(float(p.get("h")), 64.0)
		return
	if node is Checkpoint:
		var cp := node as Checkpoint
		if p.has("name") and str(p.get("name", "")) != "":
			cp.checkpoint_name = str(p.get("name"))
		return
	if node is House:
		var house := node as House
		if p.has("w"):
			house.width = float(p.get("w"))
		if p.has("h"):
			house.height = float(p.get("h"))
		if p.has("name") and str(p.get("name", "")) != "":
			house.house_name = str(p.get("name"))
		if p.has("blocks_light"):
			house.blocks_light = bool(p.get("blocks_light"))
		if p.has("target_zone") and str(p.get("target_zone", "")) != "":
			house.house_id = str(p.get("target_zone"))
		elif p.has("house_id") and str(p.get("house_id", "")) != "":
			house.house_id = str(p.get("house_id"))
		if p.has("spawn_x") or p.has("spawn_y"):
			house.interior_spawn = Vector2(
				float(p.get("spawn_x", house.interior_spawn.x)),
				float(p.get("spawn_y", house.interior_spawn.y))
			)
		if p.has("caption"):
			house.travel_caption = str(p.get("caption"))
		if p.has("layer"):
			house.z_index = int(p.get("layer"))
		return
	if node is BreakableHatch:
		var hatch := node as BreakableHatch
		if p.has("w") and p.has("h"):
			hatch.hatch_size = Vector2(maxf(float(p.get("w")), 40.0), maxf(float(p.get("h")), 12.0))
		if p.has("target_zone") and str(p.get("target_zone", "")) != "":
			hatch.next_scene = SaveManager.scene_for_zone(str(p.get("target_zone")))
		if p.has("spawn_x") or p.has("spawn_y"):
			hatch.spawn_in_next = Vector2(
				float(p.get("spawn_x", hatch.spawn_in_next.x)),
				float(p.get("spawn_y", hatch.spawn_in_next.y))
			)
		return
	if node is BreakableProp:
		var jar := node as BreakableProp
		if p.has("w") and p.has("h"):
			jar.prop_size = Vector2(float(p.get("w")), float(p.get("h")))
		return
	if node is NPC:
		var npc := node as NPC
		if p.has("name") and str(p.get("name", "")) != "":
			npc.npc_name = str(p.get("name"))
		if p.has("lines"):
			npc.lines = HouseProfiles.lines_to_packed(p.get("lines", ["…"]))
		if p.has("is_shopkeeper"):
			npc.is_shopkeeper = bool(p.get("is_shopkeeper"))
		if p.has("shop_items"):
			npc.shop_items = ShopCatalog.normalize_shop_items(p.get("shop_items", []))
		return
	if node is ShadowCrystal:
		var crystal := node as ShadowCrystal
		if p.has("name") and str(p.get("name", "")) != "":
			crystal.display_name = str(p.get("name"))
		return
	## Zone-link exit doors (scripted Node, not always class_name).
	if node.get_script() != null and str(node.get_script().resource_path).ends_with("ZoneLinkDoor.gd"):
		if p.has("target_zone"):
			node.set("target_zone", str(p.get("target_zone")))
		if p.has("spawn_x") or p.has("spawn_y"):
			node.set(
				"spawn_pos",
				Vector2(float(p.get("spawn_x", 520)), float(p.get("spawn_y", 460)))
			)
		if p.has("caption") or p.has("travel_caption"):
			node.set("travel_caption", str(p.get("caption", p.get("travel_caption", ""))))
		if p.has("name"):
			node.set("verb", str(p.get("name")))
		return
	_apply_tint(node, _piece_tint(p))


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
			LevelData.tag(bg, str(p.get("id", "")))
		"prop_backdrop":
			var mural := LevelCommon.add_art_backdrop(
				parent, pos, size, clampi(int(p.get("style", 0)), 0, 2)
			)
			_apply_tint(mural, tint)
			LevelData.tag(mural, str(p.get("id", "")))
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
			lamp.pushable = false
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
		"prop_exit":
			var exit_scr: GDScript = load("res://scripts/world/ZoneLinkDoor.gd") as GDScript
			var exit: Node = exit_scr.new()
			exit.position = pos
			exit.set("target_zone", str(p.get("target_zone", "lantern_village")))
			exit.set("spawn_pos", Vector2(float(p.get("spawn_x", 520)), float(p.get("spawn_y", 460))))
			exit.set("travel_caption", str(p.get("caption", p.get("travel_caption", ""))))
			exit.set("verb", str(p.get("name", "Leave")))
			exit.set("show_exit_arrow", bool(p.get("show_arrow", true)))
			parent.add_child(exit)
			LevelData.tag(exit, str(p.get("id", "")))
		"prop_house":
			var house_scr: GDScript = load("res://scripts/world/House.gd") as GDScript
			var house: Node = house_scr.new()
			house.position = pos
			house.set("house_name", str(p.get("name", "House")))
			house.set("house_id", str(p.get("target_zone", p.get("house_id", p.get("id", "house_keep")))))
			house.set("width", maxf(size.x, 80.0))
			house.set("height", maxf(size.y, 60.0))
			house.set("blocks_light", bool(p.get("blocks_light", true)))
			house.set("interior_spawn", Vector2(float(p.get("spawn_x", 160)), float(p.get("spawn_y", 460))))
			house.set("travel_caption", str(p.get("caption", "")))
			parent.add_child(house)
			LevelData.tag(house, str(p.get("id", "")))
		"prop_hatch":
			var hatch_scr: GDScript = load("res://scripts/world/BreakableHatch.gd") as GDScript
			var hatch: Node = hatch_scr.new()
			hatch.position = pos
			hatch.set("hatch_size", Vector2(maxf(size.x, 40.0), maxf(size.y, 12.0)))
			var hz := str(p.get("target_zone", "lantern_village"))
			hatch.set("next_scene", SaveManager.scene_for_zone(hz))
			hatch.set("spawn_in_next", Vector2(float(p.get("spawn_x", 140)), float(p.get("spawn_y", 460))))
			parent.add_child(hatch)
			LevelData.tag(hatch, str(p.get("id", "")))
		"prop_breakable":
			var jar_scr: GDScript = load("res://scripts/world/BreakableProp.gd") as GDScript
			var jar: Node = jar_scr.new()
			jar.position = pos
			jar.set("breakable_id", str(p.get("id", "")))
			parent.add_child(jar)
			LevelData.tag(jar, str(p.get("id", "")))
		"prop_enemy":
			var enemy := spawn_creature(parent, p, pos)
			LevelData.tag(enemy, str(p.get("id", "")))
		"prop_pipe":
			LevelCommon.add_pipe(parent, pos + Vector2(-size.x * 0.5, 0), pos + Vector2(size.x * 0.5, 0), maxf(size.y, 8.0))
		"prop_valve":
			var valve := LevelCommon.add_valve(parent, pos)
			LevelData.tag(valve, str(p.get("id", "")))
		"prop_tower":
			var tower_scr: GDScript = load("res://scripts/world/ClockworkTower.gd") as GDScript
			var tower: Node = tower_scr.new()
			tower.position = pos
			parent.add_child(tower)
			LevelData.tag(tower, str(p.get("id", "")))
		"prop_desk":
			var desk := Node2D.new()
			desk.position = pos
			var dart := WorldArt.new()
			dart.kind = WorldArt.Kind.DESK
			dart.style = int(p.get("style", 0))
			dart.size = size
			desk.add_child(dart)
			desk.z_index = int(p.get("layer", PieceSpecs.default_draw_layer("prop_desk")))
			parent.add_child(desk)
			LevelData.tag(desk, str(p.get("id", "")))
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


static func spawn_creature(parent: Node, p: Dictionary, pos: Vector2) -> Node:
	## Missing enemy_kind stays a wanderer. Missing damage leaves the script default.
	var kind := str(p.get("enemy_kind", "wander"))
	var enemy: Node
	match kind:
		"mite":
			enemy = RivetMite.new()
		"beetle":
			enemy = FuseBeetle.new()
		"pendulum":
			enemy = PendulumSentinel.new()
		"lamplighter":
			var packed: PackedScene = load("res://scenes/enemies/BasicEnemy.tscn")
			enemy = packed.instantiate()
			enemy.set_script(load("res://scripts/enemies/Lamplighter.gd"))
		_:
			var wander: PackedScene = load("res://scenes/enemies/WanderEnemy.tscn")
			enemy = wander.instantiate()
	enemy.position = pos
	parent.add_child(enemy)
	if p.has("damage"):
		apply_attack_damage(enemy, int(p.get("damage")))
	if p.has("hp"):
		apply_max_hp(enemy, int(p.get("hp")))
	return enemy


static func apply_max_hp(enemy: Node, hp: int) -> void:
	if enemy == null:
		return
	enemy.set("max_hp", hp)
	enemy.set("hp", hp)


static func apply_attack_damage(enemy: Node, dmg: int) -> void:
	if enemy == null:
		return
	enemy.set("attack_damage", dmg)
	_stamp_hitboxes(enemy, dmg)


static func _stamp_hitboxes(n: Node, dmg: int) -> void:
	if n is Hitbox:
		(n as Hitbox).damage = dmg
	for c in n.get_children():
		_stamp_hitboxes(c, dmg)
