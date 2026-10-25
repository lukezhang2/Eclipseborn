extends Node
## Single-player save slots. Index file tracks deleted slots so web reloads stay empty.

const SLOT_COUNT := 3
const SAVE_DIR := "user://saves"
const INDEX_PATH := "user://saves/index.cfg"

## Active slot for autosave / exit save. -1 = none.
var current_slot: int = -1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	_ensure_index()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		autosave()
	elif what == NOTIFICATION_PREDELETE:
		autosave()


func _hearths_sidecar_path(slot: int) -> String:
	return "%s/slot_%d_hearths.json" % [SAVE_DIR, slot]


func _write_hearths_sidecar(slot: int) -> void:
	## Belt-and-suspenders for web IDBFS — plain JSON round-trips reliably.
	var path := _hearths_sidecar_path(slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(GameState.activated_checkpoints))
	f.flush()
	f.close()


func _read_hearths_sidecar(slot: int) -> Array:
	var path := _hearths_sidecar_path(slot)
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	return _normalize_checkpoints(parsed)


func _normalize_checkpoints(raw) -> Array:
	var out: Array = []
	if raw == null:
		return out
	if raw is String:
		var parsed = JSON.parse_string(raw)
		return _normalize_checkpoints(parsed)
	if not (raw is Array):
		return out
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item
		out.append({
			"id": str(d.get("id", "")),
			"zone": str(d.get("zone", "")),
			"x": float(d.get("x", 0.0)),
			"y": float(d.get("y", 0.0)),
			"name": str(d.get("name", d.get("id", "Rest"))),
		})
	return out


func _persist_web_fs() -> void:
	## Nudge browser FS sync so tab-close after a hearth rest keeps the save.
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"(function(){try{if(typeof FS!=='undefined'&&FS.syncfs){FS.syncfs(false,function(){});}}catch(e){}})();",
		true
	)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.cfg" % [SAVE_DIR, slot]


func _ensure_index() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(INDEX_PATH) != OK:
		cfg.set_value("slots", "exists_0", has_save_file(0))
		cfg.set_value("slots", "exists_1", has_save_file(1))
		cfg.set_value("slots", "exists_2", has_save_file(2))
		cfg.save(INDEX_PATH)
		return
	# Honor explicit deletions even if a stale file somehow remains.
	for i in SLOT_COUNT:
		if cfg.has_section_key("slots", "exists_%d" % i):
			continue
		cfg.set_value("slots", "exists_%d" % i, has_save_file(i))
	cfg.save(INDEX_PATH)


