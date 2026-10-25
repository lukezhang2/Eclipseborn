extends RefCounted
class_name ShopCatalog
## All buyable items — editor stock lists and shop menus share this catalog.


static func all_ids() -> PackedStringArray:
	return PackedStringArray([
		"heal_tonic",
		"shade_vial",
		"shade_heart",
		"double_jump",
		"shadow_grip",
		"shade_dash",
		"gear_sense",
		"reflect",
		"snuff",
	])


static func get_item(item_id: String) -> Dictionary:
	match item_id:
		"heal_tonic":
			return {
				"id": "heal_tonic",
				"name": "Heal Tonic",
				"desc": "Restore 40 health.",
				"price": 15,
				"kind": "consumable",
			}
		"shade_vial":
			return {
				"id": "shade_vial",
				"name": "Shade Vial",
				"desc": "Refill the shade bar.",
				"price": 12,
				"kind": "consumable",
			}
		"shade_heart":
			return {
				"id": "shade_heart",
				"name": "Shade Heart Shard",
				"desc": "Permanently raise max health.",
				"price": 50,
				"kind": "upgrade",
			}
		"double_jump":
			return {
				"id": "double_jump",
				"name": "Double Jump",
				"desc": "Jump again in mid-air.",
				"price": 80,
				"kind": "ability",
				"ability": "double_jump",
			}
		"shadow_grip":
			return {
				"id": "shadow_grip",
				"name": "Shadow Grip",
				"desc": "Cling to walls in the umbra.",
				"price": 80,
				"kind": "ability",
				"ability": "shadow_grip",
			}
		"shade_dash":
			return {
				"id": "shade_dash",
				"name": "Shade Dash",
				"desc": "Dash through burning light.",
				"price": 100,
				"kind": "ability",
				"ability": "shade_dash",
			}
		"gear_sense":
			return {
				"id": "gear_sense",
				"name": "Gear Sense",
				"desc": "Feel hidden mechanisms nearby.",
				"price": 60,
				"kind": "ability",
				"ability": "gear_sense",
			}
		"reflect":
			return {
				"id": "reflect",
				"name": "Reflect",
				"desc": "Turn enemy light back on itself.",
				"price": 90,
				"kind": "ability",
				"ability": "reflect",
			}
		"snuff":
			return {
				"id": "snuff",
				"name": "Snuff",
				"desc": "Extinguish a nearby lantern.",
				"price": 70,
				"kind": "ability",
				"ability": "snuff",
			}
		_:
			return {}


static func display_name(item_id: String) -> String:
	var it := get_item(item_id)
	return str(it.get("name", item_id.replace("_", " ").capitalize()))


static func price(item_id: String) -> int:
	return int(get_item(item_id).get("price", 0))


static func default_shop_stock() -> Array:
	## Sensible starter inventory for house shopkeepers (−1 = infinite).
	return [
		{"id": "heal_tonic", "stock": -1},
		{"id": "shade_vial", "stock": -1},
		{"id": "shade_heart", "stock": 3},
		{"id": "double_jump", "stock": 1},
		{"id": "shadow_grip", "stock": 1},
	]


static func normalize_shop_items(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry in raw:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id := str(entry.get("id", "")).strip_edges()
		if id == "" or get_item(id).is_empty():
			continue
		var stock := int(entry.get("stock", -1))
		## Clamp: −1 infinite, else 0+ finite.
		if stock < -1:
			stock = -1
		out.append({"id": id, "stock": stock})
	return out


static func owns_ability(item_id: String) -> bool:
	var it := get_item(item_id)
	if str(it.get("kind", "")) != "ability":
		return false
	var aid := str(it.get("ability", item_id))
	match aid:
		"double_jump":
			return GameState.has_double_jump
		"shadow_grip":
			return GameState.has_shadow_grip
		"shade_dash":
			return GameState.has_shade_dash
		"gear_sense":
			return GameState.has_gear_sense
		"reflect":
			return GameState.has_reflect
		"snuff":
			return GameState.has_snuff
		_:
			return false


static func apply_purchase(item_id: String) -> bool:
	var it := get_item(item_id)
	if it.is_empty():
		return false
	match str(it.get("kind", "")):
		"consumable":
			match item_id:
				"heal_tonic":
					GameState.heal(40)
					return true
				"shade_vial":
					GameState.shade = 1.0
					GameState.shade_changed.emit(GameState.shade)
					return true
				_:
					return false
		"upgrade":
			if item_id == "shade_heart":
				GameState.add_shade_heart()
				return true
			return false
		"ability":
			var aid := str(it.get("ability", item_id))
			if owns_ability(item_id):
				return false
			GameState.unlock_ability(aid)
			return true
		_:
			return false
