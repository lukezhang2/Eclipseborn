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

## Draw layer the live Player uses (CharacterBody2D default z_index).
const PLAYER_DRAW_LAYER := 0
## Physics layer bit used only for light rays (not player collision). See ShadowWorld.
const LIGHT_BLOCK_PHYSICS_LAYER := 128


static func default_blocks_light(kind: String) -> bool:
	match kind:
		"floor", "wall", "block", "crate", "prop_house", "prop_desk", "prop_hatch":
			return true
		"light", "background", "prop_npc", "prop_bench", "prop_vent", "prop_checkpoint", \
		"prop_enemy", "prop_bg_gear", "prop_pickup", "prop_pipe", "prop_window", "prop_valve":
			return false
		_:
			return false


static func default_draw_layer(kind: String) -> int:
	## Relative to PLAYER_DRAW_LAYER (0). Negative = behind player.
	match kind:
		"background", "prop_bg_gear":
			return -8
		"prop_house", "prop_tower":
			return -6
		"floor", "wall", "block":
			return -4
		"prop_pipe", "prop_window", "prop_valve", "prop_desk":
			return -3
		"prop_bench", "prop_vent", "prop_checkpoint", "prop_crate", "prop_hatch", "prop_exit":
			return -2
		"crate", "prop_breakable", "prop_npc", "prop_enemy", "prop_switch":
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
			return Vector2(28, 28)
		"prop_switch":
			return Vector2(24, 40)
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
		"prop_hatch", "prop_tower", "prop_npc", "prop_switch", "prop_exit":
			return "bottom"
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
		"house_keep", "house_gear", "house_inn":
			return 500.0 ## HouseInterior FLOOR_Y
		_:
			return 482.0 ## FLOOR_CENTER 500, H 36
