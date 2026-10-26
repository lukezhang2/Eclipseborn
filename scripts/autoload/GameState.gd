extends Node
## Global run state: health, shade, abilities, pause, zone discovery.

signal health_changed(current: int, maximum: int)
signal shade_changed(ratio: float)
signal currency_changed(amount: int)
signal currency_hud_reveal
signal inventory_changed(items: Dictionary)
signal equipment_changed(slots: Array)
signal died
signal respawned
signal ability_unlocked(ability_id: String)
signal room_entered(zone_id: String, room_id: String)
signal pause_changed(paused: bool)

const ACCESSORY_SLOT_COUNT := 3

const SHADE_DRAIN_HEARTH := 1.0 / 1.5
const SHADE_DRAIN_SUNSHAFT := 1.0 / 0.75
const SHADE_REFILL_PER_SEC := 1.0
const HEALTH_BURN_HEARTH := 100.0
const HEALTH_BURN_SUNSHAFT := 200.0
const SHADE_HEART_BONUS := 25

var health: int = 100
var max_health: int = 100
var shade: float = 1.0
var umbra: float = 0.0
var has_double_jump: bool = false
var has_shadow_grip: bool = false
var has_shade_dash: bool = false
var has_gear_sense: bool = false
var has_reflect: bool = false
var has_snuff: bool = false

var checkpoint_path: String = ""
var checkpoint_position: Vector2 = Vector2.ZERO
## Zone the active rest hearth belongs to — death must not snap into another zone's coords.
var checkpoint_zone_id: String = ""
## Activated rest hearths for fast travel: [{id, zone, x, y, name}, ...]
var activated_checkpoints: Array = []
## Live position written on exit / autosave (may differ from checkpoint).
var last_position: Vector2 = Vector2.ZERO
## One-shot spawn used by zone transitions (hatch → village). Survives autosave capture.
var pending_spawn: Vector2 = Vector2.ZERO
## Editor playtest: return here with Exit Playtest instead of treating as a real run.
var editor_playtesting: bool = false
var editor_playtest_zone: String = ""
var current_zone_id: String = "cursed_cottage"
var current_room_id: String = "hall"
## Bumped to cancel an in-flight death fade when changing zones mid-sequence.
var _death_seq: int = 0
## zone_id -> Array of room_id strings discovered
var discovered_rooms: Dictionary = {}
## World cells the camera has actually framed, per zone. Terraria-style map reveal.
const MAP_CELL := 32
const _MAP_BIAS := 100000
var map_seen: Dictionary = {}
var map_seen_rev: int = 0
## Breakable ids already destroyed (persist across load).
var broken_ids: Array = []
## One-time permanent pickups (shadow crystals, etc.) — never respawn.
var collected_ids: Array = []

var currency: int = 0
var currency_hud_unlocked: bool = false
## Bag counts for useable supplies: item_id -> int.
var inventory: Dictionary = {}
## Equipped accessory item ids (length ACCESSORY_SLOT_COUNT); "" = empty.
var equipment_slots: Array = ["", "", ""]
## Remaining shop stock overrides: "zone/npc_id/item_id" -> int (−1 infinite, else remaining).
var shop_stock: Dictionary = {}

var is_paused: bool = false
## True between death and respawn — suppresses land/walk spam while the body settles.
var is_dead: bool = false
var single_player: bool = true
var player: Node2D = null
## True until the first-spawn cutscene finishes on a new save.
var needs_intro_cutscene: bool = true
var intro_cutscene_playing: bool = false
## Pushable crate horizontal limits (set by each level).
var map_min_x: float = 40.0
var map_max_x: float = 3900.0
var _regen_accum: float = 0.0
## Blocks Interact (and walk-exit) briefly after zone fades so held E can't bounce.
var _interact_lock_until_msec: int = 0

enum LightKind { HEARTH, CANDLE, MOON, CRIMSON, SUNSHAFT }


