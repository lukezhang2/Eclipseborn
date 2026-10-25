extends RefCounted
class_name ZoneCatalog
## Named props that make up each zone (mirrors the live room scripts).
## Sizes/anchors come from PieceSpecs — keep in sync with CursedCottage / LanternVillage / HouseInterior.
## See docs/LEVEL_EDITOR.md for the JSON schema.


static func zone_ids() -> PackedStringArray:
	return PackedStringArray([
		"cursed_cottage",
		"lantern_village",
		"house_keep",
		"house_gear",
		"house_inn",
	])


static func pieces_for(zone_id: String) -> Array:
	match zone_id:
		"lantern_village":
			return _village()
		"house_keep", "house_gear", "house_inn":
			return _house_interior(zone_id)
		_:
			return _cottage()


static func _cottage() -> Array:
	var FLOOR_TOP := PieceSpecs.floor_top_for_zone("cursed_cottage")
	var crate := PieceSpecs.CRATE_COTTAGE
	var out: Array = []
	out.append(_p("floor_main", "floor", "Steel Floor", 2000, 500, 4000, 36))
	out.append(_p("roof_main", "wall", "Roof Slab", 2000, 200, 4000, 36))
	out.append(_p("border_left", "wall", "Border Left", 24, 340, 48, 360))
	out.append(_p("border_right", "wall", "Border Right", 3976, 340, 48, 360))
	out.append(_p("pipe_main", "prop_pipe", "Ceiling Pipe", 2000, 238, 3900, 12))
	out.append(_p("valve_a", "prop_valve", "Valve", 220, 308, 24, 24))
	out.append(_p("window_a", "prop_window", "Window A", 180, 318, 48, 56))
	out.append(_p("window_b", "prop_window", "Window B", 980, 318, 48, 56))
	out.append(_p("window_c", "prop_window", "Window C", 1780, 318, 48, 56))
	out.append(_p("window_d", "prop_window", "Window D", 2580, 318, 52, 56))
	out.append(_p("window_e", "prop_window", "Window E", 3380, 318, 48, 56))
	out.append(_p("bench_a", "prop_bench", "Bench", 300, FLOOR_TOP - 4, 60, 20))
	out.append(_p("vent_a", "prop_vent", "Steam Vent", 860, FLOOR_TOP - 4, 36, 16))
	out.append(_p("decor_crate_a", "prop_crate", "Decor Crate A", 520, FLOOR_TOP - 14, 36, 28))
	out.append(_p("decor_crate_b", "prop_crate", "Decor Crate B", 2920, FLOOR_TOP - 15, 40, 30))
	## Pushable crates: 58×58 sitting on FLOOR_TOP (center ≈ FLOOR_TOP - 29).
	out.append(_p("box_push_a", "crate", "Pushable Crate (lamp room)", 1222.13659667969, 452.331481933594, crate.x, crate.y))
	out.append(_p("box_pull_a", "crate", "Pushable Crate (pull puzzle)", 1901.41931152344, 452.577880859375, crate.x, crate.y))
	out.append(_p("wall_tall", "wall", "Tall Pull Wall", 2080, FLOOR_TOP - 50, 32, 100))
	out.append(_p("wall_backstop", "wall", "Pull Backstop", 1854.39147949219, 457.149475097656, 33.0551719665527, 49.701171875))
	out.append(_p("platform_crate_room", "floor", "Cover Platform", 1120, FLOOR_TOP - 100, 180, 22))
	out.append(_p("ledge_a", "floor", "Jump Ledge A", 2700, FLOOR_TOP - 55, 140, 22))
	out.append(_p("ledge_b", "floor", "Jump Ledge B", 2840, FLOOR_TOP - 100, 100, 22))
	out.append(_plight("lamp_crate", "Hearth Lamp (crate room)", 1120, FLOOR_TOP - 170, 240))
	out.append(_plight("lamp_moon", "Moon Lamp", 400, 258, 140))
	out.append(_p("jar_a", "prop_breakable", "Glowing Jar A", 420, FLOOR_TOP - 18, 28, 36))
	out.append(_p("jar_b", "prop_breakable", "Glowing Jar B", 1480, FLOOR_TOP - 18, 28, 36))
	out.append(_p("jar_c", "prop_breakable", "Glowing Jar C", 2400, FLOOR_TOP - 18, 28, 36))
	out.append(_p("chest_a", "prop_breakable", "Glowing Chest", 3100, FLOOR_TOP - 16, 40, 32))
	out.append(_p("hatch_exit", "prop_hatch", "Exit Hatch", 3480, FLOOR_TOP - 2, 64, 16))
	out.append(_p("wall_end", "wall", "End Wall", 3720, FLOOR_TOP - 90, 80, 180))
	out.append(_p("checkpoint_hatch", "prop_checkpoint", "Checkpoint (cottage hatch)", 3300, FLOOR_TOP - 4, 56, 24))
	return out


