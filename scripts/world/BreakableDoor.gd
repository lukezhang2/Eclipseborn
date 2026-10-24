extends StaticBody2D
class_name BreakableDoor
## Iron hatch broken by one F attack. Leads into the next room/zone.

signal broken

@export var door_size: Vector2 = Vector2(20, 72)
@export var next_scene: String = ""
@export var hint_text: String = "Press F to break the hatch"

var _broken: bool = false
var _hurtbox: Hurtbox
var _visual: Polygon2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("breakable_doors")


func _build() -> void:
	var half := door_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)

	_visual = Polygon2D.new()
	_visual.polygon = poly
	_visual.color = Color(0.28, 0.3, 0.34)
	add_child(_visual)

	var bar := Polygon2D.new()
	bar.polygon = PackedVector2Array([
		Vector2(-half.x - 2, -8), Vector2(half.x + 2, -8),
		Vector2(half.x + 2, 8), Vector2(-half.x - 2, 8)
	])
	bar.color = Color(0.55, 0.4, 0.2)
	add_child(bar)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = door_size
	hcs.shape = rect
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)


func _on_hurt(_amount: int, _from: Node) -> void:
	if _broken:
		return
	_broken = true
	broken.emit()
	# Shatter visually then disable collision.
	_visual.color = Color(0.2, 0.2, 0.22, 0.3)
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitorable", false)
	await get_tree().create_timer(0.15).timeout
	if next_scene != "":
		GameState.set_paused(false)
		get_tree().change_scene_to_file(next_scene)
	queue_free()
