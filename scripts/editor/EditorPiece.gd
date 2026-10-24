extends Node2D
class_name EditorPiece
## Selectable / movable / resizable editor proxy with a visible name tag.


signal selected(piece: EditorPiece)

enum Kind { BACKGROUND, BLOCK, LIGHT, PROP }

var kind: Kind = Kind.BLOCK
var piece_id: String = ""
var display_name: String = "Piece"
var size: Vector2 = Vector2(64, 48)
var light_radius: float = 280.0
var light_kind: int = 0
var pushable: bool = true
var builtin: bool = false
var catalog_kind: String = "floor"

var _visual: Sprite2D
var _outline: Line2D
var _name_label: Label
var _dragging: bool = false
var _resizing: bool = false
var _resize_corner: int = -1
var _drag_off: Vector2 = Vector2.ZERO
var is_selected: bool = false


func _ready() -> void:
	z_index = 10
	_rebuild()


func setup(k: Kind, pos: Vector2, sz: Vector2, pname: String = "") -> void:
	kind = k
	position = pos
	size = sz
	if pname != "":
		display_name = pname
	if piece_id == "":
		piece_id = "%s_%d" % [_kind_name(), Time.get_ticks_msec()]
	if is_inside_tree():
		_rebuild()


func _kind_name() -> String:
	match kind:
		Kind.BACKGROUND:
			return "background"
		Kind.LIGHT:
			return "light"
		Kind.PROP:
			return catalog_kind if catalog_kind != "" else "prop"
		_:
			return catalog_kind if catalog_kind != "" else "floor"


func to_dict() -> Dictionary:
	var d := {
		"id": piece_id,
		"name": display_name,
		"kind": _kind_name(),
		"x": position.x,
		"y": position.y,
		"w": size.x,
		"h": size.y,
		"builtin": builtin,
	}
	if kind == Kind.LIGHT:
		d["kind"] = "light"
		d["radius"] = light_radius
		d["light_kind"] = light_kind
		d["pushable"] = pushable
	elif kind == Kind.BACKGROUND:
		d["kind"] = "background"
	elif has_meta("piece_kind"):
		d["kind"] = str(get_meta("piece_kind"))
	return d


func apply_dict(d: Dictionary) -> void:
	piece_id = str(d.get("id", piece_id))
	display_name = str(d.get("name", display_name if display_name != "Piece" else piece_id))
	builtin = bool(d.get("builtin", false))
	position = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
	size = Vector2(float(d.get("w", 64)), float(d.get("h", 48)))
	var k: String = str(d.get("kind", "block"))
	catalog_kind = k
	match k:
		"background":
			kind = Kind.BACKGROUND
		"light":
			kind = Kind.LIGHT
			light_radius = float(d.get("radius", light_radius if light_radius > 0.0 else 280.0))
			light_kind = int(d.get("light_kind", 0))
			pushable = bool(d.get("pushable", true))
			display_name = str(d.get("name", display_name))
		"floor", "block", "wall", "crate":
			kind = Kind.BLOCK
			set_meta("piece_kind", k)
		_:
			kind = Kind.PROP
			set_meta("piece_kind", k)
	if display_name == "" or display_name == "Piece":
		display_name = piece_id if piece_id != "" else k
	_rebuild()


