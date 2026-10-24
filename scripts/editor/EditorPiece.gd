extends Node2D
class_name EditorPiece
## Selectable / movable / resizable editor proxy. Rebuilds texture on resize.


signal selected(piece: EditorPiece)

enum Kind { BACKGROUND, BLOCK, LIGHT }

var kind: Kind = Kind.BLOCK
var piece_id: String = ""
var size: Vector2 = Vector2(64, 48)
var light_radius: float = 280.0
var light_kind: int = 0
var pushable: bool = true

var _visual: Sprite2D
var _outline: Line2D
var _handles: Array[ColorRect] = []
var _dragging: bool = false
var _resizing: bool = false
var _resize_corner: int = -1
var _drag_off: Vector2 = Vector2.ZERO
var is_selected: bool = false


func _ready() -> void:
	z_index = 10
	_rebuild()


func setup(k: Kind, pos: Vector2, sz: Vector2) -> void:
	kind = k
	position = pos
	size = sz
	piece_id = "%s_%d" % [_kind_name(), Time.get_ticks_msec()]
	if is_inside_tree():
		_rebuild()


func _kind_name() -> String:
	match kind:
		Kind.BACKGROUND:
			return "background"
		Kind.LIGHT:
			return "light"
		_:
			return "block"


func to_dict() -> Dictionary:
	var d := {
		"kind": _kind_name() if kind != Kind.BLOCK else "floor",
		"x": position.x,
		"y": position.y,
		"w": size.x,
		"h": size.y,
	}
	if kind == Kind.LIGHT:
		d["kind"] = "light"
		d["radius"] = light_radius
		d["light_kind"] = light_kind
		d["pushable"] = pushable
	elif kind == Kind.BACKGROUND:
		d["kind"] = "background"
	return d


func apply_dict(d: Dictionary) -> void:
	position = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
	size = Vector2(float(d.get("w", 64)), float(d.get("h", 48)))
	var k: String = str(d.get("kind", "block"))
	match k:
		"background":
			kind = Kind.BACKGROUND
		"light":
			kind = Kind.LIGHT
			light_radius = float(d.get("radius", 280))
			light_kind = int(d.get("light_kind", 0))
			pushable = bool(d.get("pushable", true))
		_:
			kind = Kind.BLOCK
	_rebuild()


func set_selected(on: bool) -> void:
	is_selected = on
	if _outline:
		_outline.default_color = Color(0.3, 1.0, 0.5, 1.0) if on else Color(0.9, 0.9, 0.2, 0.6)
	_show_handles(on)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_handles.clear()
	_visual = Sprite2D.new()
	_visual.centered = true
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match kind:
		Kind.BACKGROUND:
			_visual.texture = _make_bg_tex(int(size.x), int(size.y))
			_visual.modulate = Color(1, 1, 1, 0.85)
		Kind.LIGHT:
			_visual.texture = _make_light_tex(48, 48)
			size = Vector2(48, 48)
		_:
			_visual.texture = _make_block_tex(int(size.x), int(size.y))
	_visual.scale = Vector2(
		size.x / float(_visual.texture.get_width()),
		size.y / float(_visual.texture.get_height())
	)
	add_child(_visual)
	_outline = Line2D.new()
	_outline.width = 2.0
	_outline.default_color = Color(0.9, 0.9, 0.2, 0.6)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	_outline.add_point(Vector2(-hx, -hy))
	_outline.add_point(Vector2(hx, -hy))
	_outline.add_point(Vector2(hx, hy))
	_outline.add_point(Vector2(-hx, hy))
	_outline.add_point(Vector2(-hx, -hy))
	add_child(_outline)
	if kind == Kind.LIGHT:
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(1.0, 0.85, 0.4, 0.5)
		for i in 24:
			var a := TAU * float(i) / 24.0
			ring.add_point(Vector2(cos(a), sin(a)) * light_radius)
		ring.add_point(ring.get_point_position(0))
		add_child(ring)


func _show_handles(on: bool) -> void:
	for h in _handles:
		if is_instance_valid(h):
			h.queue_free()
	_handles.clear()
	if not on or kind == Kind.LIGHT:
		return
	# Four corner handles as Control nodes in local space via Node2D markers
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var corners := [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]
	for i in 4:
		var marker := Node2D.new()
		marker.position = corners[i]
		marker.name = "Handle%d" % i
		var poly := Polygon2D.new()
		poly.color = Color(0.2, 0.95, 0.45)
		poly.polygon = PackedVector2Array([
			Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
		])
		marker.add_child(poly)
		marker.set_meta("corner", i)
		add_child(marker)


func _make_block_tex(w: int, h: int) -> ImageTexture:
	w = clampi(w, 8, 512)
	h = clampi(h, 8, 256)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := Color(0.28, 0.29, 0.32)
			if x % 48 < 2 or y < 2 or y >= h - 2:
				c = c.darkened(0.3)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_bg_tex(w: int, h: int) -> ImageTexture:
	w = clampi(w, 8, 512)
	h = clampi(h, 8, 512)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var brick := Color(0.3, 0.2, 0.15) if int(y / 14) % 2 == int(x / 28) % 2 else Color(0.25, 0.16, 0.12)
			img.set_pixel(x, y, brick)
	return ImageTexture.create_from_image(img)


func _make_light_tex(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w * 0.5, h * 0.5)
	for y in h:
		for x in w:
			var d := Vector2(x, y).distance_to(c) / (w * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.8, 0.35, a))
	return ImageTexture.create_from_image(img)


func contains_point(local_pt: Vector2) -> bool:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	return absf(local_pt.x) <= hx and absf(local_pt.y) <= hy


func handle_at(local_pt: Vector2) -> int:
	if kind == Kind.LIGHT:
		return -1
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var corners := [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]
	for i in 4:
		if local_pt.distance_to(corners[i]) < 12.0:
			return i
	return -1


func begin_drag(world: Vector2) -> void:
	_dragging = true
	_drag_off = position - world


func begin_resize(corner: int) -> void:
	_resizing = true
	_resize_corner = corner


func end_interact() -> void:
	_dragging = false
	_resizing = false
	_resize_corner = -1


func drag_to(world: Vector2) -> void:
	if _dragging:
		position = world + _drag_off


func resize_to(world: Vector2) -> void:
	if not _resizing:
		return
	var local := to_local(world)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var min_x := -hx
	var max_x := hx
	var min_y := -hy
	var max_y := hy
	match _resize_corner:
		0:
			min_x = local.x
			min_y = local.y
		1:
			max_x = local.x
			min_y = local.y
		2:
			max_x = local.x
			max_y = local.y
		3:
			min_x = local.x
			max_y = local.y
	var new_w := maxf(24.0, max_x - min_x)
	var new_h := maxf(16.0, max_y - min_y)
	var center_local := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	position = to_global(center_local)
	size = Vector2(new_w, new_h)
	_rebuild()
	set_selected(true)
