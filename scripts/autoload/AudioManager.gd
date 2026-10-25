extends Node
## Loads and plays SFX. Footsteps are keyed by floor_sfx meta (default: steel).

## Volume helpers: −25% ≈ −2.5 dB, −45% ≈ −5.2 dB, −90% ≈ −20 dB.
const DB_DOWN_25 := -2.5
const DB_DOWN_45 := -5.2
const DB_DOWN_90 := -20.0

var _attack: AudioStream
var _walk_steel: AudioStream
var _jump: AudioStream
var _land: AudioStream
var _crack: AudioStream
var _gears: AudioStream
var _break: AudioStream
var _currency: AudioStream
var _hurt: AudioStream
var _hit: AudioStream
var _burn_shade: AudioStream
var _burn_health: AudioStream

var _walk_cooldown: float = 0.0
var _hurt_cooldown: float = 0.0
var _hit_cooldown: float = 0.0
var _land_cooldown: float = 0.0
var _players: Array[AudioStreamPlayer] = []
var _burn_shade_player: AudioStreamPlayer
var _burn_health_player: AudioStreamPlayer
var _sfx_bus: String = "Master"
var _web_unlocked: bool = false
var _shade_burning: bool = false
var _health_burning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_sfx_bus()
	_attack = _load("res://assets/sfx/attack.wav")
	## Steel plate footsteps — default bank for all floor_sfx kinds until more exist.
	_walk_steel = _load("res://assets/sfx/walk.wav")
	_jump = _load("res://assets/sfx/jump.wav")
	_land = _load("res://assets/sfx/land.wav")
	_crack = _load("res://assets/sfx/boot_crack.wav")
	_gears = _load("res://assets/sfx/boot_gears.wav")
	_break = _load("res://assets/sfx/break.wav")
	_currency = _load("res://assets/sfx/currency.wav")
	_hurt = _load("res://assets/sfx/hurt.wav")
	_hit = _load("res://assets/sfx/hit.wav")
	_burn_shade = _load_loop("res://assets/sfx/burn_shade.wav")
	_burn_health = _load_loop("res://assets/sfx/burn_health.wav")
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.bus = _sfx_bus
		add_child(p)
		_players.append(p)
	_burn_shade_player = _make_loop_player()
	_burn_health_player = _make_loop_player()
	call_deferred("_resolve_sfx_bus")
	if OS.has_feature("web"):
		set_process_input(true)


func _make_loop_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.bus = _sfx_bus
	add_child(p)
	return p


func _input(event: InputEvent) -> void:
	if _web_unlocked:
		return
	if event is InputEventMouseButton \
			or event is InputEventKey \
			or event is InputEventScreenTouch \
			or event is InputEventJoypadButton:
		_web_unlocked = true
		if _attack:
			var p := _play(_attack, -80.0)
			if p:
				p.stop()
		set_process_input(false)


func _process(delta: float) -> void:
	_walk_cooldown = maxf(0.0, _walk_cooldown - delta)
	_hurt_cooldown = maxf(0.0, _hurt_cooldown - delta)
	_hit_cooldown = maxf(0.0, _hit_cooldown - delta)
	_land_cooldown = maxf(0.0, _land_cooldown - delta)
	## If a burn loop should be on but stalled (web sample quirk), nudge it.
	if _shade_burning and _burn_shade_player and not _burn_shade_player.playing:
		_set_loop(_burn_shade_player, _burn_shade, true, -14.0)
	if _health_burning and _burn_health_player and not _burn_health_player.playing:
		_set_loop(_burn_health_player, _burn_health, true, -9.0)


func _resolve_sfx_bus() -> void:
	if AudioServer.get_bus_index(Settings.SFX_BUS) != -1:
		_sfx_bus = Settings.SFX_BUS
	else:
		_sfx_bus = "Master"
	for p in _players:
		if is_instance_valid(p):
			p.bus = _sfx_bus
	if _burn_shade_player:
		_burn_shade_player.bus = _sfx_bus
	if _burn_health_player:
		_burn_health_player.bus = _sfx_bus


