extends StaticBody2D
class_name House
## Decorative house with optional interact prompt.


@export var house_name: String = "House"
@export var width: float = 120.0
@export var height: float = 90.0

var _prompt: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("houses")


func _build() -> void:
	var hx := width * 0.5
	var hy := height * 0.5
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	cs.position = Vector2(0, -hy)
	add_child(cs)
	var wall := Polygon2D.new()
	wall.color = Color(0.28, 0.22, 0.18)
	wall.polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	add_child(wall)
	var roof := Polygon2D.new()
	roof.color = Color(0.35, 0.18, 0.14)
	roof.polygon = PackedVector2Array([
		Vector2(-hx - 8, -height), Vector2(hx + 8, -height), Vector2(0, -height - 36)
	])
	add_child(roof)
	var door := Polygon2D.new()
	door.color = Color(0.15, 0.1, 0.08)
	door.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(10, 0), Vector2(10, -28), Vector2(-10, -28)
	])
	add_child(door)
	var win := Polygon2D.new()
	win.color = Color(0.55, 0.6, 0.35, 0.5)
	win.polygon = PackedVector2Array([
		Vector2(-hx + 16, -height + 20), Vector2(-hx + 36, -height + 20),
		Vector2(-hx + 36, -height + 40), Vector2(-hx + 16, -height + 40)
	])
	add_child(win)
	# Occlude light
	var occ := ShadowOccluder.new()
	occ.local_polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	add_child(occ)
	_prompt = Label.new()
	_prompt.text = house_name
	_prompt.position = Vector2(-40, -height - 50)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6, 0.8))
	add_child(_prompt)
