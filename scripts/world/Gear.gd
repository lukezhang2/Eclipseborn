extends Node2D
class_name Gear
## Rotating gear that slides a linked platform (giant moving object stub).

@export var linked_path: NodePath
@export var rotate_speed: float = 40.0
@export var move_amplitude: float = 120.0
@export var player_can_spin: bool = true

var _angle: float = 0.0
var _base: Vector2
var _linked: Node2D
var _spinning: bool = true


func _ready() -> void:
	_build_visual()
	call_deferred("_resolve_link")
	# Occluder disk so gears cast shadows.
	var occ := ShadowOccluder.new()
	occ.local_polygon = _circle_poly(28.0, 10)
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
	# Gear Sense later: remote spin. For now always spins (or when player nearby).
	_angle += deg_to_rad(rotate_speed) * delta
	rotation = _angle
	if _linked:
		_linked.position = _base + Vector2(sin(_angle) * move_amplitude, 0.0)
		ShadowWorld.mark_dirty()


func _build_visual() -> void:
	var disk := Polygon2D.new()
	disk.polygon = _circle_poly(30.0, 12)
	disk.color = Color(0.4, 0.38, 0.35)
	add_child(disk)
	for i in 6:
		var tooth := Polygon2D.new()
		tooth.color = Color(0.55, 0.4, 0.2)
		tooth.polygon = PackedVector2Array([
			Vector2(-4, -34), Vector2(4, -34), Vector2(3, -26), Vector2(-3, -26)
		])
		tooth.rotation = i * TAU / 6.0
		add_child(tooth)


func _circle_poly(radius: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		out.append(Vector2(cos(a), sin(a)) * radius)
	return out
