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
				"lines": [
					"You're the only shade-walker left. The rest of us live in the light fine.",
					"That umbra hunger of yours — it's not natural, traveler.",
					"I can fit gears. I can't fit whatever made you burn in daylight.",
				],
			}
		"house_inn":
			return {
				"id": "house_inn",
				"title": "Shade Inn",
				"keeper_name": "Innkeep",
				"npc_id": "npc_shop",
				"return_spawn": Vector2(1780, 460),
				"lines": [
					"Most guests sit by the hearth. You… flinch from it.",
					"You're the odd one — shade-bound while we walk the lantern streets.",
					"Room's in the dark wing. Figured you'd prefer it that way.",
				],
			}
		_:
			return {
				"id": "house_keep",
				"title": "Lantern Keep",
				"keeper_name": "Keeper",
				"npc_id": "npc_shop",
				"return_spawn": Vector2(520, 460),
				"lines": [
					"Everyone else thrives under lanterns. You alone need the dark.",
					"Spirit, you're marked — the shade clings to you like a second skin.",
					"We tend lamps. You flee them. That makes you the stranger here.",
				],
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
