extends CanvasLayer
## Gear-swirl fade used when leaving the cottage hatch into Lantern Village.


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_out() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var label := Label.new()
	label.text = "Into Lantern Village…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -20
	label.offset_bottom = 20
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0))
	add_child(label)
	var gear := Node2D.new()
	gear.position = Vector2(640, 360)
	add_child(gear)
	var ring := Polygon2D.new()
	ring.color = Color(0.55, 0.45, 0.25, 0)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * (40.0 + (i % 2) * 12.0))
	ring.polygon = pts
	gear.add_child(ring)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", 1.0, 0.85)
	tw.tween_property(label, "modulate:a", 1.0, 0.5)
	tw.tween_property(ring, "modulate:a", 1.0, 0.4)
	tw.tween_property(gear, "rotation_degrees", 360.0, 0.9)
	await tw.finished


func play_in() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 1)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.0, 0.7)
	await tw.finished
	queue_free()
