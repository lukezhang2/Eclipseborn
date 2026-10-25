extends StaticBody2D
class_name SwitchDoor
## Door controlled by a LightSwitch (or any set_on caller). Closed = solid; open = passable.


@export var door_id: String = "door"
@export var starts_open: bool = false
@export var width: float = 28.0
@export var height: float = 96.0

var _open: bool = false
var _panel: Polygon2D
var _frame: Polygon2D
var _cs: CollisionShape2D
var _label: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("switch_targets")
	add_to_group("switch_doors")
	if door_id != "":
		set_meta("catalog_id", door_id)
	_build()
	set_open(starts_open)


func _build() -> void:
	var hx := width * 0.5
	_frame = Polygon2D.new()
	_frame.color = Color(0.22, 0.16, 0.12)
	_frame.polygon = PackedVector2Array([
		Vector2(-hx - 4, 0), Vector2(hx + 4, 0), Vector2(hx + 4, -height - 4), Vector2(-hx - 4, -height - 4)
	])
	add_child(_frame)

	_panel = Polygon2D.new()
	_panel.color = Color(0.38, 0.26, 0.16)
	_panel.polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	add_child(_panel)

	## Planks
	for i in 3:
		var plank := Polygon2D.new()
		plank.color = Color(0.3, 0.2, 0.12, 0.55)
		var y0 := -height * (0.25 + i * 0.25)
		plank.polygon = PackedVector2Array([
			Vector2(-hx + 2, y0 - 2), Vector2(hx - 2, y0 - 2),
			Vector2(hx - 2, y0 + 2), Vector2(-hx + 2, y0 + 2)
		])
		_panel.add_child(plank)

	var knob := Polygon2D.new()
	knob.color = Color(0.75, 0.62, 0.3)
	knob.polygon = PackedVector2Array([
		Vector2(hx - 10, -height * 0.45), Vector2(hx - 4, -height * 0.45),
		Vector2(hx - 4, -height * 0.45 + 6), Vector2(hx - 10, -height * 0.45 + 6)
	])
	_panel.add_child(knob)

	_cs = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	_cs.shape = rect
	_cs.position = Vector2(0, -height * 0.5)
	add_child(_cs)

	## Light occluder when closed
	var occ := ShadowOccluder.new()
	occ.local_polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	occ.name = "DoorOccluder"
	add_child(occ)

	_label = Label.new()
	_label.position = Vector2(-22, -height - 18)
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	add_child(_label)


func set_on(powered: bool) -> void:
	## Lever ON opens the door (powered = open).
	set_open(powered)


func set_powered(powered: bool) -> void:
	set_open(powered)


func set_open(open: bool) -> void:
	_open = open
	if _cs:
		_cs.disabled = open
	if _panel:
		## Slide up when open.
		_panel.position.y = -height * 0.85 if open else 0.0
		_panel.modulate.a = 0.35 if open else 1.0
	var occ := get_node_or_null("DoorOccluder") as ShadowOccluder
	if occ:
		## Empty polygon when open so light rays ignore it.
		var hx := width * 0.5
		if open:
			occ.local_polygon = PackedVector2Array()
		else:
			occ.local_polygon = PackedVector2Array([
				Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
			])
	if _label:
		_label.text = "Open" if open else "Closed"
	ShadowWorld.mark_dirty()


func is_open() -> bool:
	return _open
