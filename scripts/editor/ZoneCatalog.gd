extends RefCounted
class_name ZoneCatalog
## Named props that make up each zone (mirrors the live room scripts).
## Sizes/anchors come from PieceSpecs — keep in sync with CursedCottage / LanternVillage /
## HouseInterior / ClockworkTowerZone.
## See docs/LEVEL_EDITOR.md for the JSON schema.


static func zone_ids() -> PackedStringArray:
	return PackedStringArray([
		"cursed_cottage",
		"lantern_village",
		"clockwork_tower",
		"house_keep",
		"house_gear",
		"house_inn",
	])


static func pieces_for(zone_id: String) -> Array:
	match zone_id:
		"lantern_village":
			return _village()
		"clockwork_tower":
			return _tower()
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
	out.append(_p("valve_1", "prop_valve", "Valve", 220, 308, 24, 24))
	out.append(_p("window_1", "prop_window", "Window 1", 180, 318, 48, 56))
	out.append(_p("window_2", "prop_window", "Window 2", 980, 318, 48, 56))
	out.append(_p("window_3", "prop_window", "Window 3", 1780, 318, 48, 56))
	out.append(_p("window_4", "prop_window", "Window 4", 2580, 318, 52, 56))
	out.append(_p("window_5", "prop_window", "Window 5", 3380, 318, 48, 56))
	out.append(_p("bench_1", "prop_bench", "Bench", 300, FLOOR_TOP - 4, 60, 20))
	out.append(_p("vent_1", "prop_vent", "Steam Vent", 860, FLOOR_TOP - 4, 36, 16))
	out.append(_p("decor_crate_1", "prop_crate", "Decor Crate 1", 520, FLOOR_TOP - 14, 36, 28))
	out.append(_p("decor_crate_2", "prop_crate", "Decor Crate 2", 2920, FLOOR_TOP - 15, 40, 30))
	## Pushable crates: 58×58 sitting on FLOOR_TOP (center ≈ FLOOR_TOP - 29).
	out.append(_p("box_push_1", "crate", "Pushable Crate (lamp room)", 1222.13659667969, 452.331481933594, crate.x, crate.y))
	out.append(_p("box_pull_1", "crate", "Pushable Crate (pull puzzle)", 1901.41931152344, 452.577880859375, crate.x, crate.y))
	out.append(_p("wall_tall", "wall", "Tall Pull Wall", 2080, FLOOR_TOP - 50, 32, 100))
	out.append(_p("wall_backstop", "wall", "Pull Backstop", 1854.39147949219, 457.149475097656, 33.0551719665527, 49.701171875))
	out.append(_p("platform_crate_room", "floor", "Cover Platform", 1120, FLOOR_TOP - 100, 180, 22))
	out.append(_p("ledge_1", "floor", "Jump Ledge 1", 2700, FLOOR_TOP - 55, 140, 22))
	out.append(_p("ledge_2", "floor", "Jump Ledge 2", 2840, FLOOR_TOP - 100, 100, 22))
	out.append(_plight("lamp_crate", "Hearth Lamp (crate room)", 1120, FLOOR_TOP - 170, 240))
	out.append(_plight("lamp_moon", "Moon Lamp", 400, 258, 140))
	out.append(_p("jar_1", "prop_breakable", "Glowing Jar 1", 420, FLOOR_TOP - 18, 28, 36))
	out.append(_p("jar_2", "prop_breakable", "Glowing Jar 2", 1480, FLOOR_TOP - 18, 28, 36))
	out.append(_p("jar_3", "prop_breakable", "Glowing Jar 3", 2400, FLOOR_TOP - 18, 28, 36))
	out.append(_p("chest_1", "prop_breakable", "Glowing Chest", 3100, FLOOR_TOP - 16, 40, 32))
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
	out.append(_plight("lantern_1", "Hanging Lantern 1", 280, 160, 120))
	out.append(_plight("lantern_2", "Hanging Lantern 2", 720, 160, 120))
	out.append(_plight("lantern_3", "Hanging Lantern 3", 1600, 160, 120))
	out.append(_p("window_1", "prop_window", "Window", 360, 220, 44, 60))
	out.append(_p("bench_1", "prop_bench", "Bench", 455, FLOOR_TOP, 60, 20))
	out.append(_p("vent_1", "prop_vent", "Steam Vent", 1053, FLOOR_TOP, 36, 16))
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
	out.append(_pplat("platform_gear_1", "Moving Platform 1", 1278, 414, 140, 20, {
		"move_amplitude": 200.0, "move_speed": 0.65, "vertical": false,
		"path_y_amplitude": 0.0, "rotate_while_moving": true, "rotate_speed": 1.0,
		"rotate_platform": false, "with_gear": true,
		"gear_dx": -94.0, "gear_dy": -110.0, "gear_radius": 55.0,
	}))
	out.append(_pplat("platform_gear_2", "Moving Platform 2", 2305.59130859375, FLOOR_TOP - 130, 120, 20, {
		"move_amplitude": 70.0, "move_speed": 0.55, "vertical": true,
		"path_y_amplitude": 0.0, "rotate_while_moving": true, "rotate_speed": 1.2,
		"rotate_platform": false, "with_gear": true,
		"gear_dx": -100.0, "gear_dy": -110.0, "gear_radius": 70.0,
	}))
	out.append(_p("bg_gear_1", "prop_bg_gear", "BG Gear 1", 1450, 300, 110, 110))
	out.append(_p("bg_gear_2", "prop_bg_gear", "BG Gear 2", 2200, 260, 140, 140))
	out.append(_p("enemy_1", "prop_enemy", "Wander Enemy 1", 1500, FLOOR_TOP - 20, 28, 36))
	out.append(_p("enemy_2", "prop_enemy", "Wander Enemy 2", 2050, FLOOR_TOP - 20, 28, 36))
	out.append(_p("tower", "prop_tower", "Clockwork Tower", MAP_W - 200, FLOOR_TOP, 160, 280))
	out.append(_p("shade_heart", "prop_pickup", "Shade Heart", 2407.53247070312, 256, 28, 28))
	out.append(_p("checkpoint_gate", "prop_checkpoint", "Checkpoint (village gate) — the … hearth", 200, FLOOR_TOP, 56, 24))
	return out


