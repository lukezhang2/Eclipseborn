extends CharacterBody2D
class_name Player
## Eclipseborn spirit: humanoid shadow body, aim up/down, directed attack slashes.

const WALK_SPEED := 140.0
const RUN_SPEED := 240.0
const JUMP_VELOCITY := -360.0
const DOUBLE_JUMP_VELOCITY := -320.0
const GRAVITY := 980.0
const ATTACK_STARTUP := 0.05
const ATTACK_ACTIVE := 0.12
const ATTACK_RECOVERY := 0.12
const ATTACK_DAMAGE := 12

var facing: float = 1.0
## -1 down, 0 forward, 1 up
var look_aim: int = 0
var _jumps_remaining: int = 1
var _attack_timer: float = 0.0
var _attack_phase: String = "none"
var _bump_timer: float = 0.0
var _pushing: bool = false
var _in_vulnerable_light: bool = false
var _active_light_kind: int = GameState.LightKind.HEARTH
var _anim_name: String = "idle"

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var light_probe: Area2D = $LightProbe


func _ready() -> void:
	GameState.player = self
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	hurtbox.team = "player"
	hurtbox.owner_body = self
	hurtbox.hurt.connect(_on_hurt)
	hitbox.team = "player"
	hitbox.owner_body = self
	hitbox.damage = ATTACK_DAMAGE
	hitbox.deactivate()
	light_probe.area_entered.connect(_on_light_area_entered)
	light_probe.area_exited.connect(_on_light_area_exited)
	sprite.sprite_frames = SpiritSprites.build_frames()
	sprite.play("idle")
	sprite.centered = true
	sprite.position = Vector2(0, -32)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if GameState.checkpoint_position == Vector2.ZERO:
		GameState.set_checkpoint(global_position)
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return

	_update_look()
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
	_update_visual(dir)
	_sync_hitbox_position()


func _update_look() -> void:
	if _attack_phase != "none":
		return
	var up := Input.is_action_pressed("look_up")
	var down := Input.is_action_pressed("look_down")
	if up and not down:
		look_aim = 1
	elif down and not up:
		look_aim = -1
	else:
		look_aim = 0


func _try_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		_jumps_remaining = 1 if GameState.has_double_jump else 0
		_play_anim("jump")
		return
	if GameState.has_double_jump and _jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		_play_anim("jump")


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
	var anim := "attack_forward"
	if look_aim > 0:
		anim = "attack_up"
	elif look_aim < 0:
		anim = "attack_down"
	_play_anim(anim)
	var slash := AttackSlash.new()
	add_child(slash)
	slash.play(look_aim, facing)


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
	var offset := Vector2(30.0 * facing, -12.0)
	if look_aim > 0:
		offset = Vector2(18.0 * facing, -40.0)
	elif look_aim < 0:
		offset = Vector2(18.0 * facing, 8.0)
	hitbox.position = offset
	hitbox.rotation_degrees = -50.0 * look_aim
	hitbox.scale.x = facing
	if hitbox_shape and hitbox_shape.shape is RectangleShape2D:
		(hitbox_shape.shape as RectangleShape2D).size = Vector2(40, 24)


func _update_light_exposure(delta: float) -> void:
	if _in_vulnerable_light:
		GameState.apply_light_exposure(delta, _active_light_kind as GameState.LightKind)
	else:
		GameState.refill_shade_safe(delta)


func _on_light_area_entered(area: Area2D) -> void:
	if not area.has_meta("light_kind"):
		return
	var kind: int = area.get_meta("light_kind")
	if kind == GameState.LightKind.SUNSHAFT or not _in_vulnerable_light:
		_active_light_kind = kind
	if kind in [GameState.LightKind.HEARTH, GameState.LightKind.CANDLE, GameState.LightKind.SUNSHAFT]:
		_in_vulnerable_light = true


func _on_light_area_exited(_area: Area2D) -> void:
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


func _update_visual(dir: float) -> void:
	visual.scale.x = facing
	sprite.flip_h = false

	if _attack_phase != "none":
		return

	if GameState.shade <= 0.0 and _in_vulnerable_light:
		_play_anim("light_burn")
	elif _in_vulnerable_light and GameState.shade > 0.0:
		_play_anim("shade_drain")
	elif _bump_timer > 0.0:
		_play_anim("bump")
	elif _pushing:
		_play_anim("push")
	elif not is_on_floor():
		_play_anim("fall" if velocity.y > 40.0 else "jump")
	elif absf(dir) > 0.01:
		_play_anim("run" if Input.is_action_pressed("run") else "walk")
	else:
		_play_anim("idle")

	# Head tilt cue: nudge sprite offset when looking.
	sprite.position.y = -32 + (-2 if look_aim > 0 else (2 if look_aim < 0 else 0))


func _play_anim(anim: String) -> void:
	if _anim_name == anim and sprite.is_playing():
		return
	_anim_name = anim
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
