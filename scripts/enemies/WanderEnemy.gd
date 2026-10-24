extends CharacterBody2D
class_name WanderEnemy
## Simple patrol: walks back and forth, flips on walls, damages on contact.

@export var move_speed: float = 55.0
@export var attack_damage: int = 10
@export var max_hp: int = 24

var hp: int = 24
var _dir: float = 1.0
var _hurt_cd: float = 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 1 | 4
	hurtbox.team = "enemy"
	hurtbox.owner_body = self
	hurtbox.hurt.connect(_on_hurt)
	hitbox.team = "enemy"
	hitbox.owner_body = self
	hitbox.damage = attack_damage
	hitbox.monitoring = true
	# Keep a small always-on contact hurt volume
	hitbox.activate()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return
	_hurt_cd = maxf(0.0, _hurt_cd - delta)
	velocity.x = _dir * move_speed
	velocity.y += 980.0 * delta
	move_and_slide()
	if is_on_wall():
		_dir *= -1.0
	# Also flip if no floor ahead
	if is_on_floor():
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(_dir * 16.0, -4.0)
		var to := from + Vector2(0, 28)
		var q := PhysicsRayQueryParameters2D.create(from, to)
		q.collision_mask = 1
		q.exclude = [self]
		if space.intersect_ray(q).is_empty():
			_dir *= -1.0
	visual.scale.x = -1.0 if _dir < 0.0 else 1.0
	_touch_damage()


func _touch_damage() -> void:
	if _hurt_cd > 0.0:
		return
	var p = GameState.player
	if p == null or not is_instance_valid(p):
		return
	if global_position.distance_to(p.global_position) < 28.0:
		GameState.take_damage(attack_damage)
		_hurt_cd = 0.8


func _on_hurt(amount: int, _from: Node) -> void:
	hp -= amount
	visual.modulate = Color(1.6, 1.6, 1.6)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return
	visual.modulate = Color.WHITE
	if hp <= 0:
		queue_free()
