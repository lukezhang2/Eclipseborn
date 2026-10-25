extends Area2D
class_name Ladder
## Brass climb ladder. Overlap + hold look_up (W) / look_down to climb.


@export var ladder_height: float = 200.0
@export var ladder_width: float = 28.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 ## Player CharacterBody2D
	monitoring = true
	monitorable = false
	add_to_group("ladders")
	_build_shape()
	_build_art()


func _build_shape() -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	## Position is the bottom of the ladder (floor top). Shape extends upward.
	rect.size = Vector2(ladder_width + 10.0, ladder_height)
	cs.shape = rect
	cs.position = Vector2(0.0, -ladder_height * 0.5)
	add_child(cs)


func _build_art() -> void:
	var art := Node2D.new()
	art.z_index = -1
	add_child(art)
	var hx := ladder_width * 0.5
	## Side rails
	var left := Polygon2D.new()
	left.color = Color(0.42, 0.34, 0.22)
	left.polygon = PackedVector2Array([
		Vector2(-hx - 3, 2), Vector2(-hx + 2, 2),
		Vector2(-hx + 2, -ladder_height - 2), Vector2(-hx - 3, -ladder_height - 2)
	])
	art.add_child(left)
	var right := Polygon2D.new()
	right.color = Color(0.42, 0.34, 0.22)
	right.polygon = PackedVector2Array([
		Vector2(hx - 2, 2), Vector2(hx + 3, 2),
		Vector2(hx + 3, -ladder_height - 2), Vector2(hx - 2, -ladder_height - 2)
	])
	art.add_child(right)
	## Highlight edges
	var gleam := Polygon2D.new()
	gleam.color = Color(0.62, 0.52, 0.32, 0.55)
	gleam.polygon = PackedVector2Array([
		Vector2(-hx - 2, 0), Vector2(-hx, 0),
		Vector2(-hx, -ladder_height), Vector2(-hx - 2, -ladder_height)
	])
	art.add_child(gleam)
	## Rungs
	var step := 18.0
	var y := -10.0
	while y > -ladder_height + 6.0:
		var rung := Polygon2D.new()
		rung.color = Color(0.5, 0.4, 0.26)
		rung.polygon = PackedVector2Array([
			Vector2(-hx + 1, y - 2), Vector2(hx - 1, y - 2),
			Vector2(hx - 1, y + 2), Vector2(-hx + 1, y + 2)
		])
		art.add_child(rung)
		y -= step


func top_y() -> float:
	return global_position.y - ladder_height


func bottom_y() -> float:
	return global_position.y


func contains_player(player: Node2D) -> bool:
	if player == null:
		return false
	var px := player.global_position.x
	var py := player.global_position.y
	var half := (ladder_width + 14.0) * 0.5
	if absf(px - global_position.x) > half:
		return false
	## Feet can be slightly below bottom or a bit above top while mounting.
	return py <= bottom_y() + 18.0 and py >= top_y() - 12.0
