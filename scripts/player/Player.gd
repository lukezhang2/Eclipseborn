extends CharacterBody2D
class_name Player
## Shadow spirit: black fire, walk/run/jump, attack, shade/health, box push.

const WALK_SPEED := 140.0
const RUN_SPEED := 240.0
const JUMP_VELOCITY := -360.0
const DOUBLE_JUMP_VELOCITY := -320.0
const GRAVITY := 980.0
const ATTACK_STARTUP := 0.06
const ATTACK_ACTIVE := 0.10
const ATTACK_RECOVERY := 0.14
const ATTACK_DAMAGE := 12

enum AnimState { IDLE, WALK, RUN, JUMP, DOUBLE_JUMP, FALL, PUSH, BUMP, ATTACK, SHADE_DRAIN, LIGHT_BURN }

var facing: float = 1.0
var _jumps_remaining: int = 1
var _attack_timer: float = 0.0
var _attack_phase: String = "none"  # none, startup, active, recovery
var _bump_timer: float = 0.0
var _pushing: bool = false
var _in_vulnerable_light: bool = false
var _active_light_kind: int = GameState.LightKind.HEARTH
var _anim: AnimState = AnimState.IDLE

@onready var visual: Node2D = $Visual
@onready var flame: Polygon2D = $Visual/Flame
@onready var eye_l: Polygon2D = $Visual/EyeL
@onready var eye_r: Polygon2D = $Visual/EyeR
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var light_probe: Area2D = $LightProbe


func _ready() -> void:
	GameState.player = self
	collision_layer = 2
	collision_mask = 1 | 4 | 8  # world, shadow ground, boxes
	hurtbox.team = "player"
	hurtbox.owner_body = self
	hurtbox.hurt.connect(_on_hurt)
	hitbox.team = "player"
	hitbox.owner_body = self
	hitbox.damage = ATTACK_DAMAGE
	hitbox.deactivate()
	light_probe.area_entered.connect(_on_light_area_entered)
	light_probe.area_exited.connect(_on_light_area_exited)
	if GameState.checkpoint_position == Vector2.ZERO:
		GameState.set_checkpoint(global_position)
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return

	_update_light_exposure(delta)
	_update_attack(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		_jumps_remaining = 2 if GameState.has_double_jump else 1

	var attacking := _attack_phase != "none"
	var dir := 0.0
	if not attacking:
		dir = Input.get_axis("move_left", "move_right")
		if dir != 0.0:
			facing = signf(dir)

	_pushing = false
	if dir != 0.0 and not attacking:
		_try_push_boxes(dir, delta)

	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	if attacking:
		velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
	elif _bump_timer > 0.0:
		_bump_timer -= delta
		velocity.x = 0.0
	else:
		velocity.x = dir * speed

	if Input.is_action_just_pressed("jump") and not attacking:
		_try_jump()

	if Input.is_action_just_pressed("attack") and _attack_phase == "none":
		_start_attack()

	move_and_slide()
	_update_visual(delta, dir)
	_sync_hitbox_position()


func _try_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		_jumps_remaining = 1 if GameState.has_double_jump else 0
		_anim = AnimState.JUMP
		return
	if GameState.has_double_jump and _jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		_anim = AnimState.DOUBLE_JUMP


func _try_push_boxes(dir: float, delta: float) -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is PushableBox:
			var result: String = (collider as PushableBox).try_push(global_position, dir, delta)
			if result == "push":
				_pushing = true
			elif result == "bump":
				_bump_timer = 0.15
		elif collider is Node:
			var lamp := _find_lamp_owner(collider)
			if lamp and lamp.has_method("try_push"):
				lamp.try_push(dir, delta)
				_pushing = true


func _find_lamp_owner(node: Node) -> Node:
	var n: Node = node
	while n:
		if n.is_in_group("pushable_lamps"):
			return n
		n = n.get_parent()
	return null


func _start_attack() -> void:
	_attack_phase = "startup"
	_attack_timer = ATTACK_STARTUP
	_anim = AnimState.ATTACK


func _update_attack(delta: float) -> void:
	if _attack_phase == "none":
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	match _attack_phase:
		"startup":
			_attack_phase = "active"
			_attack_timer = ATTACK_ACTIVE
			hitbox.activate()
		"active":
			_attack_phase = "recovery"
			_attack_timer = ATTACK_RECOVERY
			hitbox.deactivate()
		"recovery":
			_attack_phase = "none"
			hitbox.deactivate()


func _sync_hitbox_position() -> void:
	hitbox.position = Vector2(28.0 * facing, -8.0)
	hitbox.scale.x = facing


func _update_light_exposure(delta: float) -> void:
	if _in_vulnerable_light:
		GameState.apply_light_exposure(delta, _active_light_kind as GameState.LightKind)
	else:
		GameState.refill_shade_safe(delta)


func _on_light_area_entered(area: Area2D) -> void:
	if not area.has_meta("light_kind"):
		return
	var kind: int = area.get_meta("light_kind")
	# Prefer the harshest light if multiple.
	if kind == GameState.LightKind.SUNSHAFT or not _in_vulnerable_light:
		_active_light_kind = kind
	if kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]:
		_in_vulnerable_light = true
	elif kind in [GameState.LightKind.MOON, GameState.LightKind.CRIMSON]:
		# Safe light: still counts as "out of vulnerable".
		pass


