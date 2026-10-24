extends Area2D
class_name Hurtbox
## The part of a body that can take a hit.

signal hurt(amount: int, from: Node)

@export var team: String = "player"  # "player" or "enemy"
@export var owner_body: Node = null


func _ready() -> void:
	collision_layer = 16  # hurtbox
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("hurtboxes")


func apply_hit(amount: int, from: Node) -> void:
	hurt.emit(amount, from)