func lock_interact(seconds: float = 0.85) -> void:
	_interact_lock_until_msec = Time.get_ticks_msec() + int(maxf(0.0, seconds) * 1000.0)


func can_interact() -> bool:
	if is_dead or intro_cutscene_playing:
		return false
	return Time.get_ticks_msec() >= _interact_lock_until_msec


func reveal_screen() -> void:
	## Stamp the live camera frame into the zone map.
	if player == null or not is_instance_valid(player):
		return
	if current_zone_id == "":
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	var vp := player.get_viewport()
	if vp == null:
		return
	var view_size := vp.get_visible_rect().size
	var zoom := cam.zoom if cam != null else Vector2.ONE
	if zoom.x <= 0.01 or zoom.y <= 0.01:
		zoom = Vector2.ONE
	var center := cam.get_screen_center_position() if cam != null else player.global_position
	var world_size := Vector2(view_size.x / zoom.x, view_size.y / zoom.y)
	reveal_rect(current_zone_id, Rect2(center - world_size * 0.5, world_size))


func reveal_rect(zone_id: String, world_rect: Rect2) -> void:
	if zone_id == "" or world_rect.size.x <= 1.0 or world_rect.size.y <= 1.0:
		return
	var cells: Dictionary = map_seen.get(zone_id, {})
	var x0 := int(floor(world_rect.position.x / float(MAP_CELL)))
	var y0 := int(floor(world_rect.position.y / float(MAP_CELL)))
	var x1 := int(floor((world_rect.end.x - 0.001) / float(MAP_CELL)))
	var y1 := int(floor((world_rect.end.y - 0.001) / float(MAP_CELL)))
	var added := false
	for iy in range(y0, y1 + 1):
		for ix in range(x0, x1 + 1):
			var key := map_pack(ix, iy)
			if not cells.has(key):
				cells[key] = true
				added = true
	if added:
		map_seen[zone_id] = cells
		map_seen_rev += 1


func map_pack(ix: int, iy: int) -> int:
	return (ix + _MAP_BIAS) * 1000000 + (iy + _MAP_BIAS)


func map_cell_seen(zone_id: String, world: Vector2) -> bool:
	var cells: Dictionary = map_seen.get(zone_id, {})
	if cells.is_empty():
		return false
	var ix := int(floor(world.x / float(MAP_CELL)))
	var iy := int(floor(world.y / float(MAP_CELL)))
	return cells.has(map_pack(ix, iy))


func map_hidden_spans(zone_id: String, bounds: Rect2) -> Array:
	## Horizontal runs of world cells the camera has not framed, clipped to bounds.
	var hidden: Array = []
	if bounds.size.x < 1.0 or bounds.size.y < 1.0:
		return hidden
	var cells: Dictionary = map_seen.get(zone_id, {})
	var cell := float(MAP_CELL)
	var x0 := int(floor(bounds.position.x / cell))
	var y0 := int(floor(bounds.position.y / cell))
	var x1 := int(floor((bounds.end.x - 0.001) / cell))
	var y1 := int(floor((bounds.end.y - 0.001) / cell))
	for iy in range(y0, y1 + 1):
		var ix := x0
		while ix <= x1:
			if cells.has(map_pack(ix, iy)):
				ix += 1
				continue
			var start := ix
			while ix <= x1 and not cells.has(map_pack(ix, iy)):
				ix += 1
			var span := Rect2(float(start) * cell, float(iy) * cell, float(ix - start) * cell, cell)
			var hit := span.intersection(bounds)
			if hit.size.x >= 0.5 and hit.size.y >= 0.5:
				hidden.append(hit)
	return hidden


func _ready() -> void:
	discovered_rooms = {
		"cursed_cottage": [],
		"lantern_village": [],
		"clockwork_tower": [],
	}


