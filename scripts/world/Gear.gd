extends Node2D
class_name Gear
## Real toothed gear that slides a linked platform.

@export var linked_path: NodePath
@export var rotate_speed: float = 40.0
@export var move_amplitude: float = 120.0
@export var player_can_spin: bool = true
@export var tooth_count: int = 14
@export var radius: float = 32.0

var _angle: float = 0.0
var _base: Vector2
var _linked: Node2D
var _spinning: bool = true


func _ready() -> void:
	_build_visual()
	call_deferred("_resolve_link")
	var occ := ShadowOccluder.new()
	occ.local_polygon = _circle_poly(radius * 0.85, 14)
	add_child(occ)
	add_to_group("gears")


func bind_platform(node: Node2D) -> void:
	_linked = node
	if _linked:
		_base = _linked.position


func _resolve_link() -> void:
	if linked_path != NodePath(""):
		_linked = get_node_or_null(linked_path) as Node2D
		if _linked:
			_base = _linked.position


func _physics_process(delta: float) -> void:
	if GameState.is_paused or not _spinning:
		return
	_angle += deg_to_rad(rotate_speed) * delta
	rotation = _angle
	if _linked:
		_linked.position = _base + Vector2(sin(_angle) * move_amplitude, 0.0)
		ShadowWorld.mark_dirty()


func _build_visual() -> void:
	var steel := Color(0.48, 0.46, 0.42)
	var disc := Polygon2D.new()
	disc.polygon = _circle_poly(radius * 0.86, 28)
	disc.color = steel.darkened(0.2)
	add_child(disc)
	var ring := Polygon2D.new()
	ring.polygon = _ring_poly(radius * 0.86, radius * 0.6, 28)
	ring.color = steel
	add_child(ring)
	for i in 5:
		var spoke := Polygon2D.new()
		spoke.color = steel.lightened(0.15)
		spoke.polygon = PackedVector2Array([
			Vector2(-3.5, -radius * 0.58), Vector2(3.5, -radius * 0.58),
			Vector2(2.8, -radius * 0.28), Vector2(-2.8, -radius * 0.28),
		])
		spoke.rotation = i * TAU / 5.0
		add_child(spoke)
	var hub := Polygon2D.new()
	hub.polygon = _circle_poly(radius * 0.26, 16)
	hub.color = Color(0.55, 0.42, 0.22)
	add_child(hub)
	var hole := Polygon2D.new()
	hole.polygon = _circle_poly(radius * 0.09, 10)
	hole.color = Color(0.08, 0.07, 0.06)
	add_child(hole)
	for i in tooth_count:
		var tooth := Polygon2D.new()
		tooth.color = steel.lightened(0.12)
		var tw := radius * 0.13
		var th := radius * 0.22
		tooth.polygon = PackedVector2Array([
			Vector2(-tw, -radius * 0.84), Vector2(tw, -radius * 0.84),
			Vector2(tw * 0.7, -radius * 0.84 - th), Vector2(-tw * 0.7, -radius * 0.84 - th),
		])
		tooth.rotation = i * TAU / float(tooth_count)
		add_child(tooth)


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
