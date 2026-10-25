extends Node2D
class_name LightWashFan
## Triangle-fan light wash from the lamp origin. Star-shaped from the emitter so
## concave occluder bites still fill solidly (Polygon2D triangulation often hollows the middle).


var origin: Vector2 = Vector2.ZERO
var rim: PackedVector2Array = PackedVector2Array()
var color: Color = Color(1, 1, 1, 0.5)


func set_fan(o: Vector2, rim_pts: PackedVector2Array, col: Color) -> void:
	origin = o
	rim = rim_pts
	color = col
	queue_redraw()


func _draw() -> void:
	var n := rim.size()
	if n < 2:
		return
	for i in n:
		var a := rim[i]
		var b := rim[(i + 1) % n]
		draw_colored_polygon(PackedVector2Array([origin, a, b]), color)
