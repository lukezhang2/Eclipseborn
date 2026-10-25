extends StaticBody2D
class_name BreakableProp
## Glowing breakable that pops silver gear currency when smashed.

@export var breakable_id: String = ""
@export var prop_size: Vector2 = Vector2(28, 36)
@export var currency_drops: int = 2

var _broken: bool = false
var _hurtbox: Hurtbox
var _visual: Node2D


func _ready() -> void:
	if GameState.is_broken(breakable_id):
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("breakables")


func _build() -> void:
	var half := prop_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)

	_visual = Node2D.new()
	add_child(_visual)
	# Clay jar that glows from its mouth (no aura around it).
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.POT
	art.style = 14
	art.size = prop_size
	_visual.add_child(art)

	var occ := ShadowOccluder.new()
	occ.local_polygon = poly
	add_child(occ)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# Slightly larger than the jar so close swings still connect.
	rect.size = prop_size + Vector2(14, 10)
	hcs.shape = rect
	hcs.position = Vector2(0, -2)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)


func _on_hurt(_amount: int, _from: Node) -> void:
	if _broken:
		return
	_broken = true
	GameState.mark_broken(breakable_id)
	AudioManager.play_break()
	# Spawn silver gears with a little pop.
	for i in currency_drops:
		var gear := CurrencyPickup.new()
		gear.pop_velocity = Vector2(randf_range(-110, 110), randf_range(-260, -140))
		get_parent().add_child(gear)
		gear.global_position = global_position + Vector2(randf_range(-6, 6), -10)
		gear.velocity = gear.pop_velocity
	# Shatter fade
	if _visual:
		_visual.modulate.a = 0.3
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_deferred("disabled", true)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	await get_tree().create_timer(0.2).timeout
	SaveManager.autosave()
	queue_free()