static func _tower() -> Array:
	## Mirrors ClockworkTowerZone constants (JUMP_REACH_Y=52, FLOOR_H=36).
	const MAP_W := 1100.0
	const SHAFT_L := 80.0
	const SHAFT_R := 780.0
	const FLOOR_H := 36.0
	const JUMP_REACH_Y := 52.0
	const LEDGE_W := 140.0
	const LOBBY_FLOOR := 2680.0
	const LOBBY_TOP := LOBBY_FLOOR - FLOOR_H * 0.5
	const ANTECHAMBER_FLOOR := 620.0
	const ANTECHAMBER_TOP := ANTECHAMBER_FLOOR - FLOOR_H * 0.5
	const ARENA_FLOOR := 360.0
	const ARENA_TOP := ARENA_FLOOR - FLOOR_H * 0.5
	const ROOF_TOP := 20.0
	var out: Array = []
	var mid_y := (ROOF_TOP + LOBBY_FLOOR) * 0.5
	var wall_h := LOBBY_FLOOR - ROOF_TOP + 120.0
	out.append(_p("floor_lobby", "floor", "Lobby Floor", (SHAFT_L + SHAFT_R) * 0.5, LOBBY_FLOOR, SHAFT_R - SHAFT_L + 80.0, FLOOR_H))
	out.append(_p("border_left", "wall", "Tower Wall Left", 20, mid_y, 40, wall_h))
	out.append(_p("border_right", "wall", "Tower Wall Right", MAP_W - 20, mid_y, 40, wall_h))
	out.append(_p("pipe_ceiling", "prop_pipe", "Ceiling Rail", MAP_W * 0.5, ROOF_TOP + 30, MAP_W - 120, 12))
	out.append(_p("checkpoint_lobby", "prop_checkpoint", "Tower Lobby", 260, LOBBY_TOP, 56, 24))
	out.append(_plight("lobby_lamp", "Lobby Lamp", 420, LOBBY_TOP - 120, 180))
	out.append(_p("vent_lobby", "prop_vent", "Lobby Steam Vent", 520, LOBBY_TOP, 36, 16))
	out.append(_p("bench_lobby", "prop_bench", "Lobby Bench", 340, LOBBY_TOP, 60, 20))
	out.append(_p("exit_village", "prop_exit", "Village Door", 110, LOBBY_TOP - 8, 40, 50))

	## Main shaft climb from lobby (10 ledges).
	var y := LOBBY_TOP - 20.0
	for i in 10:
		y -= JUMP_REACH_Y
		var x := 220.0 if i % 2 == 0 else 560.0
		out.append(_p("ledge_shaft_%d" % (i + 1), "floor", "Shaft Ledge %d" % (i + 1), x, y + FLOOR_H * 0.5, LEDGE_W, FLOOR_H))
	out.append(_p("floor_shaft_landing", "floor", "Shaft Landing", 400, y - 10.0 + FLOOR_H * 0.5, 420, FLOOR_H))
	out.append(_p("ledge_workshop_door", "floor", "Workshop Door Ledge", 700, y - JUMP_REACH_Y + FLOOR_H * 0.5, 160, FLOOR_H))
	out.append(_plight("climb_lamp", "Climb Lamp", 400, y - 80, 150))

	## Side workshop.
	var workshop_floor := 2140.0
	out.append(_p("floor_workshop", "floor", "Workshop Floor", 960, workshop_floor, 280, FLOOR_H))
	out.append(_p("bench_workshop", "prop_bench", "Workshop Bench", 940, workshop_floor - FLOOR_H * 0.5, 60, 20))
	out.append(_p("jar_workshop", "prop_breakable", "Workshop Jar", 1020, workshop_floor - FLOOR_H * 0.5 - 8, 28, 36))

	## Pendulum cloister climb (8 ledges from 2124).
	y = 2124.0
	for i in 8:
		y -= JUMP_REACH_Y
		var cx := 240.0 if i % 2 == 0 else 540.0
		out.append(_p("ledge_cloister_%d" % (i + 1), "floor", "Cloister Ledge %d" % (i + 1), cx, y + FLOOR_H * 0.5, LEDGE_W, FLOOR_H))
	out.append(_p("floor_cloister_l", "floor", "Cloister Floor L", 220, y - 8.0 + FLOOR_H * 0.5, 220, FLOOR_H))
	out.append(_p("floor_cloister_r", "floor", "Cloister Floor R", 560, y - 8.0 + FLOOR_H * 0.5, 220, FLOOR_H))
	out.append(_p("ledge_cloister_gap", "floor", "Cloister Gap Ledge", 390, y - JUMP_REACH_Y + FLOOR_H * 0.5, 120, FLOOR_H))
	out.append(_plight("cloister_lamp", "Cloister Lamp", 390, y - JUMP_REACH_Y - 90, 160))
	var csw := _p("cloister_switch", "prop_switch", "Cloister Lever", 160, y - 8.0, 24, 40)
	csw["starts_on"] = true
	csw["target_ids"] = ["cloister_lamp"]
	out.append(csw)

	## Steam flue (10 vent ledges from 1710).
	y = 1710.0
	for i in 10:
		y -= JUMP_REACH_Y
		var fx := 250.0 if i % 2 == 0 else 530.0
		out.append(_p("ledge_flue_%d" % (i + 1), "floor", "Flue Ledge %d" % (i + 1), fx, y + FLOOR_H * 0.5, LEDGE_W, FLOOR_H))
		out.append(_p("vent_flue_%d" % (i + 1), "prop_vent", "Flue Vent %d" % (i + 1), fx, y, 36, 16))
	out.append(_p("ledge_flue_top", "floor", "Flue Top Ledge", 390, y - JUMP_REACH_Y + FLOOR_H * 0.5, 160, FLOOR_H))
	out.append(_plight("flue_lamp", "Flue Floor Lamp", 390, y - JUMP_REACH_Y - 8, 130))
	var fsw := _p("flue_switch", "prop_switch", "Flue Lever", 300, y - JUMP_REACH_Y, 24, 40)
	fsw["starts_on"] = false
	fsw["target_ids"] = ["flue_lamp"]
	out.append(fsw)

	## Ash archive (left wing).
	var archive_floor := 1120.0
	out.append(_p("floor_archive", "floor", "Archive Floor", 160, archive_floor, 260, FLOOR_H))
	out.append(_plight("archive_lamp", "Archive Lamp", 160, archive_floor - 100, 120))
	out.append(_p("jar_archive", "prop_breakable", "Archive Jar", 120, archive_floor - FLOOR_H * 0.5 - 8, 28, 36))

	## Switch gallery (7 climb from 1192).
	y = 1192.0
	for i in 7:
		y -= JUMP_REACH_Y
		var gx := 240.0 if i % 2 == 0 else 540.0
		out.append(_p("ledge_gallery_%d" % (i + 1), "floor", "Gallery Ledge %d" % (i + 1), gx, y + FLOOR_H * 0.5, LEDGE_W, FLOOR_H))
	out.append(_p("floor_gallery", "floor", "Gallery Floor", 400, y - 12.0 + FLOOR_H * 0.5, 560, FLOOR_H))
	var gallery_top := y - 12.0
	out.append(_plight("practice_a", "Practice Lamp A", 260, gallery_top - 8, 100))
	out.append(_plight("practice_b", "Practice Lamp B", 400, gallery_top - 8, 100))
	out.append(_plight("practice_c", "Practice Lamp C", 540, gallery_top - 8, 100))
	for pair in [["practice_sw_a", "practice_a", 220.0, true], ["practice_sw_b", "practice_b", 360.0, false], ["practice_sw_c", "practice_c", 500.0, true]]:
		var psw := _p(str(pair[0]), "prop_switch", "Practice Lever", float(pair[2]), gallery_top, 24, 40)
		psw["starts_on"] = bool(pair[3])
		psw["target_ids"] = [str(pair[1])]
		out.append(psw)

	## Antechamber + arena.
	out.append(_p("floor_antechamber", "floor", "Dial Gate Floor", 400, ANTECHAMBER_FLOOR, 560, FLOOR_H))
	out.append(_p("checkpoint_antechamber", "prop_checkpoint", "Dial Gate", 220, ANTECHAMBER_TOP, 56, 24))
	out.append(_p("floor_arena", "floor", "Dial Arena Floor", 400, ARENA_FLOOR, 620, FLOOR_H))
	out.append(_plight("tower_lamp_a", "Arena Lamp A", 250, ARENA_TOP - 8, 130))
	out.append(_plight("tower_lamp_b", "Arena Lamp B", 400, ARENA_TOP - 8, 130))
	out.append(_plight("tower_lamp_c", "Arena Lamp C", 550, ARENA_TOP - 8, 130))
	var lever_y := ARENA_TOP - 110.0
	out.append(_p("ledge_lever_a", "floor", "Lever Ledge A", 250, lever_y + FLOOR_H * 0.5, 90, FLOOR_H))
	out.append(_p("ledge_lever_b", "floor", "Lever Ledge B", 400, lever_y + FLOOR_H * 0.5, 90, FLOOR_H))
	out.append(_p("ledge_lever_c", "floor", "Lever Ledge C", 550, lever_y + FLOOR_H * 0.5, 90, FLOOR_H))
	for pair2 in [["tower_switch_a", "tower_lamp_a", 250.0, true], ["tower_switch_b", "tower_lamp_b", 400.0, false], ["tower_switch_c", "tower_lamp_c", 550.0, true]]:
		var asw := _p(str(pair2[0]), "prop_switch", "Arena Lever", float(pair2[2]), lever_y, 24, 40)
		asw["starts_on"] = bool(pair2[3])
		asw["target_ids"] = [str(pair2[1])]
		out.append(asw)
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
		float(profile.get("npc_25", FLOOR_TOP - 40)),
		profile.get("lines", []),
		profile.get("shop_items", ShopCatalog.default_shop_stock())
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


static func _pnpc(id: String, name: String, x: float, y: float, lines: Variant, shop_items: Variant = null) -> Dictionary:
	var packed := HouseProfiles.lines_to_packed(lines)
	var arr: Array = []
	for s in packed:
		arr.append(s)
	var stock := ShopCatalog.normalize_shop_items(shop_items)
	if stock.is_empty():
		stock = ShopCatalog.default_shop_stock()
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
		"is_shopkeeper": true,
		"shop_items": stock,
	}