static func _village() -> Array:
	var FLOOR_TOP := PieceSpecs.floor_top_for_zone("lantern_village")
	var MAP_W := 3200.0
	var out: Array = []
	out.append(_p("floor_main", "floor", "Cobble Floor", MAP_W * 0.5, 520, MAP_W, 40))
	out.append(_p("border_left", "wall", "Border Left", 24, 330, 48, 360))
	out.append(_p("border_right", "wall", "Border Right", MAP_W - 24, 330, 48, 360))
	out.append(_p("pipe_wire", "prop_pipe", "Overhead Wire", MAP_W * 0.5, 90, MAP_W - 120, 12))
	out.append(_plight("lantern_a", "Hanging Lantern A", 280, 160, 120))
	out.append(_plight("lantern_b", "Hanging Lantern B", 720, 160, 120))
	out.append(_plight("lantern_c", "Hanging Lantern C", 1600, 160, 120))
	out.append(_p("window_a", "prop_window", "Window", 360, 220, 44, 60))
	out.append(_p("bench_a", "prop_bench", "Bench", 455, FLOOR_TOP, 60, 20))
	out.append(_p("vent_a", "prop_vent", "Steam Vent", 1053, FLOOR_TOP, 36, 16))
	out.append(_p("house_keep", "prop_house", "House: Lantern Keep", 520, FLOOR_TOP, 130, 100))
	out.append(_p("house_gear", "prop_house", "House: Gearwright", 980, FLOOR_TOP, 110, 88))
	out.append(_p("house_inn", "prop_house", "House: Shade Inn", 1780, FLOOR_TOP, 140, 110))
	## Editor save uses 56×56 for this puzzle crate (sits at y=472 on FLOOR_TOP 500).
	out.append(_p("crate_puzzle", "crate", "Pushable Crate (light puzzle)", 1250, 472, 56, 56))
	out.append(_plight("lamp_puzzle", "Pushable Hearth Lamp", 1292, 238, 300))
	out.append(_plight("lamp_street", "Street Lamp", 748, 312, 250))
	out.append(_plight("lamp_square", "Square Lamp", 2000, 300, 260))
	var sw := _p("switch_street", "prop_switch", "Light Switch", 372, 488, 24, 40)
	sw["starts_on"] = true
	sw["target_ids"] = ["lamp_street", "lamp_square"]
	out.append(sw)
	out.append(_pplat("platform_gear_a", "Moving Platform A", 1278, 414, 140, 20, {
		"move_amplitude": 200.0, "move_speed": 0.65, "vertical": false,
		"path_y_amplitude": 0.0, "rotate_while_moving": true, "rotate_speed": 1.0,
		"rotate_platform": false, "with_gear": true,
		"gear_dx": -94.0, "gear_dy": -110.0, "gear_radius": 55.0,
	}))
	out.append(_pplat("platform_gear_b", "Moving Platform B", 2305.59130859375, FLOOR_TOP - 130, 120, 20, {
		"move_amplitude": 70.0, "move_speed": 0.55, "vertical": true,
		"path_y_amplitude": 0.0, "rotate_while_moving": true, "rotate_speed": 1.2,
		"rotate_platform": false, "with_gear": true,
		"gear_dx": -100.0, "gear_dy": -110.0, "gear_radius": 70.0,
	}))
	out.append(_p("bg_gear_a", "prop_bg_gear", "BG Gear A", 1450, 300, 110, 110))
	out.append(_p("bg_gear_b", "prop_bg_gear", "BG Gear B", 2200, 260, 140, 140))
	out.append(_p("enemy_a", "prop_enemy", "Wander Enemy A", 1500, FLOOR_TOP - 20, 28, 36))
	out.append(_p("enemy_b", "prop_enemy", "Wander Enemy B", 2050, FLOOR_TOP - 20, 28, 36))
	out.append(_p("tower", "prop_tower", "Clockwork Tower", MAP_W - 200, FLOOR_TOP, 160, 280))
	out.append(_p("shade_heart", "prop_pickup", "Shade Heart", 2407.53247070312, 256, 28, 28))
	out.append(_p("checkpoint_gate", "prop_checkpoint", "Checkpoint (village gate) — the … hearth", 200, FLOOR_TOP, 56, 24))
	return out


