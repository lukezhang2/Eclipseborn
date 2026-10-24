extends Node2D
class_name PlatformDriver
## Moves a linked platform; pair with a decorative BgGear (no collision).

@export var move_amplitude: float = 100.0
@export var move_speed: float = 0.7
@export var vertical: bool = false

var _linked: Node2D
var _base: Vector2
var _t: float = 0.0
var _bg: Node2D


func bind(platform: Node2D, bg_gear: Node2D = null) -> void:
	_linked = platform
	_bg = bg_gear
	if _linked:
		_base = _linked.position


func _physics_process(delta: float) -> void:
	if GameState.is_paused or _linked == null:
		return
	_t += delta * move_speed
	var offset := sin(_t) * move_amplitude
	if vertical:
		_linked.position = _base + Vector2(0, offset)
	else:
		_linked.position = _base + Vector2(offset, 0)
	if _bg:
		_bg.rotation = _t
	ShadowWorld.mark_dirty()
