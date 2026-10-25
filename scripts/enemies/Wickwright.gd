extends CharacterBody2D
class_name Wickwright
## Clockwork Tower apex boss — flies, dives, and slams every arena lever ON.


signal defeated

## Ten sword connects kill the boss (each swing = 1 HP).
const MAX_HP := 10
const HURT_IFRAMES := 0.35
const WickwrightArtScript := preload("res://scripts/enemies/WickwrightArt.gd")
const DIVE_DAMAGE := 18
const SWEEP_DAMAGE := 14

enum Phase { ONE, TWO, THREE }

var hp: int = MAX_HP
var phase: Phase = Phase.ONE
var _state: String = "dormant"
var _state_t: float = 0.0
var _cooldown: float = 1.2
var _hurt_cd: float = 0.0
var _dying: bool = false
var _awake: bool = false
var _spawn_pos: Vector2 = Vector2.ZERO
var _hover_origin: Vector2 = Vector2.ZERO
var _dive_target: Vector2 = Vector2.ZERO
var _visual: Node2D
var _body_poly: Polygon2D
var _heart_poly: Polygon2D
var _wings: Array = []
## 0 = original flat polygons; 1..3 = WickwrightArt looks.
var art_style: int = 3
var _art = null ## WickwrightArt
var _hurtbox: Hurtbox
var _hitbox: Hitbox
var _switch_ids: PackedStringArray = PackedStringArray(["tower_switch_a", "tower_switch_b", "tower_switch_c"])


func _ready() -> void:
	hp = MAX_HP
	collision_layer = 0
	collision_mask = 0
	_spawn_pos = global_position
	_hover_origin = global_position
	_build()
	add_to_group("enemies")
	add_to_group("bosses")
	name = "Wickwright"
	## Sleep until the arena wake trigger fires.
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)


func awaken() -> void:
	if _awake or _dying:
		return
	_awake = true
	_state = "hover"
	_cooldown = 0.8
	_hover_origin = _spawn_pos
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", true)
		for c in _hurtbox.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).set_deferred("disabled", false)
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("The Wickwright stirs.", 3.0)


## Player died mid-fight — restore dormant full-HP encounter.
func reset_encounter() -> void:
	_dying = false
	_awake = false
	hp = MAX_HP
	phase = Phase.ONE
	_state = "dormant"
	_state_t = 0.0
	_cooldown = 1.2
	_hurt_cd = 0.0
	velocity = Vector2.ZERO
	rotation = 0.0
	modulate = Color.WHITE
	global_position = _spawn_pos
	_hover_origin = _spawn_pos
	set_physics_process(true)
	if _hitbox:
		_hitbox.deactivate()
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	if _heart_poly:
		_heart_poly.color.a = 0.15
	if _body_poly:
		_body_poly.color = Color(0.32, 0.28, 0.24)
	_restore_switches()


func _restore_switches() -> void:
	var starts := [true, false, true]
	var tree := get_tree()
	if tree == null:
		return
	for i in _switch_ids.size():
		var sid := str(_switch_ids[i])
		var sw := tree.root.find_child(sid, true, false)
		if sw == null:
			continue
		if sw.has_meta("smashed"):
			sw.remove_meta("smashed")
		sw.modulate = Color.WHITE
		sw.set_process(true)
		if sw.has_method("set_powered"):
			sw.call("set_powered", bool(starts[i]) if i < starts.size() else true, false)


func _build() -> void:
	_visual = Node2D.new()
	add_child(_visual)

	var wing_l := Polygon2D.new()
	wing_l.color = Color(0.45, 0.35, 0.22, 0.85)
	wing_l.polygon = PackedVector2Array([
		Vector2(-8, -10), Vector2(-48, -28), Vector2(-40, 8), Vector2(-12, 6)
	])
	_visual.add_child(wing_l)
	_wings.append(wing_l)
	var wing_r := Polygon2D.new()
	wing_r.color = Color(0.45, 0.35, 0.22, 0.85)
	wing_r.polygon = PackedVector2Array([
		Vector2(8, -10), Vector2(48, -28), Vector2(40, 8), Vector2(12, 6)
	])
	_visual.add_child(wing_r)
	_wings.append(wing_r)

	_body_poly = Polygon2D.new()
	_body_poly.color = Color(0.32, 0.28, 0.24)
	_body_poly.polygon = PackedVector2Array([
		Vector2(-16, -28), Vector2(16, -28), Vector2(20, 8), Vector2(10, 34),
		Vector2(-10, 34), Vector2(-20, 8)
	])
	_visual.add_child(_body_poly)

	## Pocket-watch face
	var face := Polygon2D.new()
	face.color = Color(0.7, 0.62, 0.45)
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0 + Vector2(0, -14))
	face.polygon = pts
	_visual.add_child(face)
	var pupil := Polygon2D.new()
	pupil.color = Color(0.55, 0.25, 0.7)
	pupil.polygon = PackedVector2Array([
		Vector2(-3, -16), Vector2(3, -16), Vector2(3, -10), Vector2(-3, -10)
	])
	_visual.add_child(pupil)

	_heart_poly = Polygon2D.new()
	_heart_poly.color = Color(0.95, 0.45, 0.15, 0.0)
	_heart_poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(8, 8), Vector2(0, 18), Vector2(-8, 8)
	])
	_heart_poly.position = Vector2(0, -2)
	_visual.add_child(_heart_poly)

	if GameState.has_meta("preview_boss_style"):
		art_style = int(GameState.get_meta("preview_boss_style"))
	if art_style > 0:
		for c in _visual.get_children():
			(c as CanvasItem).visible = false
		_art = WickwrightArtScript.new()
		_art.style = art_style
		_visual.add_child(_art)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	## Tall strike volume: body + drop so jump/side swings reach the hover perch.
	hr.size = Vector2(84, 160)
	hcs.shape = hr
	hcs.position = Vector2(0, 20)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)

	_hitbox = Hitbox.new()
	_hitbox.team = "enemy"
	_hitbox.owner_body = self
	_hitbox.damage = DIVE_DAMAGE
	var ics := CollisionShape2D.new()
	var ir := CircleShape2D.new()
	ir.radius = 22.0
	ics.shape = ir
	_hitbox.add_child(ics)
	add_child(_hitbox)
	_hitbox.deactivate()


