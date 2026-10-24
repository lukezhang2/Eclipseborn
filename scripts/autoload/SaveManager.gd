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
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		autosave()
	elif what == NOTIFICATION_PREDELETE:
		autosave()


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
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
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
	GameState.checkpoint_position = Vector2(
		cfg.get_value("player", "pos_x", 0.0),
		cfg.get_value("player", "pos_y", 0.0)
	)
	GameState.has_double_jump = cfg.get_value("abilities", "double_jump", false)
	GameState.has_shadow_grip = cfg.get_value("abilities", "shadow_grip", false)
	GameState.discovered_rooms = cfg.get_value("map", "discovered", {})
	GameState.broken_ids = cfg.get_value("world", "broken", [])
	GameState.health_changed.emit(GameState.health, GameState.max_health)
	GameState.shade_changed.emit(GameState.shade)
	GameState.currency_changed.emit(GameState.currency)
	return true


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
	cfg.set_value("abilities", "double_jump", GameState.has_double_jump)
	cfg.set_value("abilities", "shadow_grip", GameState.has_shadow_grip)
	cfg.set_value("map", "discovered", GameState.discovered_rooms)
	cfg.set_value("world", "broken", GameState.broken_ids)
	var err := cfg.save(slot_path(slot))
	if err == OK:
		_set_slot_exists(slot, true)
		current_slot = slot
