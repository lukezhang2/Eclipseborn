extends CanvasLayer
class_name ZoneTransition
## Title-menu gear fades behind the label while the next zone loads.


const FX_NAME := "ZoneTransitionFX"

var _spin_gear: Node2D
var _spinning: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _spinning and _spin_gear and is_instance_valid(_spin_gear):
		_spin_gear.rotation_degrees += 48.0 * delta


## Owned by this node (root child) so awaits survive change_scene_to_file.
func begin_scene_change(scene_path: String) -> void:
	name = FX_NAME
	await play_out()
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(scene_path)
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

	# Gear BEHIND the words — title-menu brass gear, translucent, keeps spinning.
	_spin_gear = GearBackdrop.make_title_gear(110.0, 18, true)
	_spin_gear.name = "SpinGear"
	_spin_gear.position = Vector2(640, 360)
	_spin_gear.modulate = Color(1, 1, 1, 0)
	_spin_gear.z_index = 0
	add_child(_spin_gear)

	var label := Label.new()
	label.name = "Caption"
	label.text = "Into Lantern Village…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -260
	label.offset_right = 260
	label.offset_top = -28
	label.offset_bottom = 28
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75, 1))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06, 0.95))
	label.add_theme_constant_override("outline_size", 6)
	label.modulate.a = 0.0
	label.z_index = 2
	add_child(label)

	_spinning = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", 1.0, 0.75)
	tw.tween_property(_spin_gear, "modulate:a", 0.28, 0.5)
	tw.tween_property(label, "modulate:a", 1.0, 0.45)
	await tw.finished
	# Hold a beat so the spinning gear reads while the zone loads.
	await get_tree().create_timer(0.35).timeout


func play_in() -> void:
	_spinning = false
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
	for c in get_children():
		if c != dim and c is CanvasItem:
			(c as CanvasItem).visible = false
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.0, 0.65)
	await tw.finished
	queue_free()


func _clear_children() -> void:
	_spinning = false
	_spin_gear = null
	for c in get_children():
		c.queue_free()


static func clear_stale(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var stale := tree.root.get_node_or_null(FX_NAME)
	if stale:
		stale.queue_free()
