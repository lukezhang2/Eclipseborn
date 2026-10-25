extends CharacterBody2D
class_name BasicEnemy
## Simple shadow enemy with hurtbox + a short melee hitbox. Prototype combat target.

@export var max_hp: int = 30
@export var move_speed: float = 60.0
@export var attack_damage: int = 8
@export var attack_cooldown: float = 1.2

var hp: int
var _cooldown: float = 0.0
var _attacking: bool = false

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	hp = max_hp
	# Layer 0: stand on world via mask, but do not body-block the player (damage via hit/hurt Areas).
	collision_layer = 0
	collision_mask = 1 | 4
	hurtbox.team = "enemy"
	hurtbox.owner_body = self
	hurtbox.hurt.connect(_on_hurt)
	hitbox.team = "enemy"
	hitbox.owner_body = self
	hitbox.damage = attack_damage
	hitbox.deactivate()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var player := GameState.player
	if player and is_instance_valid(player):
		var dir := signf(player.global_position.x - global_position.x)
		velocity.x = dir * move_speed
		velocity.y += 980.0 * delta
		move_and_slide()
		if not _attacking and _cooldown <= 0.0 and absf(player.global_position.x - global_position.x) < 48.0:
			_do_attack()
	# Pogo: if player lands on top, bounce them (handled in player via enemy group check later).
	_check_pogo()


func _do_attack() -> void:
	_attacking = true
	_cooldown = attack_cooldown
	hitbox.position = Vector2(24.0 * signf(velocity.x if velocity.x != 0.0 else 1.0), -10.0)
	hitbox.activate()
	await get_tree().create_timer(0.12).timeout
	hitbox.deactivate()
	_attacking = false


func _check_pogo() -> void:
	var player := GameState.player
	if not player or not is_instance_valid(player):
		return
	if player.velocity.y > 50.0:
		var delta_pos: Vector2 = player.global_position - global_position
		if absf(delta_pos.x) < 22.0 and delta_pos.y < -20.0 and delta_pos.y > -50.0:
			player.velocity.y = -320.0
			_on_hurt(8, player)


func _on_hurt(amount: int, _from: Node) -> void:
	hp -= amount
	visual.modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return
	visual.modulate = Color.WHITE
	if hp <= 0:
		_die()


func _die() -> void:
	# Ash break-apart: fade and free.
	var tw := create_tween()
	tw.tween_property(visual, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()
