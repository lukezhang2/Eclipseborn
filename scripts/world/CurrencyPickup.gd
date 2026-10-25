extends CharacterBody2D
class_name CurrencyPickup
## Silver gear pickup. Spreads, bounces on floors/walls, then can be collected.

const PICKUP_RADIUS := 52.0
const MAGNET_RADIUS := 90.0
const VALUE := 1
## Brief pop before the player can collect (also used for fade-in).
const PICKUP_DELAY := 0.25
const BODY_RADIUS := 8.0
## Default loot when a normal enemy dies.
const ENEMY_DROP_MIN := 2
const ENEMY_DROP_MAX := 3

var pop_velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _visual: Node2D
var _age: float = 0.0
var _can_pickup: bool = false
var _pickup_area: Area2D


## Scatter silver gears from a kill / smash point. `count` ≤ 0 → random enemy drop size.
static func spawn_burst(parent: Node, at: Vector2, count: int = 0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var n := count if count > 0 else randi_range(ENEMY_DROP_MIN, ENEMY_DROP_MAX)
	for _i in n:
		var gear := CurrencyPickup.new()
		gear.pop_velocity = Vector2(randf_range(-110, 110), randf_range(-260, -140))
		parent.add_child(gear)
		gear.global_position = at + Vector2(randf_range(-6, 6), -10)
		gear.velocity = gear.pop_velocity


func _ready() -> void:
	# Solid vs world geometry; not on a layer the player walks into.
	collision_layer = 0
	collision_mask = 1
	up_direction = Vector2.UP
	floor_stop_on_slope = true
	_build_body()
	_build_visual()
	_build_pickup_area()
	velocity = pop_velocity
	add_to_group("currency")


func _build_body() -> void:
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS
	cs.shape = circle
	add_child(cs)


func _build_pickup_area() -> void:
	_pickup_area = Area2D.new()
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = 2
	_pickup_area.monitoring = true
	_pickup_area.monitorable = false
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	cs.shape = circle
	_pickup_area.add_child(cs)
	_pickup_area.body_entered.connect(_on_body)
	add_child(_pickup_area)


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
		velocity.y += 980.0 * delta
		move_and_slide()
		if is_on_floor():
			velocity.y = 0.0
			velocity.x *= 0.82
			if absf(velocity.x) < 12.0:
				velocity.x = 0.0
		if is_on_wall():
			velocity.x *= -0.55
		_clamp_to_map()
		if _age >= PICKUP_DELAY:
			_can_pickup = true
			velocity = Vector2.ZERO
		return

	_clamp_to_map()
	var player = GameState.player
	if player == null or not is_instance_valid(player):
		return
	var to_p: Vector2 = (player as Node2D).global_position + Vector2(0, -18) - global_position
	var dist := to_p.length()
	if dist <= PICKUP_RADIUS:
		_collect()
		return
	if dist <= MAGNET_RADIUS:
		# Magnet phase — no world collision so it can float to the player.
		global_position += to_p.normalized() * 220.0 * delta


func _clamp_to_map() -> void:
	var min_x := GameState.map_min_x + BODY_RADIUS
	var max_x := GameState.map_max_x - BODY_RADIUS
	if global_position.x < min_x:
		global_position.x = min_x
		velocity.x = absf(velocity.x) * 0.5
	elif global_position.x > max_x:
		global_position.x = max_x
		velocity.x = -absf(velocity.x) * 0.5


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
