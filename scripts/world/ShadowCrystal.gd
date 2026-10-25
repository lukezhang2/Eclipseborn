extends Area2D
class_name ShadowCrystal
## One-time permanent upgrade: a jagged shadow-crystal fragment.
## Collected ids persist in the save — leaving/rejoining the zone never respawns it.


@export var pickup_id: String = "shade_heart"
@export var display_name: String = "Shadow Crystal Fragment"

var _bob_t: float = 0.0
var _root: Node2D
var _taken: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	if GameState.is_collected(pickup_id):
		queue_free()
		return
	_build_hit()
	_build_visual()
	body_entered.connect(_on_body)
	add_to_group("shadow_crystals")


func _build_hit() -> void:
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	cs.shape = circle
	cs.position = Vector2(0, -4)
	add_child(cs)


func _build_visual() -> void:
	_root = Node2D.new()
	_root.name = "Visual"
	add_child(_root)

	## Soft ground shadow
	var shadow := Polygon2D.new()
	shadow.color = Color(0.02, 0.02, 0.05, 0.45)
	shadow.polygon = PackedVector2Array([
		Vector2(-14, 10), Vector2(14, 10), Vector2(10, 16), Vector2(-10, 16)
	])
	shadow.z_index = -1
	_root.add_child(shadow)

	## Outer dark shell — asymmetric shard
	var shell := Polygon2D.new()
	shell.color = Color(0.08, 0.06, 0.14)
	shell.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(11, -8), Vector2(14, 2), Vector2(6, 14),
		Vector2(-4, 12), Vector2(-13, 4), Vector2(-10, -10)
	])
	_root.add_child(shell)

	## Recessed facet (depth)
	var recess := Polygon2D.new()
	recess.color = Color(0.04, 0.03, 0.08, 0.95)
	recess.polygon = PackedVector2Array([
		Vector2(-1, -12), Vector2(7, -4), Vector2(8, 4), Vector2(1, 8), Vector2(-7, 2), Vector2(-6, -6)
	])
	_root.add_child(recess)

	## Mid violet crystal body
	var body := Polygon2D.new()
	body.color = Color(0.28, 0.14, 0.42, 0.92)
	body.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(8, -5), Vector2(9, 3), Vector2(2, 10),
		Vector2(-5, 8), Vector2(-9, 0), Vector2(-6, -8)
	])
	_root.add_child(body)

	## Cool edge highlight (left)
	var edge_l := Polygon2D.new()
	edge_l.color = Color(0.55, 0.45, 0.85, 0.55)
	edge_l.polygon = PackedVector2Array([
		Vector2(-1, -13), Vector2(-5, -7), Vector2(-8, 0), Vector2(-4, 6), Vector2(-1, 2), Vector2(-2, -6)
	])
	_root.add_child(edge_l)

	## Bright ridge highlight (top-right)
	var ridge := Polygon2D.new()
	ridge.color = Color(0.72, 0.62, 0.95, 0.7)
	ridge.polygon = PackedVector2Array([
		Vector2(1, -13), Vector2(7, -6), Vector2(5, -2), Vector2(1, -5)
	])
	_root.add_child(ridge)

	## Inner umbra core
	var core := Polygon2D.new()
	core.color = Color(0.12, 0.05, 0.22, 0.85)
	core.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(4, 0), Vector2(1, 5), Vector2(-3, 2), Vector2(-3, -2)
	])
	_root.add_child(core)

	## Specular glint
	var glint := Polygon2D.new()
	glint.color = Color(0.92, 0.88, 1.0, 0.85)
	glint.polygon = PackedVector2Array([
		Vector2(2, -10), Vector2(5, -7), Vector2(3, -6)
	])
	_root.add_child(glint)

	## Soft halo (atmosphere)
	var halo := Polygon2D.new()
	halo.color = Color(0.35, 0.2, 0.55, 0.18)
	halo.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, -4), Vector2(12, 16), Vector2(-12, 14), Vector2(-16, -6)
	])
	halo.z_index = -2
	_root.add_child(halo)

	## Fracture line etch
	var crack := Line2D.new()
	crack.width = 1.2
	crack.default_color = Color(0.15, 0.08, 0.28, 0.75)
	crack.points = PackedVector2Array([Vector2(-2, -8), Vector2(1, 0), Vector2(-1, 7)])
	_root.add_child(crack)

	var label := Label.new()
	label.text = display_name
	label.position = Vector2(-52, -36)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.85, 0.75))
	_root.add_child(label)


func _process(delta: float) -> void:
	if _taken or _root == null:
		return
	_bob_t += delta
	_root.position.y = sin(_bob_t * 2.2) * 3.0
	_root.rotation = sin(_bob_t * 1.1) * 0.06


func _on_body(body: Node) -> void:
	if _taken:
		return
	if not (body is Player or (body and body.is_in_group("player"))):
		return
	_taken = true
	if not GameState.collect_shadow_crystal(pickup_id):
		queue_free()
		return
	_play_collect()


func _play_collect() -> void:
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.set_parallel(true)
	if _root:
		tw.tween_property(_root, "scale", Vector2(1.6, 1.6), 0.22)
		tw.tween_property(_root, "modulate:a", 0.0, 0.28)
	await tw.finished
	queue_free()
