extends Area2D
class_name Hitbox
## Active attack volume. Exists only during active frames; hits each target once per swing.

@export var team: String = "player"
@export var damage: int = 10
@export var owner_body: Node = null

var _hit_ids: Dictionary = {}
var _active: bool = false


func _ready() -> void:
	collision_layer = 32  # hitbox
	collision_mask = 16   # hurtbox
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


func activate() -> void:
	_hit_ids.clear()
	_active = true
	monitoring = true


func deactivate() -> void:
	_active = false
	monitoring = false
	_hit_ids.clear()


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if not area is Hurtbox:
		return
	var hurt := area as Hurtbox
	if hurt.team == team:
		return
	var id := hurt.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	hurt.apply_hit(damage, owner_body)
