extends RefCounted
class_name HouseProfiles
## Shared house / shopkeeper defaults for interiors + the level editor.


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["house_keep", "house_gear", "house_inn"])


static func is_house(zone_id: String) -> bool:
	return zone_id in all_ids()


static func get_profile(house_id: String) -> Dictionary:
	match house_id:
		"house_gear":
			return {
				"id": "house_gear",
				"title": "Gearwright",
				"keeper_name": "Gearwright",
				"npc_id": "npc_shop",
				"return_spawn": Vector2(980, 460),
				"shop_items": [
					{"id": "heal_tonic", "stock": -1},
					{"id": "shade_vial", "stock": -1},
					{"id": "double_jump", "stock": 1},
					{"id": "shadow_grip", "stock": 1},
					{"id": "gear_sense", "stock": 1},
					{"id": "shade_dash", "stock": 1},
				],
			}
		"house_inn":
			return {
				"id": "house_inn",
				"title": "Shade Inn",
				"keeper_name": "Innkeep",
				"npc_id": "npc_shop",
				"return_spawn": Vector2(1780, 460),
				"shop_items": [
					{"id": "heal_tonic", "stock": -1},
					{"id": "shade_vial", "stock": -1},
					{"id": "shade_heart", "stock": 5},
					{"id": "snuff", "stock": 1},
				],
			}
		_:
			return {
				"id": "house_keep",
				"title": "Lantern Keep",
				"keeper_name": "Keeper",
				"npc_id": "npc_shop",
				"npc_y": 450.0,
				"return_spawn": Vector2(520, 460),
				"shop_items": ShopCatalog.default_shop_stock(),
			}


static func lines_to_packed(lines: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if typeof(lines) == TYPE_PACKED_STRING_ARRAY:
		return lines
	if typeof(lines) == TYPE_ARRAY:
		for item in lines:
			var s := str(item).strip_edges()
			if s != "":
				out.append(s)
	elif typeof(lines) == TYPE_STRING:
		for line in str(lines).split("\n"):
			var s := line.strip_edges()
			if s != "":
				out.append(s)
	if out.is_empty():
		out.append("…")
	return out