func _on_light_area_exited(area: Area2D) -> void:
	if not area.has_meta("light_kind"):
		return
	# Recompute from overlapping areas.
	_in_vulnerable_light = false
	_active_light_kind = GameState.LightKind.HEARTH
	for a in light_probe.get_overlapping_areas():
		if a.has_meta("light_kind"):
			var kind: int = a.get_meta("light_kind")
			if kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]:
				_in_vulnerable_light = true
				if kind == GameState.LightKind.SUNSHAFT:
					_active_light_kind = kind
				elif _active_light_kind != GameState.LightKind.SUNSHAFT:
					_active_light_kind = kind


func _on_hurt(amount: int, _from: Node) -> void:
	GameState.take_damage(amount)


func _update_visual(delta: float, dir: float) -> void:
	visual.scale.x = facing

	# Breathing idle flicker.
	var t := Time.get_ticks_msec() / 1000.0
	var breath := 1.0 + sin(t * 3.0) * 0.06
	if _attack_phase == "none":
		flame.scale = Vector2(breath, breath + sin(t * 5.0) * 0.04)

	# Eyes drift slightly.
	eye_l.position = Vector2(-6 * facing, -18) + Vector2(sin(t * 1.3) * 1.2, cos(t * 1.1) * 0.8)
	eye_r.position = Vector2(6 * facing, -18) + Vector2(sin(t * 1.5 + 1.0) * 1.2, cos(t * 1.2) * 0.8)

	# State pick for presentation.
	if _attack_phase != "none":
		_anim = AnimState.ATTACK
		flame.color = Color(0.08, 0.05, 0.1)
	elif GameState.shade <= 0.0 and _in_vulnerable_light:
		_anim = AnimState.LIGHT_BURN
		flame.modulate = Color(1, 0.7, 0.5, 0.7)
	elif _in_vulnerable_light and GameState.shade > 0.0:
		_anim = AnimState.SHADE_DRAIN
		flame.modulate = Color(0.85, 0.85, 0.9, 0.85)
		flame.scale *= 0.92
	elif _bump_timer > 0.0:
		_anim = AnimState.BUMP
		flame.modulate = Color.WHITE
	elif _pushing:
		_anim = AnimState.PUSH
		flame.scale = Vector2(1.25, 0.75)
		flame.modulate = Color.WHITE
	elif not is_on_floor():
		_anim = AnimState.FALL if velocity.y > 0.0 else _anim
		flame.modulate = Color.WHITE
	elif absf(dir) > 0.01:
		_anim = AnimState.RUN if Input.is_action_pressed("run") else AnimState.WALK
		flame.scale = Vector2(1.15 if _anim == AnimState.RUN else 1.0, 0.9)
		flame.modulate = Color.WHITE
	else:
		_anim = AnimState.IDLE
		flame.modulate = Color.WHITE

	# Attack lash stretch.
	if _attack_phase == "active":
		flame.scale = Vector2(1.6, 0.7)
	elif _attack_phase == "startup":
		flame.scale = Vector2(0.7, 1.2)
