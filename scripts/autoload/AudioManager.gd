extends Node
## Loads and plays SFX. Concrete-hallway echo baked into the WAVs.

var _attack: AudioStream
var _walk: AudioStream
var _jump: AudioStream
var _land: AudioStream
var _crack: AudioStream
var _gears: AudioStream

var _walk_cooldown: float = 0.0
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_attack = _load("res://assets/sfx/attack.wav")
	_walk = _load("res://assets/sfx/walk.wav")
	_jump = _load("res://assets/sfx/jump.wav")
	_land = _load("res://assets/sfx/land.wav")
	_crack = _load("res://assets/sfx/boot_crack.wav")
	_gears = _load("res://assets/sfx/boot_gears.wav")
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func _process(delta: float) -> void:
	_walk_cooldown = maxf(0.0, _walk_cooldown - delta)


func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _play(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return p
	# Steal first
	var p2: AudioStreamPlayer = _players[0]
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
