extends Area2D
class_name ShadowCrystalPiece
## Tower reward crystal — distinct from shade-heart fragments. Unlocks double jump.


@export var pickup_id: String = "tower_crystal_piece"
@export var display_name: String = "Shadow Crystal Piece"

var _bob_t: float = 0.0
var _root: Node2D
var _taken: bool = false
var _pop_vel: Vector2 = Vector2.ZERO
var _popping: bool = false


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
	add_to_group("shadow_crystal_pieces")


func pop_out() -> void:
	_popping = true
	_pop_vel = Vector2(randf_range(-60, 60), randf_range(-220, -140))


func _build_hit() -> void:
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	cs.shape = circle
	add_child(cs)


func _build_visual() -> void:
	_root = Node2D.new()
	add_child(_root)
	## Distinct from fragment: polished disc-piece with brass ring + deep umbra core.
	var ring := Polygon2D.new()
	ring.color = Color(0.72, 0.58, 0.32)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 14.0)
	ring.polygon = pts
	_root.add_child(ring)
	var inner := Polygon2D.new()
	inner.color = Color(0.18, 0.08, 0.32)
	var pts2 := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts2.append(Vector2(cos(a), sin(a)) * 9.0)
	inner.polygon = pts2
	_root.add_child(inner)
	var core := Polygon2D.new()
	core.color = Color(0.55, 0.2, 0.75, 0.95)
	core.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)
	])
	_root.add_child(core)
	var spark := Polygon2D.new()
	spark.color = Color(0.95, 0.85, 1.0, 0.9)
	spark.polygon = PackedVector2Array([
		Vector2(1, -3), Vector2(3, -1), Vector2(1, 0)
	])
	_root.add_child(spark)
	var label := Label.new()
	label.text = "Piece"
	label.position = Vector2(-18, -28)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
	_root.add_child(label)


func _process(delta: float) -> void:
	if _taken or _root == null:
		return
	if _popping:
		_pop_vel.y += 780.0 * delta
		position += _pop_vel * delta
		if _pop_vel.y > 0.0 and absf(_pop_vel.y) < 40.0:
			_popping = false
			_pop_vel = Vector2.ZERO
	_bob_t += delta
	_root.position.y = sin(_bob_t * 2.4) * 2.5
	_root.rotation = sin(_bob_t * 1.3) * 0.08


func _on_body(body: Node) -> void:
	if _taken:
		return
	if not (body is Player or (body and body.is_in_group("player"))):
		return
	_taken = true
	set_deferred("monitoring", false)
	if not GameState.collect_crystal_piece(pickup_id):
		queue_free()
		return
	## Hide immediately so a failed/interrupted tween can't leave the disc on the floor.
	if _root:
		_root.visible = false
	var overlay: Node = preload("res://scripts/ui/AbilityUnlockOverlay.gd").new()
	get_tree().root.add_child(overlay)
	if overlay.has_method("play_double_jump"):
		overlay.call("play_double_jump")
	## Tree-bound tween so unlock overlay / pause can't stall free forever.
	var tw := get_tree().create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(queue_free)