func _process(delta: float) -> void:
	reveal_screen()
	if is_paused or intro_cutscene_playing:
		return
	# Natural regen: 1 HP / second while below max (paused while burning in light after shade empty).
	if health <= 0 or health >= max_health:
		return
	if player and is_instance_valid(player) and player._in_vulnerable_light and shade <= 0.0:
		return
	_regen_accum += delta
	if _regen_accum >= 1.0:
		_regen_accum = 0.0
		heal(1)


func reset_run() -> void:
	health = 100
	max_health = 100
	shade = 1.0
	umbra = 0.0
	currency = 0
	currency_hud_unlocked = false
	inventory = {}
	equipment_slots = ["", "", ""]
	shop_stock = {}
	has_double_jump = false
	has_shadow_grip = false
	has_shade_dash = false
	has_gear_sense = false
	has_reflect = false
	has_snuff = false
	checkpoint_path = ""
	checkpoint_position = Vector2.ZERO
	checkpoint_zone_id = ""
	activated_checkpoints = []
	last_position = Vector2.ZERO
	current_zone_id = "cursed_cottage"
	current_room_id = "hall"
	broken_ids = []
	collected_ids = []
	discovered_rooms = {
		"cursed_cottage": [],
		"lantern_village": [],
		"clockwork_tower": [],
	}
	map_seen = {}
	map_seen_rev = 0
	needs_intro_cutscene = true
	intro_cutscene_playing = false
	is_dead = false
	_death_seq += 1
	_clear_death_fade()
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)
	currency_changed.emit(currency)
	inventory_changed.emit(inventory)
	equipment_changed.emit(equipment_slots)


## True after the Wickwright defeat cutscene has run (opens village descent hole).
func wickwright_defeated() -> bool:
	return is_collected("wickwright_defeated")


## Shadow crystal *piece* (tower reward) — unlocks double jump; separate from shade-heart fragments.
func collect_crystal_piece(pickup_id: String) -> bool:
	if pickup_id == "" or is_collected(pickup_id):
		return false
	mark_collected(pickup_id)
	unlock_ability("double_jump")
	SaveManager.autosave()
	return true


func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	var first := not currency_hud_unlocked
	currency += amount
	if first:
		currency_hud_unlocked = true
		currency_hud_reveal.emit()
	currency_changed.emit(currency)


func spend_currency(amount: int) -> bool:
	if amount <= 0:
		return true
	if currency < amount:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true


func get_inventory_count(item_id: String) -> int:
	if item_id == "" or not inventory.has(item_id):
		return 0
	return maxi(0, int(inventory[item_id]))


func add_inventory_item(item_id: String, amount: int = 1) -> void:
	if item_id == "" or amount <= 0:
		return
	inventory[item_id] = get_inventory_count(item_id) + amount
	inventory_changed.emit(inventory)


func use_inventory_item(item_id: String) -> bool:
	## Consumes one supply from the bag and applies its effect.
	if get_inventory_count(item_id) <= 0:
		return false
	var it := ShopCatalog.get_item(item_id)
	if str(it.get("kind", "")) != "consumable":
		return false
	match item_id:
		"heal_tonic":
			if health >= max_health:
				return false
			heal(40)
		"shade_vial":
			if shade >= 0.999:
				return false
			shade = 1.0
			shade_changed.emit(shade)
		_:
			return false
	var left := get_inventory_count(item_id) - 1
	if left <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = left
	inventory_changed.emit(inventory)
	return true


func _normalize_equipment_slots(raw: Variant) -> Array:
	var out: Array = ["", "", ""]
	if typeof(raw) != TYPE_ARRAY:
		return out
	for i in ACCESSORY_SLOT_COUNT:
		if i < raw.size():
			out[i] = str(raw[i])
	return out


func is_accessory_equipped(item_id: String) -> bool:
	if item_id == "":
		return false
	return equipment_slots.has(item_id)


