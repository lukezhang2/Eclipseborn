extends Node
## Single-player save slots. Group co-op saves come in Phase 3.

const SLOT_COUNT := 3
const SAVE_DIR := "user://saves"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.cfg" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func slot_summary(slot: int) -> String:
	if not has_save(slot):
		return "Empty"
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return "Empty"
	var zone: String = cfg.get_value("meta", "zone", "cursed_cottage")
	var health: int = cfg.get_value("player", "health", 100)
	var max_h: int = cfg.get_value("player", "max_health", 100)
	return "%s — %d/%d HP" % [zone.replace("_", " ").capitalize(), health, max_h]


func new_game(slot: int) -> void:
	GameState.reset_run()
	GameState.needs_intro_cutscene = true
	save_game(slot)


func save_game(slot: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "zone", GameState.current_zone_id)
	cfg.set_value("meta", "room", GameState.current_room_id)
	cfg.set_value("meta", "intro_done", not GameState.needs_intro_cutscene)
	cfg.set_value("player", "health", GameState.health)
	cfg.set_value("player", "max_health", GameState.max_health)
	cfg.set_value("player", "shade", GameState.shade)
	cfg.set_value("player", "umbra", GameState.umbra)
	cfg.set_value("player", "pos_x", GameState.checkpoint_position.x)
	cfg.set_value("player", "pos_y", GameState.checkpoint_position.y)
	cfg.set_value("abilities", "double_jump", GameState.has_double_jump)
	cfg.set_value("abilities", "shadow_grip", GameState.has_shadow_grip)
	cfg.set_value("map", "discovered", GameState.discovered_rooms)
	cfg.save(slot_path(slot))


func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return false
	GameState.reset_run()
	GameState.current_zone_id = cfg.get_value("meta", "zone", "cursed_cottage")
	GameState.current_room_id = cfg.get_value("meta", "room", "hall")
	GameState.needs_intro_cutscene = not cfg.get_value("meta", "intro_done", false)
	GameState.health = cfg.get_value("player", "health", 100)
	GameState.max_health = cfg.get_value("player", "max_health", 100)
	GameState.shade = cfg.get_value("player", "shade", 1.0)
	GameState.umbra = cfg.get_value("player", "umbra", 0.0)
	GameState.checkpoint_position = Vector2(
		cfg.get_value("player", "pos_x", 0.0),
		cfg.get_value("player", "pos_y", 0.0)
	)
	GameState.has_double_jump = cfg.get_value("abilities", "double_jump", false)
	GameState.has_shadow_grip = cfg.get_value("abilities", "shadow_grip", false)
	GameState.discovered_rooms = cfg.get_value("map", "discovered", {})
	GameState.health_changed.emit(GameState.health, GameState.max_health)
	GameState.shade_changed.emit(GameState.shade)
	return true
