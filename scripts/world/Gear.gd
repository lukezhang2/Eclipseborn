extends Node2D
class_name Gear
## Rotating gear with real teeth that slides a linked platform.

@export var linked_path: NodePath
@export var rotate_speed: float = 40.0
@export var move_amplitude: float = 120.0
@export var player_can_spin: bool = true
@export var tooth_count: int = 12
@export var radius: float = 30.0

var _angle: float = 0.0
var _base: Vector2
var _linked: Node2D
var _spinning: bool = true


func _ready() -> void:
	_build_visual()
	call_deferred("_resolve_link")
	var occ := ShadowOccluder.new()
	occ.local_polygon = _circle_poly(radius * 0.9, 14)
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
	# Outer ring
	var ring := Polygon2D.new()
	ring.polygon = _ring_poly(radius, radius * 0.72, 28)
	ring.color = Color(0.38, 0.36, 0.33)
	add_child(ring)
	# Hub
	var hub := Polygon2D.new()
	hub.polygon = _circle_poly(radius * 0.28, 16)
	hub.color = Color(0.55, 0.42, 0.22)
	add_child(hub)
	var hub_hole := Polygon2D.new()
	hub_hole.polygon = _circle_poly(radius * 0.1, 10)
	hub_hole.color = Color(0.12, 0.1, 0.09)
	add_child(hub_hole)
	# Spokes
	for i in 4:
		var spoke := Polygon2D.new()
		spoke.color = Color(0.45, 0.4, 0.32)
		spoke.polygon = PackedVector2Array([
			Vector2(-2.5, -radius * 0.65), Vector2(2.5, -radius * 0.65),
			Vector2(2.5, -radius * 0.3), Vector2(-2.5, -radius * 0.3),
		])
		spoke.rotation = i * TAU / 4.0
		add_child(spoke)
	# Teeth
	for i in tooth_count:
		var tooth := Polygon2D.new()
		tooth.color = Color(0.5, 0.38, 0.2)
		var tw := radius * 0.18
		var th := radius * 0.28
		tooth.polygon = PackedVector2Array([
			Vector2(-tw, -radius), Vector2(tw, -radius),
			Vector2(tw * 0.7, -radius + th), Vector2(-tw * 0.7, -radius + th),
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