func equip_accessory(item_id: String, slot: int = -1) -> bool:
	## Place an owned ability into an accessory slot. Returns false if no room / invalid.
	if item_id == "" or not ShopCatalog.owns_ability(item_id):
		return false
	if is_accessory_equipped(item_id):
		return false
	equipment_slots = _normalize_equipment_slots(equipment_slots)
	var target := slot
	if target < 0 or target >= ACCESSORY_SLOT_COUNT:
		target = -1
		for i in ACCESSORY_SLOT_COUNT:
			if str(equipment_slots[i]) == "":
				target = i
				break
	if target < 0:
		return false
	if str(equipment_slots[target]) != "":
		return false
	equipment_slots[target] = item_id
	equipment_changed.emit(equipment_slots)
	return true


func unequip_accessory_slot(slot: int) -> bool:
	equipment_slots = _normalize_equipment_slots(equipment_slots)
	if slot < 0 or slot >= ACCESSORY_SLOT_COUNT:
		return false
	if str(equipment_slots[slot]) == "":
		return false
	equipment_slots[slot] = ""
	equipment_changed.emit(equipment_slots)
	return true


func unequip_accessory(item_id: String) -> bool:
	equipment_slots = _normalize_equipment_slots(equipment_slots)
	for i in ACCESSORY_SLOT_COUNT:
		if str(equipment_slots[i]) == item_id:
			equipment_slots[i] = ""
			equipment_changed.emit(equipment_slots)
			return true
	return false


func shop_stock_key(shop_key: String, item_id: String) -> String:
	return "%s/%s" % [shop_key, item_id]


func get_shop_stock(shop_key: String, item_id: String, base_stock: int) -> int:
	## base_stock −1 = infinite. Runtime overrides only apply to finite stock.
	if base_stock < 0:
		return -1
	var key := shop_stock_key(shop_key, item_id)
	if shop_stock.has(key):
		return maxi(0, int(shop_stock[key]))
	return maxi(0, base_stock)


func set_shop_stock(shop_key: String, item_id: String, remaining: int) -> void:
	var key := shop_stock_key(shop_key, item_id)
	if remaining < 0:
		shop_stock.erase(key)
		return
	shop_stock[key] = remaining


func mark_broken(id: String) -> void:
	if id == "" or broken_ids.has(id):
		return
	broken_ids.append(id)


func is_broken(id: String) -> bool:
	return id != "" and broken_ids.has(id)


func mark_collected(id: String) -> void:
	if id == "" or collected_ids.has(id):
		return
	collected_ids.append(id)


func is_collected(id: String) -> bool:
	return id != "" and collected_ids.has(id)


## Permanent shade-heart upgrade from a shadow crystal. Returns false if already taken.
func collect_shadow_crystal(pickup_id: String) -> bool:
	if pickup_id == "" or is_collected(pickup_id):
		return false
	mark_collected(pickup_id)
	add_shade_heart()
	SaveManager.autosave()
	return true


func set_paused(value: bool) -> void:
	if not single_player and value:
		# Co-op: menus do not freeze the world.
		is_paused = false
		get_tree().paused = false
		pause_changed.emit(false)
		return
	is_paused = value
	get_tree().paused = value
	if value:
		AudioManager.stop_all_burns()
	pause_changed.emit(value)


func unlock_ability(ability_id: String) -> void:
	match ability_id:
		"double_jump":
			has_double_jump = true
		"shadow_grip":
			has_shadow_grip = true
		"shade_dash":
			has_shade_dash = true
		"gear_sense":
			has_gear_sense = true
		"reflect":
			has_reflect = true
		"snuff":
			has_snuff = true
	ability_unlocked.emit(ability_id)


func enter_room(zone_id: String, room_id: String) -> void:
	current_zone_id = zone_id
	current_room_id = room_id
	if not discovered_rooms.has(zone_id):
		discovered_rooms[zone_id] = []
	var rooms: Array = discovered_rooms[zone_id]
	if not rooms.has(room_id):
		rooms.append(room_id)
		discovered_rooms[zone_id] = rooms
	room_entered.emit(zone_id, room_id)