func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream := load(path)
		if stream is AudioStream:
			return stream as AudioStream
		push_warning("AudioManager: failed to load stream at %s" % path)
	else:
		push_warning("AudioManager: missing SFX %s" % path)
	return null


func _load_loop(path: String) -> AudioStream:
	var stream := _load(path)
	if stream == null:
		return null
	stream = stream.duplicate()
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = -1
	return stream


func _walk_for_floor(floor_kind: String) -> AudioStream:
	## All kinds fall back to steel until we author wood/cobble/etc.
	match floor_kind:
		_:
			return _walk_steel


func _play(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	_resolve_sfx_bus()
	for p in _players:
		if not p.playing:
			p.bus = _sfx_bus
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return p
	var p2: AudioStreamPlayer = _players[0]
	p2.bus = _sfx_bus
	p2.stream = stream
	p2.volume_db = volume_db
	p2.pitch_scale = pitch
	p2.play()
	return p2


func play_attack() -> void:
	_play(_attack, -2.0 + DB_DOWN_45, randf_range(0.96, 1.04))


func play_walk(floor_kind: String = "steel") -> void:
	if GameState.is_dead:
		return
	if _walk_cooldown > 0.0:
		return
	_walk_cooldown = 0.32
	_play(_walk_for_floor(floor_kind), -8.0 + DB_DOWN_45, randf_range(0.94, 1.06))


func play_jump() -> void:
	if GameState.is_dead:
		return
	# Steel-boot push-off (same family as walk).
	_play(_jump, -4.0 + DB_DOWN_45, randf_range(0.97, 1.03))


func play_land(floor_kind: String = "steel") -> void:
	if GameState.is_dead:
		return
	if _land_cooldown > 0.0:
		return
	_land_cooldown = 0.18
	# Land uses the steel bank for now; floor_kind reserved for future material lands.
	if floor_kind.is_empty():
		floor_kind = "steel"
	_play(_land, -6.0 + DB_DOWN_45, randf_range(0.97, 1.03))


func play_boot_crack() -> AudioStreamPlayer:
	return _play(_crack, -1.0 + DB_DOWN_25)


func play_boot_gears() -> AudioStreamPlayer:
	return _play(_gears, -6.0 + DB_DOWN_90)


func play_break() -> void:
	_play(_break, -3.0, randf_range(0.92, 1.08))


func play_currency() -> void:
	_play(_currency, -4.0, randf_range(0.96, 1.06))


func play_hurt() -> void:
	if _hurt_cooldown > 0.0:
		return
	_hurt_cooldown = 0.14
	_play(_hurt, -5.0, randf_range(0.94, 1.05))


func play_hit_connect() -> void:
	## Plays when a player attack volume actually lands on a hurtbox.
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = 0.05
	_play(_hit, -3.0, randf_range(0.94, 1.08))


func set_shade_burning(on: bool) -> void:
	if on == _shade_burning and (not on or (_burn_shade_player and _burn_shade_player.playing)):
		return
	if on:
		_health_burning = false
		if _burn_health_player and _burn_health_player.playing:
			_burn_health_player.stop()
	_shade_burning = on
	_set_loop(_burn_shade_player, _burn_shade, on, -14.0)


func set_health_burning(on: bool) -> void:
	if on == _health_burning and (not on or (_burn_health_player and _burn_health_player.playing)):
		return
	if on:
		_shade_burning = false
		if _burn_shade_player and _burn_shade_player.playing:
			_burn_shade_player.stop()
	_health_burning = on
	_set_loop(_burn_health_player, _burn_health, on, -9.0)


func stop_all_burns() -> void:
	_shade_burning = false
	_health_burning = false
	if _burn_shade_player and _burn_shade_player.playing:
		_burn_shade_player.stop()
	if _burn_health_player and _burn_health_player.playing:
		_burn_health_player.stop()


func _set_loop(player: AudioStreamPlayer, stream: AudioStream, on: bool, volume_db: float) -> void:
	if player == null:
		return
	if not on:
		if player.playing:
			player.stop()
		return
	if stream == null:
		push_warning("AudioManager: burn loop stream missing")
		return
	player.bus = _sfx_bus
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	if not player.playing:
		player.play()
