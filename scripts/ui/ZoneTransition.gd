extends CanvasLayer
class_name ZoneTransition
## Gear-swirl fade. Lives on the tree root so the coroutine survives scene changes.


const FX_NAME := "ZoneTransitionFX"


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


## Owned by this node (root child) so awaits survive change_scene_to_file.
func begin_scene_change(scene_path: String) -> void:
	name = FX_NAME
	await play_out()
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(scene_path)
	# Wait until the new scene is in the tree before fading in.
	await tree.process_frame
	await tree.process_frame
	await play_in()


func play_out() -> void:
	_clear_children()
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var label := Label.new()
	label.text = "Into Lantern Village…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -220
	label.offset_right = 220
	label.offset_top = -24
	label.offset_bottom = 24
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
	label.modulate.a = 0.0
	add_child(label)
	var gear := Node2D.new()
	gear.position = Vector2(640, 360)
	add_child(gear)
	var ring := Polygon2D.new()
	ring.color = Color(0.55, 0.45, 0.25, 1)
	ring.modulate.a = 0.0
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * (40.0 + (i % 2) * 12.0))
	ring.polygon = pts
	gear.add_child(ring)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", 1.0, 0.7)
	tw.tween_property(label, "modulate:a", 1.0, 0.45)
	tw.tween_property(ring, "modulate:a", 1.0, 0.4)
	tw.tween_property(gear, "rotation_degrees", 360.0, 0.75)
	await tw.finished


func play_in() -> void:
	var dim := get_node_or_null("Dim") as ColorRect
	if dim == null:
		dim = ColorRect.new()
		dim.name = "Dim"
		dim.color = Color(0, 0, 0, 1)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
	else:
		dim.color.a = 1.0
	# Hide chrome so only the black fades out over the new scene.
	for c in get_children():
		if c != dim and c is CanvasItem:
			(c as CanvasItem).visible = false
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.0, 0.65)
	await tw.finished
	queue_free()


func _clear_children() -> void:
	for c in get_children():
		c.queue_free()


static func clear_stale(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var stale := tree.root.get_node_or_null(FX_NAME)
	if stale:
		stale.queue_free()
