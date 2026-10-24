extends Node2D
class_name House
## Background house — walkable street in front. Door can be entered with F.


@export var house_name: String = "House"
@export var width: float = 120.0
@export var height: float = 90.0
@export var interior_blurb: String = "Warm shade pools inside."

var _prompt: Label
var _door_area: Area2D
var _inside: bool = false
var _interior_layer: CanvasLayer


func _ready() -> void:
	z_index = -6
	_build()
	add_to_group("houses")


func _build() -> void:
	var hx := width * 0.5
	# Visual only — no world collision so the street stays walkable.
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
	door.color = Color(0.12, 0.08, 0.06)
	door.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(11, -32), Vector2(-11, -32)
	])
	add_child(door)
	var door_glow := Polygon2D.new()
	door_glow.color = Color(0.55, 0.45, 0.25, 0.35)
	door_glow.polygon = PackedVector2Array([
		Vector2(-8, -4), Vector2(8, -4), Vector2(7, -28), Vector2(-7, -28)
	])
	add_child(door_glow)
	var win := Polygon2D.new()
	win.color = Color(0.55, 0.6, 0.35, 0.5)
	win.polygon = PackedVector2Array([
		Vector2(-hx + 16, -height + 20), Vector2(-hx + 36, -height + 20),
		Vector2(-hx + 36, -height + 40), Vector2(-hx + 16, -height + 40)
	])
	add_child(win)
	# Soft light block without solid physics.
	var occ := ShadowOccluder.new()
	occ.local_polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	add_child(occ)

	_door_area = Area2D.new()
	_door_area.collision_layer = 0
	_door_area.collision_mask = 2
	_door_area.monitoring = true
	var dcs := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(36, 40)
	dcs.shape = drect
	dcs.position = Vector2(0, -16)
	_door_area.add_child(dcs)
	add_child(_door_area)

	_prompt = Label.new()
	_prompt.text = "F — Enter %s" % house_name
	_prompt.position = Vector2(-70, -48)
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7))
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	if _inside:
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_cancel"):
			_leave()
		return
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 42.0
	_prompt.visible = near
	if near and Input.is_action_just_pressed("attack"):
		_enter()


func _enter() -> void:
	if _inside:
		return
	_inside = true
	_prompt.visible = false
	if GameState.player and GameState.player.has_method("set_control_locked"):
		GameState.player.set_control_locked(true)
	_interior_layer = CanvasLayer.new()
	_interior_layer.layer = 25
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interior_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(340, 160)
	panel.custom_minimum_size = Vector2(600, 360)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = house_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	var body := Label.new()
	body.text = interior_blurb + "\n\nPress F or Esc to step back onto the street."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 16)
	vbox.add_child(body)
	var leave := Button.new()
	leave.text = "Leave"
	leave.pressed.connect(_leave)
	vbox.add_child(leave)
	get_tree().root.add_child(_interior_layer)


func _leave() -> void:
	if not _inside:
		return
	_inside = false
	if is_instance_valid(_interior_layer):
		_interior_layer.queue_free()
	_interior_layer = null
	if GameState.player and GameState.player.has_method("set_control_locked"):
		GameState.player.set_control_locked(false)

