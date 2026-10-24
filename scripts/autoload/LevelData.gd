extends Node
## Loads JSON level overlays from user://editor/ or res://data/levels/.


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
		return {"zone": zone_id, "pieces": []}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"zone": zone_id, "pieces": []}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"zone": zone_id, "pieces": []}
	return parsed


static func save_raw(zone_id: String, data: Dictionary, to_res: bool = false) -> Error:
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


static func apply(parent: Node2D, zone_id: String) -> void:
	var data := load_raw(zone_id)
	var pieces: Array = data.get("pieces", [])
	for p in pieces:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		_spawn_piece(parent, p)


static func _spawn_piece(parent: Node2D, p: Dictionary) -> void:
	var kind: String = str(p.get("kind", "block"))
	var pos := Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
	var size := Vector2(float(p.get("w", 48)), float(p.get("h", 48)))
	match kind:
		"background":
			LevelCommon.add_brick_wall_face(parent, pos.x, pos.y, size.x, size.y)
		"block", "floor":
			LevelCommon.add_steel_floor(parent, pos.x, pos.y, size.x, maxf(size.y, 16.0))
		"wall":
			LevelCommon.add_wall(parent, pos.x, pos.y, size.x, size.y)
		"crate":
			var box := PushableBox.new()
			box.position = pos
			box.box_size = size
			parent.add_child(box)
		"light":
			var lamp := LightSource.new()
			lamp.position = pos
			lamp.radius = float(p.get("radius", 280.0))
			lamp.light_kind = int(p.get("light_kind", GameState.LightKind.HEARTH)) as GameState.LightKind
			lamp.pushable = bool(p.get("pushable", true))
			parent.add_child(lamp)
		"prop_bench":
			LevelCommon.add_bench(parent, pos)
		"prop_vent":
			LevelCommon.add_steam_vent(parent, pos)
		"prop_crate":
			LevelCommon.add_crate_prop(parent, pos, size)
