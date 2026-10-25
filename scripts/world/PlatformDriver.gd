extends Node2D
class_name PlatformDriver
## Moves a linked platform along a path; optional gear/platform spin.


@export var move_amplitude: float = 100.0
@export var move_speed: float = 0.7
@export var vertical: bool = false
## Secondary axis wobble (elliptical path when combined with amplitude).
@export var path_y_amplitude: float = 0.0
@export var rotate_while_moving: bool = true
@export var rotate_speed: float = 1.0 ## multiplies phase for gear spin
@export var rotate_platform: bool = false ## spin the floor itself

var _linked: Node2D
var _base: Vector2
var _t: float = 0.0
var _bg: Node2D


func bind(platform: Node2D, bg_gear: Node2D = null) -> void:
	_linked = platform
	_bg = bg_gear
	if _linked:
		_base = _linked.position


func configure(d: Dictionary) -> void:
	if d.has("move_amplitude"):
		move_amplitude = float(d.get("move_amplitude"))
	if d.has("amplitude"):
		move_amplitude = float(d.get("amplitude"))
	if d.has("move_speed"):
		move_speed = float(d.get("move_speed"))
	if d.has("speed"):
		move_speed = float(d.get("speed"))
	if d.has("vertical"):
		vertical = bool(d.get("vertical"))
	if d.has("path_y_amplitude"):
		path_y_amplitude = float(d.get("path_y_amplitude"))
	if d.has("rotate_while_moving"):
		rotate_while_moving = bool(d.get("rotate_while_moving"))
	if d.has("rotate"):
		rotate_while_moving = bool(d.get("rotate"))
	if d.has("rotate_speed"):
		rotate_speed = float(d.get("rotate_speed"))
	if d.has("rotate_platform"):
		rotate_platform = bool(d.get("rotate_platform"))


func _physics_process(delta: float) -> void:
	if GameState.is_paused or _linked == null:
		return
	_t += delta * move_speed
	var sx := sin(_t)
	var ox := 0.0
	var oy := 0.0
	if vertical:
		oy = sx * move_amplitude
		ox = cos(_t) * path_y_amplitude
	else:
		ox = sx * move_amplitude
		oy = cos(_t) * path_y_amplitude
	_linked.position = _base + Vector2(ox, oy)
	if rotate_while_moving and _bg:
		_bg.rotation = _t * rotate_speed
	if rotate_platform:
		_linked.rotation = _t * rotate_speed
	## ShadowWorld picks up platform motion via ShadowOccluder.did_move (throttled).
