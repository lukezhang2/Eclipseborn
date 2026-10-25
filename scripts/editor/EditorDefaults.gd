extends RefCounted
class_name EditorDefaults
## Damage used when the designer adds a new creature. Stored per browser in user://
## so existing level pieces are left alone.

const PATH := "user://editor_defaults.cfg"


static func damage_for(creature: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK and cfg.has_section_key("damage", creature):
		return int(cfg.get_value("damage", creature))
	return PieceSpecs.creature_damage(creature)


static func set_damage(creature: String, value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("damage", creature, value)
	cfg.save(PATH)
