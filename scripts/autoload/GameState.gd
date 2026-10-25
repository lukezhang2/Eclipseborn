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

var is_paused: bool = false
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
	}
	needs_intro_cutscene = true
	intro_cutscene_playing = false
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)
	currency_changed.emit(currency)


func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	var first := not currency_hud_unlocked
	currency += amount
	if first:
		currency_hud_unlocked = true
		currency_hud_reveal.emit()
	currency_changed.emit(currency)


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
	get_tree().change_scene_to_file(scene_path)


func apply_light_exposure(dt: float, kind: LightKind) -> void:
	if is_paused:
		return
	match kind:
		LightKind.MOON, LightKind.CRIMSON:
			_refill_shade(dt)
			return
		_:
			pass

	var drain := SHADE_DRAIN_HEARTH
	var burn := HEALTH_BURN_HEARTH
	if kind == LightKind.SUNSHAFT:
		drain = SHADE_DRAIN_SUNSHAFT
		burn = HEALTH_BURN_SUNSHAFT

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
	died.emit()
	# Soft respawn at checkpoint.
	get_tree().create_timer(0.6).timeout.connect(_respawn, CONNECT_ONE_SHOT)


func _respawn() -> void:
	health = max_health
	shade = 1.0
	health_changed.emit(health, max_health)
	shade_changed.emit(shade)
	if player and is_instance_valid(player):
		player.global_position = checkpoint_position
	respawned.emit()