func set_selected(on: bool) -> void:
	is_selected = on
	if _outline:
		_outline.default_color = Color(0.25, 1.0, 0.55, 1.0) if on else Color(0.85, 0.8, 0.35, 0.7)
		_outline.width = 3.0 if on else 2.0
	if _name_label:
		_name_label.visible = true
		_name_label.add_theme_color_override(
			"font_color",
			Color(0.4, 1.0, 0.65) if on else Color(0.9, 0.88, 0.75)
		)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_visual = Sprite2D.new()
	_visual.centered = true
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match kind:
		Kind.BACKGROUND:
			_visual.texture = _make_bg_tex(int(size.x), int(size.y))
			_visual.modulate = Color(1, 1, 1, 0.85)
		Kind.LIGHT:
			_visual.texture = _make_light_tex(48, 48)
			size = Vector2(maxi(48, int(size.x)), maxi(48, int(size.y)))
		Kind.PROP:
			_visual.texture = _make_prop_tex(int(size.x), int(size.y), catalog_kind)
		_:
			_visual.texture = _make_block_tex(int(size.x), int(size.y), catalog_kind)
	var tw := maxi(_visual.texture.get_width(), 1)
	var th := maxi(_visual.texture.get_height(), 1)
	_visual.scale = Vector2(size.x / float(tw), size.y / float(th))
	add_child(_visual)

	_outline = Line2D.new()
	_outline.width = 2.0
	_outline.default_color = Color(0.85, 0.8, 0.35, 0.7)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	_outline.add_point(Vector2(-hx, -hy))
	_outline.add_point(Vector2(hx, -hy))
	_outline.add_point(Vector2(hx, hy))
	_outline.add_point(Vector2(-hx, hy))
	_outline.add_point(Vector2(-hx, -hy))
	add_child(_outline)

	_name_label = Label.new()
	_name_label.text = display_name
	_name_label.position = Vector2(-mini(hx, 80.0), -hy - 22.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.75))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	add_child(_name_label)

	if kind == Kind.LIGHT:
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(1.0, 0.85, 0.4, 0.45)
		for i in 24:
			var a := TAU * float(i) / 24.0
			ring.add_point(Vector2(cos(a), sin(a)) * light_radius)
		ring.add_point(ring.get_point_position(0))
		add_child(ring)

	set_selected(is_selected)


func _make_block_tex(w: int, h: int, k: String) -> ImageTexture:
	w = clampi(w, 8, 512)
	h = clampi(h, 8, 256)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Color(0.28, 0.29, 0.32)
	if k == "wall":
		base = Color(0.22, 0.18, 0.16)
	elif k == "crate":
		base = Color(0.42, 0.3, 0.18)
	for y in h:
		for x in w:
			var c := base
			if x % 48 < 2 or y < 2 or y >= h - 2:
				c = c.darkened(0.3)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_prop_tex(w: int, h: int, k: String) -> ImageTexture:
	w = clampi(w, 16, 512)
	h = clampi(h, 16, 512)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col := Color(0.45, 0.4, 0.35)
	match k:
		"prop_checkpoint":
			col = Color(0.35, 0.32, 0.4)  # hearth — was the cryptic … prop
		"prop_house":
			col = Color(0.4, 0.28, 0.2)
		"prop_npc":
			col = Color(0.5, 0.45, 0.55)
		"prop_breakable":
			col = Color(0.45, 0.55, 0.65)
		"prop_enemy":
			col = Color(0.35, 0.2, 0.4)
		"prop_lantern", "prop_tower":
			col = Color(0.55, 0.45, 0.25)
		"prop_bg_gear":
			col = Color(0.4, 0.38, 0.36)
		_:
			col = Color(0.4, 0.42, 0.48)
	for y in h:
		for x in w:
			var edge := x < 2 or y < 2 or x >= w - 2 or y >= h - 2
			img.set_pixel(x, y, col.darkened(0.25) if edge else col)
	# Checkpoint marker: three clear dots so it matches what you saw in-game.
	if k == "prop_checkpoint":
		for i in 3:
			var cx := int(w * (0.25 + i * 0.25))
			var cy := int(h * 0.35)
			for oy in range(-2, 3):
				for ox in range(-2, 3):
					if ox * ox + oy * oy <= 4:
						var px := cx + ox
						var py := cy + oy
						if px >= 0 and py >= 0 and px < w and py < h:
							img.set_pixel(px, py, Color(0.65, 0.75, 0.95))
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
		if local_pt.distance_to(corners[i]) < 14.0:
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
