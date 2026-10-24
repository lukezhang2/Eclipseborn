extends Area2D
class_name CurrencyPickup
## Silver gear pickup. Spreads for a moment before it can be collected.

const PICKUP_RADIUS := 52.0
const MAGNET_RADIUS := 90.0
const VALUE := 1
const PICKUP_DELAY := 1.0

var pop_velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _visual: Node2D
var _age: float = 0.0
var _can_pickup: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	cs.shape = circle
	add_child(cs)
	_build_visual()
	body_entered.connect(_on_body)
	add_to_group("currency")


func _build_visual() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	var ring := Polygon2D.new()
	ring.polygon = _ring_poly(10.0, 6.5, 16)
	ring.color = Color(0.78, 0.82, 0.88)
	_visual.add_child(ring)
	var hub := Polygon2D.new()
	hub.polygon = _circle_poly(3.5, 10)
	hub.color = Color(0.92, 0.94, 0.98)
	_visual.add_child(hub)
	for i in 8:
		var tooth := Polygon2D.new()
		tooth.color = Color(0.7, 0.74, 0.8)
		tooth.polygon = PackedVector2Array([
			Vector2(-2.2, -11), Vector2(2.2, -11),
			Vector2(1.6, -8), Vector2(-1.6, -8),
		])
		tooth.rotation = i * TAU / 8.0
		_visual.add_child(tooth)


func _physics_process(delta: float) -> void:
	_age += delta
	_spin += delta * 4.0
	if _visual:
		_visual.rotation = _spin
		_visual.modulate.a = 0.55 + 0.45 * clampf(_age / PICKUP_DELAY, 0.0, 1.0)
	if not _can_pickup:
		pop_velocity.y += 900.0 * delta
		pop_velocity.x = move_toward(pop_velocity.x, 0.0, 40.0 * delta)
		position += pop_velocity * delta
		if _age >= PICKUP_DELAY:
			_can_pickup = true
			pop_velocity = Vector2.ZERO
		return

	var player = GameState.player
	if player == null or not is_instance_valid(player):
		return
	var to_p: Vector2 = (player as Node2D).global_position + Vector2(0, -18) - global_position
	var dist := to_p.length()
	if dist <= PICKUP_RADIUS:
		_collect()
		return
	if dist <= MAGNET_RADIUS:
		global_position += to_p.normalized() * 220.0 * delta


func _on_body(body: Node) -> void:
	if not _can_pickup:
		return
	if body is Player or body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if not _can_pickup:
		return
	_can_pickup = false
	AudioManager.play_currency()
	GameState.add_currency(VALUE)
	SaveManager.autosave()
	queue_free()


func _circle_poly(r: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


func _ring_poly(outer: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * outer)
	for i in range(points - 1, -1, -1):
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * inner)
	return out
