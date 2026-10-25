extends Area2D
class_name Hitbox
## Active attack volume. Hits each target once per swing (including already-overlapping).

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
	add_to_group("hitboxes")
	area_entered.connect(_on_area_entered)


func activate() -> void:
	_hit_ids.clear()
	_active = true
	monitoring = true
	# area_entered only fires on enter — catch pots already overlapping when the swing starts.
	call_deferred("_scan_overlaps")


func _scan_overlaps() -> void:
	if not _active or not monitoring:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)


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
	## Only the player's swing should chirp on connect (enemy hitboxes stay silent here).
	if team == "player":
		AudioManager.play_hit_connect()
