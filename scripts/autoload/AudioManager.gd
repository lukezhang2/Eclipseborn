extends Node
## Loads and plays SFX. Concrete-hallway echo baked into the WAVs.

var _attack: AudioStream
var _walk: AudioStream
var _jump: AudioStream
var _land: AudioStream
var _crack: AudioStream
var _gears: AudioStream
var _break: AudioStream
var _currency: AudioStream

var _walk_cooldown: float = 0.0
var _players: Array[AudioStreamPlayer] = []
var _sfx_bus: String = "Master"
var _web_unlocked: bool = false


func _ready() -> void:
	# Keep SFX alive while the tree is paused (pause menu / zone map).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_sfx_bus()
	_attack = _load("res://assets/sfx/attack.wav")
	_walk = _load("res://assets/sfx/walk.wav")
	_jump = _load("res://assets/sfx/jump.wav")
	_land = _load("res://assets/sfx/land.wav")
	_crack = _load("res://assets/sfx/boot_crack.wav")
	_gears = _load("res://assets/sfx/boot_gears.wav")
	_break = _load("res://assets/sfx/break.wav")
	_currency = _load("res://assets/sfx/currency.wav")
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.bus = _sfx_bus
		add_child(p)
		_players.append(p)
	# Settings may finish applying volumes one frame later; re-bind buses then.
	call_deferred("_resolve_sfx_bus")
	if OS.has_feature("web"):
		set_process_input(true)


func _input(event: InputEvent) -> void:
	## Browsers keep AudioContext suspended until a user gesture.
	if _web_unlocked:
		return
	if event is InputEventMouseButton \
			or event is InputEventKey \
			or event is InputEventScreenTouch \
			or event is InputEventJoypadButton:
		_web_unlocked = true
		# Engine resumes the Web AudioContext on input; nudge a silent play path too.
		if _attack:
			var p := _play(_attack, -80.0)
			if p:
				p.stop()
		set_process_input(false)


func _process(delta: float) -> void:
	_walk_cooldown = maxf(0.0, _walk_cooldown - delta)


func _resolve_sfx_bus() -> void:
	## Prefer the dedicated SFX bus from default_bus_layout; fall back to Master.
	if AudioServer.get_bus_index(Settings.SFX_BUS) != -1:
		_sfx_bus = Settings.SFX_BUS
	else:
		_sfx_bus = "Master"
	for p in _players:
		if is_instance_valid(p):
			p.bus = _sfx_bus


func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream := load(path)
		if stream is AudioStream:
			return stream as AudioStream
		push_warning("AudioManager: failed to load stream at %s" % path)
	else:
		push_warning("AudioManager: missing SFX %s" % path)
	return null


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
	# Steal first
	var p2: AudioStreamPlayer = _players[0]
	p2.bus = _sfx_bus
	p2.stream = stream
	p2.volume_db = volume_db
	p2.pitch_scale = pitch
	p2.play()
	return p2


func play_attack() -> void:
	_play(_attack, -2.0, randf_range(0.95, 1.05))


func play_walk() -> void:
	if _walk_cooldown > 0.0:
		return
	_walk_cooldown = 0.28
	_play(_walk, -8.0, randf_range(0.92, 1.08))


func play_jump() -> void:
	_play(_jump, -4.0, randf_range(0.96, 1.04))


func play_land() -> void:
	_play(_land, -6.0)


func play_boot_crack() -> AudioStreamPlayer:
	return _play(_crack, -1.0)


func play_boot_gears() -> AudioStreamPlayer:
	return _play(_gears, -6.0)


func play_break() -> void:
	_play(_break, -3.0, randf_range(0.92, 1.08))


func play_currency() -> void:
	_play(_currency, -4.0, randf_range(0.96, 1.06))
