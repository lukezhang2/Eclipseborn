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
## Outward length past the body edge — matches AttackSlash tip (~40 local + offset, grown ~1.25×).
const HIT_REACH_SIDE := 60.0
const HIT_REACH_UP := 56.0
const HIT_REACH_DOWN := 58.0
## Cross-axis thickness of the attack volume (keeps the box from being a thin line).
const HIT_THICK_SIDE := 1.07  # × body height
const HIT_THICK_VERT := 1.37  # × body width

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
var _active_light_intensity: float = 1.0
var _anim_name: String = "idle"
var _was_on_floor: bool = true
var _control_locked: bool = false
var _land_suppress: float = 0.0
var _floor_sfx: String = "steel"

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var light_probe: Area2D = $LightProbe


func _ready() -> void:
	GameState.player = self
	collision_layer = 2
	## Green world collider: walls/crates/lamps only — enemies stay off these layers so we pass through them.
	## 1=world, 4=shadow_ground, 8=crates, 16=pushable lamp bodies
	collision_mask = 1 | 4 | 8 | 16
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
	if hitbox:
		var hshape := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hshape and hshape.shape:
			hshape.shape = hshape.shape.duplicate()
			# All attack offset lives on Hitbox; local shape must stay at origin (no gap).
			hshape.position = Vector2.ZERO
	if hurtbox:
		var hcs := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hcs and hcs.shape:
			hcs.shape = hcs.shape.duplicate()
	sprite.sprite_frames = SpiritSprites.build_frames()
	sprite.play("idle")
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Godot 4 capsule height includes hemispheres. Plant feet on the floor, not in it.
	_apply_standing_collision()
	_sync_hurtbox()
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

	_land_suppress = maxf(0.0, _land_suppress - delta)
	_update_aim_and_crouch()
	_update_light_exposure(delta)
	_update_attack(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		_jumps_remaining = 2 if GameState.has_double_jump else 1

	## Capture fall speed before slide zeros it — used for a real landing thud.
	var fall_speed := velocity.y

	if _control_locked or GameState.is_dead:
		move_and_slide()
		_finish_floor_audio(fall_speed)
		_update_visual(0.0)
		return

	var dir := _get_move_axis()
	if dir != 0.0:
		facing = signf(dir)
		if not Input.is_action_pressed("look_up") and not _wants_down_aim() and not crouching:
			aim_dir = Vector2.RIGHT if facing > 0.0 else Vector2.LEFT

	_pushing = false
	_pulling = false

	var speed := RUN_SPEED if Input.is_action_pressed("run") and not crouching else WALK_SPEED
	if crouching:
		speed *= CROUCH_MULT
	if _bump_timer > 0.0:
		_bump_timer -= delta
		velocity.x = 0.0
	else:
		velocity.x = dir * speed

	if Input.is_action_just_pressed("jump") and not crouching:
		_try_jump()
	if Input.is_action_just_pressed("attack") and _attack_phase == "none":
		_start_attack()

	move_and_slide()
	_finish_floor_audio(fall_speed)
	if is_on_floor() and absf(dir) > 0.1 and not GameState.is_dead:
		AudioManager.play_walk(_floor_sfx)
	# Push/pull after slide so contact + proximity both work.
	if dir != 0.0 or Input.is_action_pressed("pull"):
		_try_move_boxes(dir if dir != 0.0 else facing, delta)
	_update_visual(dir)
	_update_crouch_collision()
	_sync_hurtbox()
	_sync_hitbox()
	_try_enter_hatch()


func _finish_floor_audio(fall_speed: float) -> void:
	_floor_sfx = _detect_floor_sfx()
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		## Only real falls (not death jitter / tiny floor flicker).
		if (
			not GameState.is_dead
			and _land_suppress <= 0.0
			and fall_speed > 110.0
		):
			AudioManager.play_land(_floor_sfx)
	_was_on_floor = on_floor


func _detect_floor_sfx() -> String:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_normal()
		if n.y > -0.55:
			continue
		var collider := col.get_collider()
		if collider is Node and (collider as Node).has_meta("floor_sfx"):
			return str((collider as Node).get_meta("floor_sfx"))
	return "steel"


func play_death() -> void:
	## Brief collapse pose while the death fade runs.
	_control_locked = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color(0.55, 0.45, 0.55, 1.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(visual, "rotation", 1.25 * facing, 0.4)
		tw.tween_property(sprite, "modulate:a", 0.35, 0.45)


func notify_respawned() -> void:
	## Ignore the teleport "landing" when snapping back to a checkpoint.
	_land_suppress = 0.45
	_was_on_floor = true
	velocity = Vector2.ZERO
	_control_locked = false
	if visual:
		visual.rotation = 0.0
	if sprite:
		sprite.modulate = Color.WHITE


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


func _apply_standing_collision() -> void:
	## Sprite feet at image y≈52 / center 32 → offset −20 puts soles at origin.
	## Lift 2px so art sits on the floor plate instead of clipping into it.
	sprite.position.y = -22.0
	if body_shape and body_shape.shape is CapsuleShape2D:
		var cap := body_shape.shape as CapsuleShape2D
		cap.height = 36.0
		cap.radius = 10.0
		# Bottom of capsule at y = -2 (slightly above origin).
		body_shape.position.y = -cap.height * 0.5 - 2.0


func _update_crouch_collision() -> void:
	if crouching:
		sprite.position.y = -16.0
		if body_shape and body_shape.shape is CapsuleShape2D:
			var cap := body_shape.shape as CapsuleShape2D
			cap.height = 22.0
			cap.radius = 10.0
			body_shape.position.y = -cap.height * 0.5 - 2.0
	else:
		_apply_standing_collision()


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
	# Push ONLY when physically walking into a side face (not standing on top / nearby).
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is PushableBox:
			var box := collider as PushableBox
			var n := col.get_normal()
			if pulling:
				# Only pull when walking away from the crate (no teleport snap).
				var away := signf(global_position.x - box.global_position.x)
				if dir != 0.0 and signf(dir) == away:
					if box.try_pull(global_position, dir, delta) == "pull":
						_pulling = true
						facing = away
			else:
				if absf(n.x) < 0.55:
					continue
				if dir == 0.0 or signf(dir) == signf(n.x):
					continue
				if box.try_push(global_position, dir, delta) == "push":
					_pushing = true
		elif collider is Node and not pulling:
			var lamp := _find_lamp_owner(collider)
			var n2 := col.get_normal()
			if lamp and lamp.has_method("try_push") and absf(n2.x) >= 0.55 and dir != 0.0 and signf(dir) != signf(n2.x):
				lamp.try_push(dir, delta)
				_pushing = true
	if not pulling or dir == 0.0:
		return
	# Proximity pull — walk away while holding V; box follows. No player teleport.
	var nearest: PushableBox = null
	var best := 9999.0
	for node in get_tree().get_nodes_in_group("boxes"):
		if not node is PushableBox:
			continue
		var box := node as PushableBox
		var d := absf(box.global_position.x - global_position.x)
		var dy := absf(box.global_position.y - global_position.y)
		if dy > box.box_size.y * 0.65:
			continue
		if d < best and d < box.box_size.x * 0.5 + 56.0:
			best = d
			nearest = box
	if nearest == null:
		return
	var away2 := signf(global_position.x - nearest.global_position.x)
	if signf(dir) != away2:
		return
	if nearest.try_pull(global_position, dir, delta) == "pull":
		_pulling = true
		facing = away2


func _try_enter_hatch() -> void:
	if not Input.is_action_just_pressed("crouch"):
		return
	for h in get_tree().get_nodes_in_group("enterable_hatches"):
		if h.has_method("try_enter") and h.try_enter(self):
			return


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


func _body_half_extents() -> Vector2:
	## Green world collider AABB (capsule ≈ width 2r × height).
	if body_shape and body_shape.shape is CapsuleShape2D:
		var cap := body_shape.shape as CapsuleShape2D
		return Vector2(cap.radius, cap.height * 0.5)
	return Vector2(10.0, 18.0)


func _sync_hurtbox() -> void:
	## Yellow: inset damage volume inside green. No physics vs enemies (Area2D only).
	if hurtbox == null:
		return
	var hcs := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hcs == null or not (hcs.shape is RectangleShape2D):
		return
	var half := _body_half_extents()
	var body_h := half.y * 2.0
	var body_w := half.x * 2.0
	var body_top := body_shape.position.y - half.y
	# Diagram ratios vs green: ~55% wide, ~62% tall, top inset ~29%.
	var hurt_w := body_w * 0.55
	var hurt_h := body_h * 0.62
	var top_inset := body_h * 0.29
	var rect := hcs.shape as RectangleShape2D
	rect.size = Vector2(hurt_w, hurt_h)
	hcs.position = Vector2(0.0, body_top + top_inset + hurt_h * 0.5)


func _sync_hitbox() -> void:
	## Red cardinal attack boxes: flush on the body, long enough to cover the slash tip.
	var shape := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		return
	shape.position = Vector2.ZERO
	var half := _body_half_extents()
	var body_w := half.x * 2.0
	var body_h := half.y * 2.0
	var body_cx := body_shape.position.x
	var body_cy := body_shape.position.y
	var body_top := body_cy - half.y
	var body_bottom := body_cy + half.y
	if shape.shape is RectangleShape2D:
		var rect := shape.shape as RectangleShape2D
		if aim_dir == Vector2.UP:
			rect.size = Vector2(body_w * HIT_THICK_VERT, HIT_REACH_UP)
			hitbox.position = Vector2(body_cx, body_top - rect.size.y * 0.5)
		elif aim_dir == Vector2.DOWN:
			rect.size = Vector2(body_w * HIT_THICK_VERT, HIT_REACH_DOWN)
			hitbox.position = Vector2(body_cx, body_bottom + rect.size.y * 0.5)
		else:
			rect.size = Vector2(HIT_REACH_SIDE, body_h * HIT_THICK_SIDE)
			hitbox.position = Vector2(body_cx + facing * (half.x + rect.size.x * 0.5), body_cy)
	else:
		if aim_dir == Vector2.UP:
			hitbox.position = Vector2(0, body_top - HIT_REACH_UP * 0.5)
		elif aim_dir == Vector2.DOWN:
			hitbox.position = Vector2(0, body_bottom + HIT_REACH_DOWN * 0.5)
		else:
			hitbox.position = Vector2(facing * (half.x + HIT_REACH_SIDE * 0.5), body_cy)
	hitbox.rotation = 0
	hitbox.scale = Vector2.ONE


func _update_light_exposure(delta: float) -> void:
	_recompute_light_state()
	if GameState.is_dead:
		AudioManager.stop_all_burns()
		return
	if _in_vulnerable_light:
		GameState.apply_light_exposure(
			delta,
			_active_light_kind as GameState.LightKind,
			_active_light_intensity
		)
		# Quiet crackle while shade drains; a bit louder once HP burns in light.
		if GameState.shade > 0.0:
			AudioManager.set_shade_burning(true)
		else:
			AudioManager.set_health_burning(true)
	else:
		GameState.refill_shade_safe(delta)
		AudioManager.stop_all_burns()


func _recompute_light_state() -> void:
	_in_vulnerable_light = false
	_active_light_kind = GameState.LightKind.HEARTH
	_active_light_intensity = 0.0
	var center := global_position + Vector2(0, -18)
	var has_sunshaft := false
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
		var inten := 1.0
		if light.has_method("get_intensity"):
			inten = float(light.get_intensity())
		var kind: int = light.get_light_kind()
		## Overlapping lamps add intensity (matches additive wash stacking).
		_in_vulnerable_light = true
		_active_light_intensity += inten
		if kind == GameState.LightKind.SUNSHAFT or not has_sunshaft:
			_active_light_kind = kind
			if kind == GameState.LightKind.SUNSHAFT:
				has_sunshaft = true


func _occluded(from: Vector2, to: Vector2) -> bool:
	## World(1) + crates(8) + light-only houses(128) — same mask as ShadowWorld washes.
	return ShadowWorld.segment_occluded(from, to, [get_rid()])


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