static func _house_interior(house_id: String) -> Array:
	var profile := HouseProfiles.get_profile(house_id)
	var FLOOR_TOP := 500.0
	var MAP_W := 720.0
	var out: Array = []
	out.append(_p("floor_main", "floor", "Shop Floor", MAP_W * 0.5, FLOOR_TOP + 20.0, MAP_W, 40))
	out.append(_p("roof_main", "wall", "Shop Roof", MAP_W * 0.5, 180.0, MAP_W, 36))
	out.append(_p("border_left", "wall", "Border Left", 24, 330, 48, 360))
	out.append(_p("border_right", "wall", "Border Right", MAP_W - 24, 330, 48, 360))
	out.append(_p("desk", "prop_desk", "Shop Desk", MAP_W * 0.5, FLOOR_TOP - 8, 200, 28))
	out.append(_p("exit_door", "prop_exit", "Exit Door", 80, FLOOR_TOP, 40, 50))
	out.append(_plight("lamp_moon", "Moon Lamp", MAP_W - 100, 260, 140))
	out.append(_pnpc(
		str(profile.get("npc_id", "npc_shop")),
		str(profile.get("keeper_name", "Keeper")),
		MAP_W * 0.5,
		float(profile.get("npc_y", FLOOR_TOP - 40)),
		profile.get("lines", [])
	))
	return out


static func _p(id: String, kind: String, name: String, x: float, y: float, w: float, h: float) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"name": name,
		"x": x,
		"y": y,
		"w": w,
		"h": h,
		"anchor": PieceSpecs.anchor(kind),
		"blocks_light": PieceSpecs.default_blocks_light(kind),
		"layer": PieceSpecs.default_draw_layer(kind),
		"builtin": true,
	}


static func _pplat(id: String, name: String, x: float, y: float, w: float, h: float, motion: Dictionary) -> Dictionary:
	var d := _p(id, "prop_platform", name, x, y, w, h)
	for key in motion.keys():
		d[key] = motion[key]
	return d


static func _plight(id: String, name: String, x: float, y: float, radius: float) -> Dictionary:
	return {
		"id": id,
		"kind": "light",
		"name": name,
		"x": x,
		"y": y,
		"w": 28,
		"h": 36,
		"radius": radius,
		"intensity": 1.0,
		"anchor": "center",
		"blocks_light": false,
		"layer": PieceSpecs.default_draw_layer("light"),
		"builtin": true,
		"pushable": false,
	}


static func _pnpc(id: String, name: String, x: float, y: float, lines: Variant) -> Dictionary:
	var packed := HouseProfiles.lines_to_packed(lines)
	var arr: Array = []
	for s in packed:
		arr.append(s)
	return {
		"id": id,
		"kind": "prop_npc",
		"name": name,
		"x": x,
		"y": y,
		"w": 28,
		"h": 48,
		"anchor": "bottom",
		"blocks_light": false,
		"layer": PieceSpecs.default_draw_layer("prop_npc"),
		"builtin": true,
		"lines": arr,
	}
