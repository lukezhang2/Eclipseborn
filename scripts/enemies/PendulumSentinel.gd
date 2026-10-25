extends Node2D
class_name PendulumSentinel
## Ceiling clock-hand that swings. Blade only damages while a linked lamp is on.


@export var swing_amp_deg: float = 55.0
@export var swing_speed: float = 1.15
@export var arm_length: float = 120.0
@export var attack_damage: int = 14
@export var max_hp: int = 40
@export var lamp_id: String = ""

var hp: int = 40
var _t: float = 0.0
var _blade: Node2D
var _hurtbox: Hurtbox
var _hitbox: Hitbox
var _visual: Polygon2D


func _ready() -> void:
	hp = max_hp
	_t = randf() * TAU
	_build()
	add_to_group("enemies")


func _build() -> void:
	var hub := Polygon2D.new()
	hub.color = Color(0.55, 0.42, 0.25)
	hub.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	add_child(hub)

	_blade = Node2D.new()
	add_child(_blade)
	_visual = Polygon2D.new()
	_visual.color = Color(0.35, 0.3, 0.28)
	_visual.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(10, arm_length), Vector2(0, arm_length + 14), Vector2(-10, arm_length)
	])
	_blade.add_child(_visual)
	var eye := Polygon2D.new()
	eye.color = Color(0.75, 0.35, 0.85)
	eye.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
	])
	_blade.add_child(eye)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(18, arm_length * 0.55)
	hcs.shape = hr
	hcs.position = Vector2(0, arm_length * 0.55)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	_blade.add_child(_hurtbox)

	_hitbox = Hitbox.new()
	_hitbox.team = "enemy"
	_hitbox.owner_body = self
	_hitbox.damage = attack_damage
	var ics := CollisionShape2D.new()
	var ir := RectangleShape2D.new()
	ir.size = Vector2(22, 28)
	ics.shape = ir
	ics.position = Vector2(0, arm_length + 4)
	_hitbox.add_child(ics)
	_blade.add_child(_hitbox)
	_hitbox.activate()


func _process(delta: float) -> void:
	if GameState.is_paused or GameState.intro_cutscene_playing:
		return
	_t += delta * swing_speed
	var ang := sin(_t) * deg_to_rad(swing_amp_deg)
	_blade.rotation = ang
	var lit := _lamp_is_on()
	_visual.modulate = Color(1, 1, 1, 1) if lit else Color(0.45, 0.4, 0.5, 0.45)
	if lit:
		if not _hitbox.monitoring:
			_hitbox.activate()
	else:
		if _hitbox.monitoring:
			_hitbox.deactivate()


func _lamp_is_on() -> bool:
	if lamp_id == "":
		return true
	for lamp in get_tree().get_nodes_in_group("lights"):
		if str(lamp.get_meta("catalog_id", lamp.name)) == lamp_id or lamp.name == lamp_id:
			return lamp.has_method("is_on") and lamp.is_on()
	var by_name := get_tree().root.find_child(lamp_id, true, false)
	if by_name and by_name.has_method("is_on"):
		return by_name.is_on()
	return true


func _on_hurt(amount: int, from: Node) -> void:
	hp -= amount
	EnemyHitFX.play(_visual, self, from)
	if hp <= 0:
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			queue_free()