func set_checkpoint(pos: Vector2, path: String = "", zone: String = "", heal_full: bool = true) -> void:
	checkpoint_position = pos
	last_position = pos
	checkpoint_path = path
	checkpoint_zone_id = zone if zone != "" else current_zone_id
	if heal_full:
		health = max_health
		shade = 1.0
		health_changed.emit(health, max_health)
		shade_changed.emit(shade)


func activate_checkpoint(id: String, zone: String, pos: Vector2, label: String = "") -> void:
	var z := zone if zone != "" else current_zone_id
	set_checkpoint(pos, id, z)
	var entry := {
		"id": id if id != "" else "cp_%d" % int(pos.x),
		"zone": z,
		"x": pos.x,
		"y": pos.y,
		"name": label if label != "" else (id if id != "" else "Rest"),
	}
	var found := false
	for i in activated_checkpoints.size():
		var raw = activated_checkpoints[i]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		if str(e.get("id", "")) == entry.id and str(e.get("zone", "")) == entry.zone:
			activated_checkpoints[i] = entry
			found = true
			break
	if not found:
		activated_checkpoints.append(entry)
	## Always flush to disk so exit/reload keeps hearths for fast travel.
	SaveManager.autosave()


func is_checkpoint_activated(id: String, zone: String = "") -> bool:
	var z := zone if zone != "" else current_zone_id
	for raw in activated_checkpoints:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = raw
		if str(e.get("id", "")) == id and str(e.get("zone", "")) == z:
			return true
	return false


func get_activated_checkpoints() -> Array:
	var out: Array = []
	for raw in activated_checkpoints:
		if typeof(raw) == TYPE_DICTIONARY:
			out.append((raw as Dictionary).duplicate(true))
	return out


func travel_to_checkpoint(entry: Dictionary) -> void:
	var zone := str(entry.get("zone", current_zone_id))
	var pos := Vector2(float(entry.get("x", 0)), float(entry.get("y", 0)))
	pending_spawn = pos
	set_checkpoint(pos, str(entry.get("id", "")), zone)
	current_zone_id = zone
	var scene_path := SaveManager.scene_for_zone(zone)
	var label := str(entry.get("name", "Rest"))
	change_zone(scene_path, "Traveling to %s…" % label, pos)


## Prefer this over raw change_scene_to_file so the gear fade always plays.
func change_zone(scene_path: String, caption: String = "", spawn: Vector2 = Vector2.ZERO) -> void:
	## Leaving a zone must not carry death fades / cutscene locks into the next room.
	clear_transient_zone_state()
	if spawn != Vector2.ZERO:
		pending_spawn = spawn
		last_position = spawn
	lock_interact(1.25)
	ZoneTransition.go(get_tree(), scene_path, caption if caption != "" else "…")


## Call before any scene change so death/cutscene flags don't leak (tower → village, etc.).
func clear_transient_zone_state() -> void:
	_death_seq += 1
	is_dead = false
	intro_cutscene_playing = false
	_clear_death_fade()
	AudioManager.stop_all_burns()


func _clear_death_fade() -> void:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var fade := tree.root.get_node_or_null("DeathFade")
	if fade:
		fade.queue_free()


func apply_light_exposure(dt: float, kind: LightKind, intensity: float = 1.0) -> void:
	if is_paused:
		return
	match kind:
		LightKind.MOON, LightKind.CRIMSON:
			_refill_shade(dt)
			return
		_:
			pass

	var scale := clampf(intensity, 0.15, 3.0)
	var drain := SHADE_DRAIN_HEARTH * scale
	var burn := HEALTH_BURN_HEARTH * scale
	if kind == LightKind.SUNSHAFT:
		drain = SHADE_DRAIN_SUNSHAFT * scale
		burn = HEALTH_BURN_SUNSHAFT * scale

	if shade > 0.0:
		shade = maxf(0.0, shade - drain * dt)
		shade_changed.emit(shade)
		return

	# Shade empty: health burns fast.
	var next := float(health) - burn * dt
	health = maxi(0, int(floor(next)))
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()


