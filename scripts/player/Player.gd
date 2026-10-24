extends CharacterBody2D
class_name Player
## Eclipseborn spirit: cardinal attacks only (N/E/S/W), crouch, pull, center light.

const WALK_SPEED := 140.0
const RUN_SPEED := 240.0
const CROUCH_MULT := 0.6
const JUMP_VELOCITY := -360.0
const DOUBLE_JUMP_VELOCITY := -320.0
const GRAVITY := 980.0
const ATTACK_STARTUP := 0.05
const ATTACK_ACTIVE := 0.11
const ATTACK_RECOVERY := 0.12
const ATTACK_DAMAGE := 12

var facing: float = 1.0
## Cardinal look: Vector2.RIGHT/LEFT/UP/DOWN
var aim_dir: Vector2 = Vector2.RIGHT
var crouching: bool = false
var _jumps_remaining: int = 1
var _attack_timer: float = 0.0
var _attack_phase: String = "none"
var _bump_timer: float = 0.0
var _pushing: bool = false
var _pulling: bool = false
var _in_vulnerable_light: bool = false
var _active_light_kind: int = GameState.LightKind.HEARTH
var _anim_name: String = "idle"
var _was_on_floor: bool = true
var _control_locked: bool = false

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
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
	var probe_shape := light_probe.get_node("CollisionShape2D") as CollisionShape2D
	if probe_shape and probe_shape.shape is CircleShape2D:
		(probe_shape.shape as CircleShape2D).radius = 3.0
		probe_shape.position = Vector2(0, -18)
	if body_shape and body_shape.shape:
		body_shape.shape = body_shape.shape.duplicate()
	sprite.sprite_frames = SpiritSprites.build_frames()
	sprite.play("idle")
	sprite.centered = true
	sprite.position = Vector2(0, -28)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if GameState.checkpoint_position == Vector2.ZERO:
		GameState.set_checkpoint(global_position)
	add_to_group("player")
	if GameState.needs_intro_cutscene:
		_control_locked = true
		call_deferred("_run_intro")


func _run_intro() -> void:
	GameState.intro_cutscene_playing = true
	_control_locked = true
	var intro := preload("res://scripts/world/IntroCutscene.gd").new()
	get_parent().add_child(intro)
	await intro.play(self)
	GameState.needs_intro_cutscene = false
	GameState.intro_cutscene_playing = false
	_control_locked = false


func set_control_locked(locked: bool) -> void:
	_control_locked = locked
	if locked:
		velocity = Vector2.ZERO


## Clamped axis: opposing left/right cancel; never stacks above 1.
func _get_move_axis() -> float:
	var left := Input.get_action_strength("move_left")
	var right := Input.get_action_strength("move_right")
	if left > 0.0 and right > 0.0:
		return 0.0
	return clampf(right - left, -1.0, 1.0)


