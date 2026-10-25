extends Node
## Global run state: health, shade, abilities, pause, zone discovery.

signal health_changed(current: int, maximum: int)
signal shade_changed(ratio: float)
signal currency_changed(amount: int)
signal currency_hud_reveal
signal died
signal respawned
signal ability_unlocked(ability_id: String)
signal room_entered(zone_id: String, room_id: String)
signal pause_changed(paused: bool)

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
## zone_id -> Array of room_id strings discovered
var discovered_rooms: Dictionary = {}
## Breakable ids already destroyed (persist across load).
var broken_ids: Array = []
## One-time permanent pickups (shadow crystals, etc.) — never respawn.
var collected_ids: Array = []

var currency: int = 0
var currency_hud_unlocked: bool = false
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
	return Time.get_ticks_msec() >= _interact_lock_until_msec


func _ready() -> void:
	discovered_rooms = {
		"cursed_cottage": [],
		"lantern_village": [],
		"clockwork_tower": [],
	}


func _process(delta: float) -> void:
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
	shop_stock = {}
	has_double_jump = false
	has_shadow_grip = false
	has_shade_dash = false
	has_gear_sense = false
	has_reflect = false
	has_snuff = false
	checkpoint_path = ""
	checkpoint_position = Vector2.ZERO
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
	needs_intro_cutscene = true
	intro_cutscene_playing = false
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)
	currency_changed.emit(currency)


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


func set_checkpoint(pos: Vector2, path: String = "") -> void:
	checkpoint_position = pos
	last_position = pos
	checkpoint_path = path
	health = max_health
	shade = 1.0
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)


func activate_checkpoint(id: String, zone: String, pos: Vector2, label: String = "") -> void:
	set_checkpoint(pos, id)
	var entry := {
		"id": id if id != "" else "cp_%d" % int(pos.x),
		"zone": zone if zone != "" else current_zone_id,
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
	checkpoint_position = pos
	checkpoint_path = str(entry.get("id", ""))
	last_position = pos
	current_zone_id = zone
	var scene_path := SaveManager.scene_for_zone(zone)
	var label := str(entry.get("name", "Rest"))
	change_zone(scene_path, "Traveling to %s…" % label, pos)


## Prefer this over raw change_scene_to_file so the gear fade always plays.
func change_zone(scene_path: String, caption: String = "", spawn: Vector2 = Vector2.ZERO) -> void:
	if spawn != Vector2.ZERO:
		pending_spawn = spawn
		last_position = spawn
	lock_interact(1.25)
	ZoneTransition.go(get_tree(), scene_path, caption if caption != "" else "…")


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
	if player and is_instance_valid(player) and player.has_method("play_death"):
		player.play_death()
	var tree := get_tree()
	if tree == null:
		_respawn()
		return
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
	await tree.create_timer(0.2).timeout
	_respawn()
	if is_instance_valid(dim):
		var tw2 := tree.create_tween()
		tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(dim, "color:a", 0.0, 0.55)
		await tw2.finished
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
	## Prefer the last rested hearth — never the continue/logout position alone.
	if checkpoint_position != Vector2.ZERO:
		return checkpoint_position
	if checkpoint_path != "":
		for raw in activated_checkpoints:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = raw
			if str(e.get("id", "")) == checkpoint_path:
				var p := Vector2(float(e.get("x", 0.0)), float(e.get("y", 0.0)))
				if p != Vector2.ZERO:
					checkpoint_position = p
					return p
	if player and is_instance_valid(player):
		return (player as Node2D).global_position
	return last_position