func has_save_file(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func has_save(slot: int) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(INDEX_PATH) == OK and cfg.has_section_key("slots", "exists_%d" % slot):
		return bool(cfg.get_value("slots", "exists_%d" % slot, false))
	return has_save_file(slot)


func _set_slot_exists(slot: int, exists: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(INDEX_PATH)
	cfg.set_value("slots", "exists_%d" % slot, exists)
	cfg.save(INDEX_PATH)


func delete_save(slot: int) -> void:
	var path := slot_path(slot)
	# Prefer directory-relative remove (more reliable on HTML5 IndexedDB).
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		var fname := "slot_%d.cfg" % slot
		if dir.file_exists(fname):
			dir.remove(fname)
		var side := "slot_%d_hearths.json" % slot
		if dir.file_exists(side):
			dir.remove(side)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var side_path := _hearths_sidecar_path(slot)
	if FileAccess.file_exists(side_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(side_path))
	_set_slot_exists(slot, false)
	if current_slot == slot:
		current_slot = -1
	# Flush index again after delete.
	_set_slot_exists(slot, false)


func slot_summary(slot: int) -> String:
	if not has_save(slot):
		return "Empty"
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return "Empty"
	var zone: String = cfg.get_value("meta", "zone", "cursed_cottage")
	var health: int = cfg.get_value("player", "health", 100)
	var max_h: int = cfg.get_value("player", "max_health", 100)
	var gears: int = cfg.get_value("player", "currency", 0)
	return "%s — %d/%d HP — %d gears" % [zone.replace("_", " ").capitalize(), health, max_h, gears]


func new_game(slot: int) -> void:
	GameState.reset_run()
	GameState.needs_intro_cutscene = true
	current_slot = slot
	save_game(slot)


func scene_for_zone(zone_id: String) -> String:
	match zone_id:
		"lantern_village":
			return "res://scenes/rooms/LanternVillage.tscn"
		"house_keep", "house_gear", "house_inn":
			GameState.set_meta("pending_house_id", zone_id)
			return "res://scenes/rooms/HouseInterior.tscn"
		_:
			return "res://scenes/rooms/CursedCottage.tscn"


func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return false
	GameState.reset_run()
	current_slot = slot
	GameState.current_zone_id = cfg.get_value("meta", "zone", "cursed_cottage")
	GameState.current_room_id = cfg.get_value("meta", "room", "hall")
	GameState.needs_intro_cutscene = not cfg.get_value("meta", "intro_done", false)
	GameState.health = cfg.get_value("player", "health", 100)
	GameState.max_health = cfg.get_value("player", "max_health", 100)
	GameState.shade = cfg.get_value("player", "shade", 1.0)
	GameState.umbra = cfg.get_value("player", "umbra", 0.0)
	GameState.currency = cfg.get_value("player", "currency", 0)
	GameState.currency_hud_unlocked = cfg.get_value("player", "currency_hud", false)
	## pos_x/y = where the player left / continues (NOT the rest hearth).
	var continue_pos := Vector2(
		float(cfg.get_value("player", "pos_x", 0.0)),
		float(cfg.get_value("player", "pos_y", 0.0))
	)
	GameState.last_position = continue_pos
	GameState.has_double_jump = cfg.get_value("abilities", "double_jump", false)
	GameState.has_shadow_grip = cfg.get_value("abilities", "shadow_grip", false)
	GameState.has_shade_dash = cfg.get_value("abilities", "shade_dash", false)
	GameState.has_gear_sense = cfg.get_value("abilities", "gear_sense", false)
	GameState.has_reflect = cfg.get_value("abilities", "reflect", false)
	GameState.has_snuff = cfg.get_value("abilities", "snuff", false)
	GameState.discovered_rooms = cfg.get_value("map", "discovered", {})
	GameState.broken_ids = cfg.get_value("world", "broken", [])
	GameState.collected_ids = cfg.get_value("world", "collected", [])
	if typeof(GameState.collected_ids) != TYPE_ARRAY:
		GameState.collected_ids = []
	var stock_raw = cfg.get_value("world", "shop_stock", {})
	GameState.shop_stock = stock_raw if typeof(stock_raw) == TYPE_DICTIONARY else {}
	## Prefer JSON sidecar / checkpoints_json — nested Array-of-Dict can drop on web reload.
	var hearths: Array = []
	var json_field = cfg.get_value("map", "checkpoints_json", "")
	if json_field is String and str(json_field) != "":
		hearths = _normalize_checkpoints(json_field)
	if hearths.is_empty():
		hearths = _read_hearths_sidecar(slot)
	if hearths.is_empty():
		hearths = _normalize_checkpoints(cfg.get_value("map", "checkpoints", []))
	GameState.activated_checkpoints = hearths
	GameState.checkpoint_path = str(cfg.get_value("meta", "checkpoint_id", ""))
	## Death respawn uses the rest hearth — never the continue/logout position.
	GameState.checkpoint_position = _resolve_checkpoint_position(cfg, hearths, continue_pos)
	GameState.health_changed.emit(GameState.health, GameState.max_health)
	GameState.shade_changed.emit(GameState.shade)
	GameState.currency_changed.emit(GameState.currency)
	return true


func _resolve_checkpoint_position(cfg: ConfigFile, hearths: Array, fallback: Vector2) -> Vector2:
	## Dedicated fields (new saves), else hearth list by id (legacy), else continue pos.
	if cfg.has_section_key("player", "checkpoint_x") and cfg.has_section_key("player", "checkpoint_y"):
		var cp := Vector2(
			float(cfg.get_value("player", "checkpoint_x", 0.0)),
			float(cfg.get_value("player", "checkpoint_y", 0.0))
		)
		if cp != Vector2.ZERO:
			return cp
	var want_id := str(cfg.get_value("meta", "checkpoint_id", ""))
	if want_id != "":
		for raw in hearths:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = raw
			if str(e.get("id", "")) == want_id:
				return Vector2(float(e.get("x", 0.0)), float(e.get("y", 0.0)))
	## Last activated hearth if any.
	if not hearths.is_empty() and typeof(hearths[hearths.size() - 1]) == TYPE_DICTIONARY:
		var last: Dictionary = hearths[hearths.size() - 1]
		var p := Vector2(float(last.get("x", 0.0)), float(last.get("y", 0.0)))
		if p != Vector2.ZERO:
			return p
	return fallback


func capture_player_position() -> void:
	## Don't clobber an intentional transition spawn (hatch → next zone).
	if GameState.pending_spawn != Vector2.ZERO:
		GameState.last_position = GameState.pending_spawn
		return
	if GameState.player and is_instance_valid(GameState.player):
		GameState.last_position = (GameState.player as Node2D).global_position
	elif GameState.checkpoint_position != Vector2.ZERO:
		GameState.last_position = GameState.checkpoint_position


func autosave() -> void:
	if current_slot < 0:
		return
	if GameState.editor_playtesting:
		return
	capture_player_position()
	save_game(current_slot)


func save_game(slot: int = -1) -> void:
	if slot < 0:
		slot = current_slot
	if slot < 0:
		return
	capture_player_position()
	var pos := GameState.last_position
	if GameState.pending_spawn != Vector2.ZERO:
		pos = GameState.pending_spawn
	elif pos == Vector2.ZERO:
		pos = GameState.checkpoint_position
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "zone", GameState.current_zone_id)
	cfg.set_value("meta", "room", GameState.current_room_id)
	cfg.set_value("meta", "intro_done", not GameState.needs_intro_cutscene)
	cfg.set_value("player", "health", GameState.health)
	cfg.set_value("player", "max_health", GameState.max_health)
	cfg.set_value("player", "shade", GameState.shade)
	cfg.set_value("player", "umbra", GameState.umbra)
	cfg.set_value("player", "currency", GameState.currency)
	cfg.set_value("player", "currency_hud", GameState.currency_hud_unlocked)
	cfg.set_value("player", "pos_x", pos.x)
	cfg.set_value("player", "pos_y", pos.y)
	## Rest hearth used on death — kept separate from continue/logout pos above.
	cfg.set_value("player", "checkpoint_x", GameState.checkpoint_position.x)
	cfg.set_value("player", "checkpoint_y", GameState.checkpoint_position.y)
	cfg.set_value("abilities", "double_jump", GameState.has_double_jump)
	cfg.set_value("abilities", "shadow_grip", GameState.has_shadow_grip)
	cfg.set_value("abilities", "shade_dash", GameState.has_shade_dash)
	cfg.set_value("abilities", "gear_sense", GameState.has_gear_sense)
	cfg.set_value("abilities", "reflect", GameState.has_reflect)
	cfg.set_value("abilities", "snuff", GameState.has_snuff)
	cfg.set_value("map", "discovered", GameState.discovered_rooms)
	var hearths := _normalize_checkpoints(GameState.activated_checkpoints)
	GameState.activated_checkpoints = hearths
	cfg.set_value("map", "checkpoints", hearths)
	cfg.set_value("map", "checkpoints_json", JSON.stringify(hearths))
	cfg.set_value("meta", "checkpoint_id", GameState.checkpoint_path)
	cfg.set_value("world", "broken", GameState.broken_ids)
	cfg.set_value("world", "collected", GameState.collected_ids)
	cfg.set_value("world", "shop_stock", GameState.shop_stock)
	var err := cfg.save(slot_path(slot))
	_write_hearths_sidecar(slot)
	_persist_web_fs()
	if err == OK:
		_set_slot_exists(slot, true)
		current_slot = slot