func _physics_process(delta: float) -> void:
	if GameState.is_paused or GameState.intro_cutscene_playing:
		return

	_update_aim_and_crouch()
	_update_light_exposure(delta)
	_update_attack(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		_jumps_remaining = 2 if GameState.has_double_jump else 1
		if not _was_on_floor:
			AudioManager.play_land()
	_was_on_floor = is_on_floor()

	if _control_locked:
		move_and_slide()
		_update_visual(0.0)
		return

	var dir := _get_move_axis()
	if dir != 0.0:
		facing = signf(dir)
		if not Input.is_action_pressed("look_up") and not _wants_down_aim() and not crouching:
			aim_dir = Vector2.RIGHT if facing > 0.0 else Vector2.LEFT

	_pushing = false
	_pulling = false
	if dir != 0.0:
		_try_move_boxes(dir, delta)

	var speed := RUN_SPEED if Input.is_action_pressed("run") and not crouching else WALK_SPEED
	if crouching:
		speed *= CROUCH_MULT
	if _bump_timer > 0.0:
		_bump_timer -= delta
		velocity.x = 0.0
	else:
		velocity.x = dir * speed
		if is_on_floor() and absf(dir) > 0.1:
			AudioManager.play_walk()

	if Input.is_action_just_pressed("jump") and _attack_phase == "none" and not crouching:
		_try_jump()
	if Input.is_action_just_pressed("attack") and _attack_phase == "none":
		_start_attack()

	move_and_slide()
	_update_visual(dir)
	_sync_hitbox()
	_update_crouch_collision()


func _wants_down_aim() -> bool:
	if is_on_floor():
		return crouching
	return Input.is_action_pressed("look_down") or Input.is_action_pressed("crouch")


func _update_aim_and_crouch() -> void:
	crouching = Input.is_action_pressed("crouch") and is_on_floor()
	if _attack_phase != "none":
		return
	# Strict cardinal aim only — never diagonal.
	if Input.is_action_pressed("look_up"):
		aim_dir = Vector2.UP
	elif _wants_down_aim():
		aim_dir = Vector2.DOWN
	else:
		aim_dir = Vector2.RIGHT if facing > 0.0 else Vector2.LEFT


func _update_crouch_collision() -> void:
	# Keep sprite feet planted; only shrink collider while crouching.
	sprite.position.y = -28.0
	if body_shape and body_shape.shape is CapsuleShape2D:
		var cap := body_shape.shape as CapsuleShape2D
		if crouching:
			cap.height = 22.0
			body_shape.position.y = -12.0
		else:
			cap.height = 34.0
			body_shape.position.y = -18.0


func _try_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		_jumps_remaining = 1 if GameState.has_double_jump else 0
		AudioManager.play_jump()
		return
	if GameState.has_double_jump and _jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		AudioManager.play_jump()


func _try_move_boxes(dir: float, delta: float) -> void:
	var pulling := Input.is_action_pressed("pull")
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is PushableBox:
			var box := collider as PushableBox
			if pulling:
				if box.try_pull(global_position, dir, delta) == "pull":
					_pulling = true
					_attach_pull_pose(box, dir, delta)
			else:
				var r: String = box.try_push(global_position, dir, delta)
				if r == "push":
					_pushing = true
		elif collider is Node:
			var lamp := _find_lamp_owner(collider)
			if lamp and lamp.has_method("try_push") and not pulling:
				lamp.try_push(dir, delta)
				_pushing = true
	if pulling and not _pulling:
		for box in get_tree().get_nodes_in_group("boxes"):
			if box is PushableBox:
				if (box as PushableBox).try_pull(global_position, dir, delta) == "pull":
					_pulling = true
					_attach_pull_pose(box as PushableBox, dir, delta)
					break


func _attach_pull_pose(box: PushableBox, dir: float, delta: float) -> void:
	## Snap beside the crate, face the pull direction (away from crate contact).
	if dir == 0.0:
		return
	facing = signf(dir)
	var target_x := box.pull_stand_x(facing)
	global_position.x = move_toward(global_position.x, target_x, 220.0 * delta)


func _find_lamp_owner(node: Node) -> Node:
	var n: Node = node
	while n:
		if n.is_in_group("pushable_lamps"):
			return n
		n = n.get_parent()
	return null


func _start_attack() -> void:
	# Ground down-slash requires crouch; air down-slash allowed without crouch.
	if aim_dir == Vector2.DOWN and is_on_floor() and not crouching:
		return
	_attack_phase = "startup"
	_attack_timer = ATTACK_STARTUP
	if aim_dir == Vector2.RIGHT:
		facing = 1.0
		_play_anim("attack_east")
	elif aim_dir == Vector2.LEFT:
		facing = -1.0
		_play_anim("attack_west")
	elif aim_dir == Vector2.UP:
		_play_anim("attack_north")
	else:
		_play_anim("attack_south")
	AudioManager.play_attack()
	var slash := AttackSlash.new()
	add_child(slash)
	slash.play(aim_dir)


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


func _sync_hitbox() -> void:
	if aim_dir == Vector2.UP:
		hitbox.position = Vector2(0, -40)
		hitbox.rotation = 0
	elif aim_dir == Vector2.DOWN:
		hitbox.position = Vector2(0, 8)
		hitbox.rotation = 0
	else:
		hitbox.position = Vector2(28.0 * facing, -14)
		hitbox.rotation = 0
	hitbox.scale = Vector2.ONE


func _update_light_exposure(delta: float) -> void:
	_recompute_light_state()
	if _in_vulnerable_light:
		GameState.apply_light_exposure(delta, _active_light_kind as GameState.LightKind)
	else:
		GameState.refill_shade_safe(delta)


func _recompute_light_state() -> void:
	_in_vulnerable_light = false
	_active_light_kind = GameState.LightKind.HEARTH
	var center := global_position + Vector2(0, -18)
	for light in get_tree().get_nodes_in_group("lights"):
		if not light.has_method("is_on") or not light.is_on():
			continue
		if not light.has_method("burns") or not light.burns():
			continue
		var origin: Vector2 = light.get_light_origin()
		var radius: float = light.get_radius()
		if center.distance_to(origin) > radius:
			continue
		if _occluded(origin, center):
			continue
		_in_vulnerable_light = true
		_active_light_kind = light.get_light_kind()
		if _active_light_kind == GameState.LightKind.SUNSHAFT:
			break


func _occluded(from: Vector2, to: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = 8  # boxes
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	return not hit.is_empty()


func _on_light_area_entered(_area: Area2D) -> void:
	_recompute_light_state()


func _on_light_area_exited(_area: Area2D) -> void:
	_recompute_light_state()


func _on_hurt(amount: int, _from: Node) -> void:
	GameState.take_damage(amount)


func _damage_suffix() -> String:
	if not _in_vulnerable_light:
		return ""
	if GameState.shade <= 0.0:
		return "_burn"
	return "_shade"


func _update_visual(dir: float) -> void:
	visual.scale.x = facing
	if _attack_phase != "none":
		return
	var base := "idle"
	if _pulling:
		base = "pull"
	elif _pushing:
		base = "push"
	elif crouching:
		base = "crouch_walk" if absf(dir) > 0.01 else "crouch"
	elif not is_on_floor():
		base = "fall" if velocity.y > 40.0 else "jump"
	elif absf(dir) > 0.01:
		base = "run" if Input.is_action_pressed("run") else "walk"
	else:
		base = "idle"
	var suffix := _damage_suffix()
	var anim := base + suffix
	if suffix != "" and sprite.sprite_frames and not sprite.sprite_frames.has_animation(anim):
		anim = base
	_play_anim(anim)


func _play_anim(anim: String) -> void:
	if _anim_name == anim and sprite.is_playing():
		return
	_anim_name = anim
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