func _physics_process(delta: float) -> void:
	if _dying or GameState.is_paused:
		return
	if GameState.intro_cutscene_playing and _state != "cutscene":
		return
	_hurt_cd = maxf(0.0, _hurt_cd - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_state_t += delta
	_anim_wings(delta)
	if not _awake:
		## Idle hover bob while dormant — no attacks.
		var bob := Vector2(sin(Time.get_ticks_msec() * 0.0015) * 12.0, cos(Time.get_ticks_msec() * 0.002) * 8.0)
		global_position = global_position.lerp(_hover_origin + bob, clampf(2.0 * delta, 0.0, 1.0))
		return
	match _state:
		"hover":
			_do_hover(delta)
		"dive":
			_do_dive(delta)
		"sweep":
			_do_sweep(delta)
		"flip":
			_do_flip(delta)
		"cutscene":
			pass
		_:
			_state = "hover"


func _anim_wings(delta: float) -> void:
	var flap := sin(Time.get_ticks_msec() * 0.012) * 6.0
	if _wings.size() >= 2:
		_wings[0].position.y = flap
		_wings[1].position.y = -flap * 0.5
	if _art:
		_pose_art(delta)


func _pose_art(delta: float) -> void:
	var tt := Time.get_ticks_msec() * 0.001
	_art.t = tt
	var want_flap := sin(tt * 7.0) * 0.45
	var want_wind := 0.0
	if not _awake:
		want_flap = sin(tt * 2.2) * 0.2 + 0.25
	elif _state == "dive":
		if _state_t < 0.35:
			want_flap = -0.75
			want_wind = 1.0
		else:
			want_flap = 0.9 ## wings tucked for the strike
			want_wind = 0.6
	elif _state == "sweep":
		want_flap = -0.1 + sin(tt * 22.0) * 0.12
		want_wind = 0.4
	elif _state == "flip":
		want_flap = sin(tt * 12.0) * 0.6
	elif _state == "cutscene":
		want_flap = 0.8 + sin(tt * 5.0) * 0.1
	_art.flap = lerpf(_art.flap, want_flap, clampf(14.0 * delta, 0.0, 1.0))
	_art.windup = lerpf(_art.windup, want_wind, clampf(10.0 * delta, 0.0, 1.0))
	_art.heart = lerpf(_art.heart, 0.35, clampf(6.0 * delta, 0.0, 1.0))
	_art.hand_speed = 1.0 + float(phase) * 1.5
	_art.damage = float(phase) / 2.0
	_art.dying = _dying
	var p = GameState.player
	if p and is_instance_valid(p):
		_art.look = (p.global_position - global_position).normalized()


func _do_hover(delta: float) -> void:
	var p = GameState.player
	var bob := Vector2(sin(Time.get_ticks_msec() * 0.002) * 40.0, cos(Time.get_ticks_msec() * 0.003) * 18.0)
	var want := _hover_origin + bob
	if p and is_instance_valid(p):
		want.x = lerpf(want.x, p.global_position.x, 0.15)
	global_position = global_position.lerp(want, clampf(3.0 * delta, 0.0, 1.0))
	if _cooldown <= 0.0:
		_pick_attack()


func _pick_attack() -> void:
	var roll := randf()
	## Lever yank is common — boss fights by rewriting the floor lamps.
	if roll < 0.38:
		_begin_flip()
	elif roll < 0.68:
		_begin_dive()
	else:
		_begin_sweep()


func _begin_dive() -> void:
	_state = "dive"
	_state_t = 0.0
	_cooldown = 2.2
	var p = GameState.player
	_dive_target = p.global_position if p else global_position + Vector2(0, 120)
	_hitbox.damage = DIVE_DAMAGE
	_hitbox.activate()


func _do_dive(delta: float) -> void:
	if _state_t < 0.35:
		global_position.y -= 80.0 * delta
		return
	global_position = global_position.move_toward(_dive_target + Vector2(0, -20), 520.0 * delta)
	if global_position.distance_to(_dive_target + Vector2(0, -20)) < 12.0 or _state_t > 1.4:
		_hitbox.deactivate()
		_state = "hover"
		_state_t = 0.0


func _begin_sweep() -> void:
	_state = "sweep"
	_state_t = 0.0
	_cooldown = 2.0
	_hitbox.damage = SWEEP_DAMAGE
	_hitbox.activate()
	var p = GameState.player
	_dir_sign = 1.0 if (p and p.global_position.x >= global_position.x) else -1.0


var _dir_sign: float = 1.0


func _do_sweep(delta: float) -> void:
	global_position.x += _dir_sign * 280.0 * delta
	global_position.y = lerpf(global_position.y, _hover_origin.y + 30.0, 4.0 * delta)
	_visual.rotation = lerpf(_visual.rotation, _dir_sign * 0.35, 8.0 * delta)
	if _state_t > 1.1:
		_visual.rotation = 0.0
		_hitbox.deactivate()
		_state = "hover"
		_state_t = 0.0


func _begin_flip() -> void:
	_state = "flip"
	_state_t = 0.0
	_cooldown = 2.6


func _do_flip(delta: float) -> void:
	## Fly toward high lever perch and slam every surviving lever ON.
	var gallery_y := _hover_origin.y - 70.0
	global_position.y = lerpf(global_position.y, gallery_y, 4.0 * delta)
	if _state_t > 0.55 and _state_t < 0.7:
		_force_all_levers_on()
	if _state_t > 1.1:
		_state = "hover"
		_state_t = 0.0


func _force_all_levers_on() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for sid in _switch_ids:
		var sw := tree.root.find_child(str(sid), true, false)
		if sw == null or sw.get_meta("smashed", false):
			continue
		if sw.has_method("set_powered"):
			sw.call("set_powered", true, true)


func _on_hurt(amount: int, from: Node) -> void:
	if _dying or not _awake or _hurt_cd > 0.0:
		return
	## Sword swings (and any other hit) each count as one wound toward MAX_HP.
	if amount <= 0:
		return
	_hurt_cd = HURT_IFRAMES
	hp -= 1
	_play_hurt_feedback(from)
	_update_phase()
	if hp <= 0:
		_start_defeat()


func _play_hurt_feedback(from: Node) -> void:
	## Flash the whole boss (art modulate alone is easy to miss on brass fill).
	modulate = Color(2.4, 2.4, 2.4, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.8, 0.25, 0.3, 1.0), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.16)
	## Nudge away from the attacker — hover lerps ignore CharacterBody velocity.
	var away := 1.0
	if from is Node2D and is_instance_valid(from):
		away = signf(global_position.x - (from as Node2D).global_position.x)
		if away == 0.0:
			away = 1.0
	global_position.x += away * 22.0
	global_position.y -= 10.0
	EnemyHitFX.play(_art if _art else _body_poly, null, null)
	_spawn_hit_sparks()


