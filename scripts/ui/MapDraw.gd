extends Control
## Draws the zone map rectangles; owned by ZoneMap.

var layout: Array = []
var discovered: Array = []
var current_room: String = ""


func set_map_data(p_layout: Array, p_discovered: Array, p_current: String) -> void:
	layout = p_layout
	discovered = p_discovered
	current_room = p_current
	queue_redraw()


func _draw() -> void:
	for room in layout:
		var r: Rect2 = room["rect"]
		var id: String = room["id"]
		var known := discovered.has(id)
		var color := Color(0.25, 0.28, 0.35) if known else Color(0.08, 0.08, 0.1)
		var border := Color(0.55, 0.45, 0.3) if known else Color(0.15, 0.15, 0.18)
		draw_rect(r, color, true)
		draw_rect(r, border, false, 2.0)
		if known:
			draw_string(
				ThemeDB.fallback_font,
				r.position + Vector2(8, 22),
				id,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				Color(0.85, 0.8, 0.7)
			)
		if id == current_room:
			var c := r.get_center()
			draw_circle(c, 8.0, Color(0.05, 0.05, 0.08))
			draw_circle(c + Vector2(-3, -2), 2.0, Color(1, 1, 0.95))
			draw_circle(c + Vector2(3, -2), 2.0, Color(1, 1, 0.95))
