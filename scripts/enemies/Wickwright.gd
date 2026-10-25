extends CharacterBody2D
class_name Wickwright
## Clockwork Tower apex boss — flies, flips gallery lamps, Match-the-Hour heart.


signal defeated

const MAX_HP := 160
const DIVE_DAMAGE := 18
const SWEEP_DAMAGE := 14

enum Phase { ONE, TWO, THREE }

var hp: int = MAX_HP
var phase: Phase = Phase.ONE
var _state: String = "dormant"
var _state_t: float = 0.0
var _cooldown: float = 1.2
var _hurt_cd: float = 0.0
var _heart_open: bool = false
var _heart_t: float = 0.0
var _target_pattern: Array = [true, false, true] ## A B C lamps that should be ON
var _dying: bool = false
var _awake: bool = false
var _hover_origin: Vector2 = Vector2.ZERO
var _dive_target: Vector2 = Vector2.ZERO
var _visual: Node2D
var _body_poly: Polygon2D
var _heart_poly: Polygon2D
var _dial_label: Label
var _wings: Array = []
var _hurtbox: Hurtbox
var _hitbox: Hitbox
var _lamp_ids: PackedStringArray = PackedStringArray(["tower_lamp_a", "tower_lamp_b", "tower_lamp_c"])
var _switch_ids: PackedStringArray = PackedStringArray(["tower_switch_a", "tower_switch_b", "tower_switch_c"])


func _ready() -> void:
	hp = MAX_HP
	collision_layer = 0
	collision_mask = 0
	_hover_origin = global_position
	_build()
	_roll_pattern()
	add_to_group("enemies")
	add_to_group("bosses")
	name = "Wickwright"
	## Sleep until the arena wake trigger fires.
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	if _dial_label:
		_dial_label.visible = false


func awaken() -> void:
	if _awake or _dying:
		return
	_awake = true
	_state = "hover"
	_cooldown = 0.8
	_hover_origin = global_position
	if _hurtbox:
		_hurtbox.monitorable = true
	if _dial_label:
		_dial_label.visible = true
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("The Wickwright stirs — match the Hour.", 3.5)


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

	_dial_label = Label.new()
	_dial_label.position = Vector2(-40, -56)
	_dial_label.add_theme_font_size_override("font_size", 13)
	_dial_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_visual.add_child(_dial_label)
	_refresh_dial_label()

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(40, 56)
	hcs.shape = hr
	hcs.position = Vector2(0, 0)
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


func _refresh_dial_label() -> void:
	if _dial_label == null:
		return
	var marks := ""
	for i in _target_pattern.size():
		marks += "I" if _target_pattern[i] else "·"
		if i < _target_pattern.size() - 1:
			marks += " "
	_dial_label.text = "Hour  %s" % marks


func _roll_pattern() -> void:
	_target_pattern = []
	var on_count := 0
	for i in 3:
		var on := randf() > 0.45
		_target_pattern.append(on)
		if on:
			on_count += 1
	if on_count == 0:
		_target_pattern[randi() % 3] = true
	if on_count == 3:
		_target_pattern[randi() % 3] = false
	_refresh_dial_label()


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
		## Idle hover bob while dormant — no attacks, no heart logic.
		var bob := Vector2(sin(Time.get_ticks_msec() * 0.0015) * 12.0, cos(Time.get_ticks_msec() * 0.002) * 8.0)
		global_position = global_position.lerp(_hover_origin + bob, clampf(2.0 * delta, 0.0, 1.0))
		return
	_update_heart(delta)
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


func _update_heart(delta: float) -> void:
	var match_ok := _pattern_matches()
	if match_ok and not _heart_open:
		_heart_open = true
		_heart_t = 4.5 if phase != Phase.THREE else 6.0
		AudioManager.play_break()
	if _heart_open:
		_heart_t -= delta
		_heart_poly.color.a = 0.95
		_body_poly.color = Color(0.45, 0.32, 0.22)
		if _heart_t <= 0.0:
			_heart_open = false
			_roll_pattern()
	else:
		_heart_poly.color.a = 0.15
		_body_poly.color = Color(0.32, 0.28, 0.24)


func _pattern_matches() -> bool:
	for i in _lamp_ids.size():
		var want: bool = _target_pattern[i]
		var lamp := _find_lamp(_lamp_ids[i])
		var is_on := true
		if lamp and lamp.has_method("is_on"):
			is_on = lamp.is_on()
		if is_on != want:
			return false
	return true


func _find_lamp(id: String) -> Node:
	for lamp in get_tree().get_nodes_in_group("lights"):
		if str(lamp.get_meta("catalog_id", "")) == id or lamp.name == id:
			return lamp
	return get_tree().root.find_child(id, true, false)


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
	## Fly toward high lever perch and yank a switch (turns floor lanterns).
	var gallery_y := _hover_origin.y - 70.0
	global_position.y = lerpf(global_position.y, gallery_y, 4.0 * delta)
	if _state_t > 0.55 and _state_t < 0.7:
		_yank_random_switch()
	if _state_t > 1.1:
		_state = "hover"
		_state_t = 0.0


func _yank_random_switch() -> void:
	if _switch_ids.is_empty():
		return
	var sid := _switch_ids[randi() % _switch_ids.size()]
	var sw := get_tree().root.find_child(sid, true, false)
	if sw == null:
		return
	if sw.get_meta("smashed", false):
		return
	if sw.has_method("interact"):
		sw.interact()


func _on_hurt(amount: int, from: Node) -> void:
	if _dying or not _awake:
		return
	var dmg := amount
	if not _heart_open:
		dmg = maxi(1, int(amount * 0.2)) ## armor chip
	hp -= dmg
	EnemyHitFX.play(_body_poly, self, from)
	if _heart_open:
		EnemyHitFX.play(_heart_poly, null, null)
	_update_phase()
	if hp <= 0:
		_start_defeat()


func _update_phase() -> void:
	var ratio := float(hp) / float(MAX_HP)
	if ratio <= 0.33 and phase != Phase.THREE:
		phase = Phase.THREE
		_smash_switches(2)
		_roll_pattern()
	elif ratio <= 0.66 and phase == Phase.ONE:
		phase = Phase.TWO
		_smash_switches(1)
		_roll_pattern()


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
	defeated.emit()
	## Zone owns the full cutscene; we just freeze here.
	set_physics_process(false)
