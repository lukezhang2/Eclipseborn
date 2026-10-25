extends RefCounted
class_name PieceSpecs
## Canonical editor/game sizes and anchors for each piece kind.
## Keep in sync with room scripts (CursedCottage / LanternVillage) and PushableBox.
##
## Anchor:
##   "center" — (x,y) is AABB center (floors, walls, crates, lights)
##   "bottom" — (x,y) is feet on the floor line (houses, checkpoints, benches, towers)


const SCHEMA_VERSION := 1

## Pushable crates are ~1.2× the old 48 / 56 bases.
const CRATE_COTTAGE := Vector2(58, 58)
const CRATE_VILLAGE := Vector2(67, 67)

## Piece id / display naming uses numbers (window_1), not letters (window_a).


static func _letter_index(ch: String) -> int:
	## a→1 … z→26; else 0.
	if ch.length() != 1:
		return 0
	var code := ch.to_lower().unicode_at(0)
	var a := "a".unicode_at(0)
	var z := "z".unicode_at(0)
	if code < a or code > z:
		return 0
	return code - a + 1


static func id_base(piece_id: String) -> String:
	## "window_3" / "window_a" / "prop_vent_12" → base without trailing index.
	var id := piece_id.strip_edges()
	if id == "":
		return "piece"
	var parts := id.split("_")
	if parts.is_empty():
		return id
	var tail := str(parts[parts.size() - 1])
	if tail.is_valid_int() or _letter_index(tail) > 0:
		parts.remove_at(parts.size() - 1)
		if parts.is_empty():
			return id
		return "_".join(parts)
	return id


static func letter_suffix_to_number(piece_id: String) -> String:
	## Convert trailing _a…_z to _1…_26. Leaves already-numbered / unlettered ids alone.
	var id := piece_id.strip_edges()
	if id == "":
		return id
	var parts := id.split("_")
	if parts.is_empty():
		return id
	var n := _letter_index(str(parts[parts.size() - 1]))
	if n > 0:
		parts[parts.size() - 1] = str(n)
		return "_".join(parts)
	return id


static func number_display_name(name: String, number: int) -> String:
	## "Window A" / "Window 2" / "Steam Vent" → "Window N" (or "Steam Vent N").
	var n := name.strip_edges()
	if n == "":
		return "Piece %d" % number
	var parts := n.split(" ")
	if parts.size() >= 2:
		var last := str(parts[parts.size() - 1])
		if last.is_valid_int() or _letter_index(last) > 0:
			parts[parts.size() - 1] = str(number)
			return " ".join(parts)
	return "%s %d" % [n, number]


static func next_number_for_base(base: String, existing_ids: Array) -> int:
	## Highest trailing number for this base among existing ids, plus one (min 1).
	var best := 0
	var prefix := base + "_"
	for raw in existing_ids:
		var id := str(raw)
		if not id.begins_with(prefix):
			continue
		var tail := id.substr(prefix.length())
		if tail.is_valid_int():
			best = maxi(best, int(tail))
		else:
			best = maxi(best, _letter_index(tail))
	return best + 1


static func alloc_numbered_id(base: String, existing_ids: Array) -> String:
	var b := base.strip_edges()
	if b == "":
		b = "piece"
	return "%s_%d" % [b, next_number_for_base(b, existing_ids)]

## Draw layer the live Player uses (CharacterBody2D default z_index).
const PLAYER_DRAW_LAYER := 0
## Physics layer bit used only for light rays (not player collision). See ShadowWorld.
const LIGHT_BLOCK_PHYSICS_LAYER := 128


static func default_blocks_light(kind: String) -> bool:
	## Default ON — opt out for emitters, characters, and pure draw props.
	match kind:
		"light", "background", "prop_npc", "prop_enemy", "prop_pickup", "prop_switch", "prop_checkpoint":
			return false
		_:
			return true

static func is_linkable_target(kind: String) -> bool:
	return kind in ["light", "prop_lantern", "prop_door"]


static func is_switch_kind(kind: String) -> bool:
	return kind == "prop_switch"


static func is_platform_kind(kind: String) -> bool:
	return kind == "prop_platform"


static func default_draw_layer(kind: String) -> int:
	## Relative to PLAYER_DRAW_LAYER (0). Negative = behind player.
	match kind:
		"background", "prop_bg_gear":
			return -8
		"floor", "wall", "block":
			return -4
		"prop_pipe", "prop_window", "prop_valve", "prop_desk":
			return -3
		## Houses/towers above washes (−3) so lantern fill does not paint through facades.
		"prop_house", "prop_tower":
			return -1
		"prop_bench", "prop_vent", "prop_checkpoint", "prop_crate", "prop_hatch", "prop_exit", "prop_platform":
			return -2
		"crate", "prop_breakable", "prop_npc", "prop_enemy", "prop_switch", "prop_door":
			return 1
		"light", "prop_lantern", "prop_pickup":
			return 2
		_:
			return 0


static func default_size(kind: String) -> Vector2:
	match kind:
		"crate":
			return CRATE_COTTAGE
		"floor":
			return Vector2(96, 32)
		"wall":
			return Vector2(48, 96)
		"light":
			return Vector2(28, 36) ## lamp body approx (radius is separate)
		"prop_bench":
			return Vector2(60, 28)
		"prop_vent":
			return Vector2(36, 16)
		"prop_crate":
			return Vector2(36, 28)
		"prop_checkpoint":
			return Vector2(56, 28)
		"prop_house":
			return Vector2(130, 100)
		"prop_npc":
			return Vector2(28, 48)
		"prop_enemy":
			return Vector2(28, 36)
		"prop_tower":
			return Vector2(160, 280)
		"prop_hatch":
			return Vector2(64, 16)
		"prop_breakable":
			return Vector2(28, 36)
		"prop_window":
			return Vector2(48, 56)
		"prop_bg_gear":
			return Vector2(110, 110)
		"prop_pickup":
			return Vector2(32, 32)
		"prop_switch":
			return Vector2(28, 40)
		"prop_door":
			return Vector2(28, 96)
		"prop_platform":
			return Vector2(140, 20)
		"prop_desk":
			return Vector2(200, 28)
		"prop_exit":
			return Vector2(40, 50)
		_:
			return Vector2(48, 48)


static func anchor(kind: String) -> String:
	## Matches how room scripts place the node origin.
	match kind:
		"prop_house", "prop_checkpoint", "prop_bench", "prop_vent", \
		"prop_hatch", "prop_tower", "prop_npc", "prop_switch", "prop_door", "prop_exit":
			return "bottom"
		"prop_platform":
			return "center"
		"prop_desk":
			return "center"
		_:
			return "center"


static func sit_on_floor_y(kind: String, floor_top: float, size: Vector2) -> float:
	## Y so the piece rests on floor_top (top surface of the steel/cobble floor).
	if anchor(kind) == "bottom":
		return floor_top
	return floor_top - size.y * 0.5


static func floor_top_for_zone(zone_id: String) -> float:
	match zone_id:
		"lantern_village":
			return 500.0 ## FLOOR_CENTER 520, H 40
		"clockwork_tower":
			return 2662.0 ## LOBBY_TOP (LOBBY_FLOOR 2680, H 36)
		"house_keep", "house_gear", "house_inn":
			return 500.0 ## HouseInterior FLOOR_Y
		_:
			return 482.0 ## FLOOR_CENTER 500, H 36