func _spawn_hit_sparks() -> void:
	var burst := Node2D.new()
	burst.z_index = 8
	add_child(burst)
	for i in 7:
		var spark := Polygon2D.new()
		var ang := TAU * float(i) / 7.0 + randf() * 0.4
		var r := 3.0 + randf() * 2.5
		spark.polygon = PackedVector2Array([
			Vector2(0, -r), Vector2(r * 0.6, 0), Vector2(0, r), Vector2(-r * 0.6, 0)
		])
		spark.color = Color(1.0, 0.85, 0.35, 1.0) if i % 2 == 0 else Color(1.0, 0.35, 0.25, 1.0)
		spark.position = Vector2(cos(ang), sin(ang)) * 6.0
		burst.add_child(spark)
		var dest := spark.position + Vector2(cos(ang), sin(ang)) * randf_range(28.0, 48.0)
		var tw := create_tween()
		tw.tween_property(spark, "position", dest, 0.22).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.22)
	var clear := create_tween()
	clear.tween_interval(0.25)
	clear.tween_callback(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func _update_phase() -> void:
	var ratio := float(hp) / float(MAX_HP)
	if ratio <= 0.33 and phase != Phase.THREE:
		phase = Phase.THREE
		_smash_switches(2)
	elif ratio <= 0.66 and phase == Phase.ONE:
		phase = Phase.TWO
		_smash_switches(1)


func _smash_switches(count: int) -> void:
	var smashed := 0
	for sid in _switch_ids:
		if smashed >= count:
			break
		var sw := get_tree().root.find_child(sid, true, false)
		if sw == null:
			continue
		if sw.get_meta("smashed", false):
			continue
		sw.set_meta("smashed", true)
		sw.modulate = Color(0.4, 0.35, 0.35, 0.7)
		if sw.has_method("set_process"):
			sw.set_process(false)
		smashed += 1


func _start_defeat() -> void:
	if _dying:
		return
	_dying = true
	_state = "cutscene"
	_hitbox.deactivate()
	if _art:
		_art.dying = true
		_art.flap = 0.8
	defeated.emit()
	## Zone owns the full cutscene; we just freeze here.
	set_physics_process(false)