func refill_shade_safe(dt: float) -> void:
	_refill_shade(dt)


func _refill_shade(dt: float) -> void:
	if shade >= 1.0:
		return
	shade = minf(1.0, shade + SHADE_REFILL_PER_SEC * dt)
	shade_changed.emit(shade)


func take_damage(amount: int) -> void:
	# Enemy hits skip the shade bar.
	if amount <= 0:
		return
	AudioManager.play_hurt()
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func add_shade_heart() -> void:
	max_health += SHADE_HEART_BONUS
	health = max_health
	health_changed.emit(health, max_health)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.stop_all_burns()
	died.emit()
	_run_death_sequence()


func _run_death_sequence() -> void:
	## Death pose + screen fade, then soft respawn at the last rest hearth.
	var seq := _death_seq
	if player and is_instance_valid(player) and player.has_method("play_death"):
		player.play_death()
	var tree := get_tree()
	if tree == null:
		if seq == _death_seq:
			_respawn()
		return
	_clear_death_fade()
	var layer := CanvasLayer.new()
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.name = "DeathFade"
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.03, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	tree.root.add_child(layer)
	var tw := tree.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(dim, "color:a", 1.0, 0.55)
	await tw.finished
	if seq != _death_seq:
		if is_instance_valid(layer):
			layer.queue_free()
		return
	await tree.create_timer(0.2).timeout
	if seq != _death_seq:
		if is_instance_valid(layer):
			layer.queue_free()
		return
	_respawn()
	if is_instance_valid(dim):
		var tw2 := tree.create_tween()
		tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(dim, "color:a", 0.0, 0.55)
		await tw2.finished
	if seq != _death_seq:
		if is_instance_valid(layer):
			layer.queue_free()
		return
	if is_instance_valid(layer):
		layer.queue_free()


func _respawn() -> void:
	health = max_health
	shade = 1.0
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)
	var dest := _death_respawn_position()
	if player and is_instance_valid(player):
		player.global_position = dest
		if player.has_method("notify_respawned"):
			player.notify_respawned()
	is_dead = false
	respawned.emit()


func _death_respawn_position() -> Vector2:
	## Only use the active hearth if it belongs to this zone (leaving the tower
	## must not teleport you to lobby Y coords while standing in the village).
	if checkpoint_position != Vector2.ZERO and checkpoint_zone_id == current_zone_id:
		return checkpoint_position
	if checkpoint_path != "":
		for raw in activated_checkpoints:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = raw
			if str(e.get("id", "")) == checkpoint_path and str(e.get("zone", "")) == current_zone_id:
				var p := Vector2(float(e.get("x", 0.0)), float(e.get("y", 0.0)))
				if p != Vector2.ZERO:
					checkpoint_position = p
					checkpoint_zone_id = current_zone_id
					return p
	## Most recently activated hearth in this zone.
	for i in range(activated_checkpoints.size() - 1, -1, -1):
		var raw2 = activated_checkpoints[i]
		if typeof(raw2) != TYPE_DICTIONARY:
			continue
		var e2: Dictionary = raw2
		if str(e2.get("zone", "")) != current_zone_id:
			continue
		var p2 := Vector2(float(e2.get("x", 0.0)), float(e2.get("y", 0.0)))
		if p2 != Vector2.ZERO:
			checkpoint_position = p2
			checkpoint_zone_id = current_zone_id
			checkpoint_path = str(e2.get("id", checkpoint_path))
			return p2
	if player and is_instance_valid(player):
		return (player as Node2D).global_position
	return last_position
