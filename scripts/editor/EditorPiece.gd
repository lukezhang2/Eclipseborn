extends Node2D
class_name EditorPiece
## Selectable / movable / resizable editor proxy with a visible name tag.
## (x,y) uses PieceSpecs.anchor: center for crates/floors/lights, bottom for houses/etc.


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
## "center" or "bottom" — must match PieceSpecs.anchor(catalog_kind).
var anchor_mode: String = "center"
## NPC dialogue lines (one string per line). Empty for non-NPCs.
var dialogue_lines: PackedStringArray = PackedStringArray()
## If true, gameplay should occlude lantern washes (no player collision required).
var blocks_light: bool = true
## Draw order (z_index). Player is PieceSpecs.PLAYER_DRAW_LAYER (0).
var draw_layer: int = 0
## Lever links: catalog ids of lights / doors this switch powers.
var target_ids: PackedStringArray = PackedStringArray()
## Door starts open / switch starts on.
var starts_on: bool = true

var _visual: Sprite2D
var _outline: Line2D
var _name_label: Label
var _body: Node2D ## Offset for bottom-anchored pieces so position = feet.
var _dragging: bool = false
var _resizing: bool = false
var _resize_corner: int = -1
var _drag_off: Vector2 = Vector2.ZERO
var is_selected: bool = false


func _ready() -> void:
	z_index = draw_layer
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
		"anchor": anchor_mode,
		"builtin": builtin,
		"blocks_light": blocks_light,
		"layer": draw_layer,
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
	if catalog_kind == "prop_npc" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_npc"):
		var lines_arr: Array = []
		for s in dialogue_lines:
			lines_arr.append(s)
		d["lines"] = lines_arr
		d["kind"] = "prop_npc"
	if catalog_kind == "prop_switch" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_switch"):
		d["kind"] = "prop_switch"
		d["starts_on"] = starts_on
		var tids: Array = []
		for t in target_ids:
			tids.append(t)
		d["target_ids"] = tids
	if catalog_kind == "prop_door" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_door"):
		d["kind"] = "prop_door"
		d["starts_open"] = starts_on
	return d


func apply_dict(d: Dictionary) -> void:
	piece_id = str(d.get("id", piece_id))
	display_name = str(d.get("name", display_name if display_name != "Piece" else piece_id))
	builtin = bool(d.get("builtin", false))
	position = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
	size = Vector2(float(d.get("w", 64)), float(d.get("h", 48)))
	var k: String = str(d.get("kind", "block"))
	catalog_kind = k
	anchor_mode = str(d.get("anchor", PieceSpecs.anchor(k)))
	blocks_light = bool(d.get("blocks_light", PieceSpecs.default_blocks_light(k)))
	draw_layer = int(d.get("layer", PieceSpecs.default_draw_layer(k)))
	z_index = draw_layer
	target_ids = PackedStringArray()
	for t in d.get("target_ids", []):
		target_ids.append(str(t))
	if k == "prop_switch":
		starts_on = bool(d.get("starts_on", true))
	elif k == "prop_door":
		starts_on = bool(d.get("starts_open", false))
	match k:
		"background":
			kind = Kind.BACKGROUND
		"light":
			kind = Kind.LIGHT
			light_radius = float(d.get("radius", light_radius if light_radius > 0.0 else 280.0))
			light_kind = int(d.get("light_kind", 0))
			pushable = bool(d.get("pushable", true))
			size = Vector2(28, 36)
			anchor_mode = "center"
		"floor", "block", "wall", "crate":
			kind = Kind.BLOCK
			set_meta("piece_kind", k)
			if k == "crate":
				## Force gameplay size if an old 48×48 catalog entry slipped through.
				if size.x < 50.0 or size.y < 50.0:
					size = PieceSpecs.CRATE_COTTAGE
		_:
			kind = Kind.PROP
			set_meta("piece_kind", k)
			if k == "prop_npc":
				dialogue_lines = HouseProfiles.lines_to_packed(d.get("lines", dialogue_lines))
	if display_name == "" or display_name == "Piece":
		display_name = piece_id if piece_id != "" else k
	_rebuild()

func is_npc() -> bool:
	return catalog_kind == "prop_npc" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_npc")


func set_dialogue_text(text: String) -> void:
	dialogue_lines = HouseProfiles.lines_to_packed(text)


func get_dialogue_text() -> String:
	return "\n".join(dialogue_lines)


func set_draw_layer(layer: int) -> void:
	draw_layer = clampi(layer, -20, 20)
	z_index = draw_layer


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


func _local_origin_offset() -> Vector2:
	## Body is drawn in center-local space; bottom-anchored pieces shift up by half height.
	if anchor_mode == "bottom":
		return Vector2(0, -size.y * 0.5)
	return Vector2.ZERO


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_body = Node2D.new()
	_body.position = _local_origin_offset()
	add_child(_body)

	_visual = Sprite2D.new()
	_visual.centered = true
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match kind:
		Kind.BACKGROUND:
			_visual.texture = _make_bg_tex(int(size.x), int(size.y))
			_visual.modulate = Color(1, 1, 1, 0.85)
		Kind.LIGHT:
			_visual.texture = _make_light_tex(28, 36)
			size = Vector2(28, 36)
		Kind.PROP:
			_visual.texture = _make_prop_tex(int(size.x), int(size.y), catalog_kind)
		_:
			if catalog_kind == "crate":
				_visual.texture = _make_crate_tex(int(size.x), int(size.y))
			else:
				_visual.texture = _make_block_tex(int(size.x), int(size.y), catalog_kind)
	## Texture pixels == world size (same contract as PushableBox / steel floors).
	var tw := maxi(_visual.texture.get_width(), 1)
	var th := maxi(_visual.texture.get_height(), 1)
	_visual.scale = Vector2(size.x / float(tw), size.y / float(th))
	_body.add_child(_visual)

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
	_body.add_child(_outline)

	_name_label = Label.new()
	_name_label.text = display_name
	_name_label.position = Vector2(-mini(hx, 80.0), -hy - 22.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.75))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	_body.add_child(_name_label)

	if kind == Kind.LIGHT:
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(1.0, 0.85, 0.4, 0.45)
		for i in 24:
			var a := TAU * float(i) / 24.0
			## Match LightSource ring offset (burn center slightly above body).
			ring.add_point(Vector2(cos(a), sin(a)) * light_radius + Vector2(0, -8))
		ring.add_point(ring.get_point_position(0))
		_body.add_child(ring)

	set_selected(is_selected)


func _make_crate_tex(w: int, h: int) -> ImageTexture:
	## Mirrors PushableBox._make_wood_texture so editor size == gameplay size.
	w = maxi(w, 8)
	h = maxi(h, 8)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var grain := sin(float(x) * 0.35 + float(y) * 0.02) * 0.04
			var noise := fmod(float(x * 17 + y * 31), 7.0) * 0.008
			var base := Color(0.42 + grain, 0.30 + grain * 0.5, 0.18 + noise, 1.0)
			if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
				base = Color(0.18, 0.1, 0.05, 1.0)
			elif y % 10 == 0:
				base = base.darkened(0.12)
			img.set_pixel(x, y, base)
	for p in [Vector2i(5, 5), Vector2i(w - 6, 5), Vector2i(5, h - 6), Vector2i(w - 6, h - 6)]:
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				img.set_pixel(clampi(p.x + ox, 0, w - 1), clampi(p.y + oy, 0, h - 1), Color(0.55, 0.45, 0.28))
	return ImageTexture.create_from_image(img)


func _make_block_tex(w: int, h: int, k: String) -> ImageTexture:
	w = clampi(w, 8, 512)
	h = clampi(h, 8, 256)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Color(0.28, 0.29, 0.32)
	if k == "wall":
		base = Color(0.22, 0.18, 0.16)
	for y in h:
		for x in w:
			var c := base
			if x % 48 < 2 or y < 2 or y >= h - 2:
				c = c.darkened(0.3)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_prop_tex(w: int, h: int, k: String) -> ImageTexture:
	## Pipes stay thin in tex space then scale to world w/h.
	if k == "prop_pipe":
		return _make_pipe_tex(w, h)
	w = clampi(w, 16, 512)
	h = clampi(h, 16, 512)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col := Color(0.45, 0.4, 0.35)
	match k:
		"prop_checkpoint":
			col = Color(0.35, 0.32, 0.4)
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
		"prop_valve":
			col = Color(0.55, 0.2, 0.15)
		"prop_desk":
			col = Color(0.32, 0.24, 0.16)
		"prop_exit":
			col = Color(0.12, 0.08, 0.06)
		"prop_switch":
			col = Color(0.55, 0.55, 0.52)
		"prop_door":
			col = Color(0.4, 0.26, 0.14)
		_:
			col = Color(0.4, 0.42, 0.48)
	for y in h:
		for x in w:
			var edge := x < 2 or y < 2 or x >= w - 2 or y >= h - 2
			img.set_pixel(x, y, col.darkened(0.25) if edge else col)
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


func _make_pipe_tex(w: int, h: int) -> ImageTexture:
	## Distinct copper pipe so ceiling lines are obvious in the editor.
	var tw := clampi(maxi(w, 8), 8, 512)
	var th := clampi(maxi(h, 8), 8, 64)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var base := Color(0.42, 0.38, 0.32)
	var shine := Color(0.62, 0.55, 0.42)
	var rim := Color(0.22, 0.18, 0.14)
	for y in th:
		for x in tw:
			var c := base
			if y < 2 or y >= th - 2 or x < 2 or x >= tw - 2:
				c = rim
			elif y < th * 0.35:
				c = shine
			## Flange marks every ~48px of source tex.
			if x % 48 < 3:
				c = Color(0.5, 0.4, 0.25)
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


func _to_body_local(local_pt: Vector2) -> Vector2:
	return local_pt - _local_origin_offset()


func get_aabb() -> Rect2:
	## World-space axis-aligned bounds (respects center vs bottom anchor).
	if anchor_mode == "bottom":
		return Rect2(position.x - size.x * 0.5, position.y - size.y, size.x, size.y)
	return Rect2(position.x - size.x * 0.5, position.y - size.y * 0.5, size.x, size.y)


func set_aabb_position(aabb: Rect2) -> void:
	## Move so our AABB matches (keeps size).
	if anchor_mode == "bottom":
		position = Vector2(aabb.position.x + size.x * 0.5, aabb.position.y + size.y)
	else:
		position = aabb.get_center()


func contains_point(local_pt: Vector2) -> bool:
	var p := _to_body_local(local_pt)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	return absf(p.x) <= hx and absf(p.y) <= hy


func handle_at(local_pt: Vector2) -> int:
	if kind == Kind.LIGHT:
		return -1
	var p := _to_body_local(local_pt)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var corners := [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]
	for i in 4:
		if p.distance_to(corners[i]) < 14.0:
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
	## Work in body-local (center) space.
	var local := _to_body_local(to_local(world))
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
	var center_body := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	var new_size := Vector2(new_w, new_h)
	## Convert body-center back to piece position (respecting anchor).
	var world_center := to_global(_local_origin_offset() + center_body)
	if anchor_mode == "bottom":
		position = world_center + Vector2(0, new_size.y * 0.5)
	else:
		position = world_center
	size = new_size
	_rebuild()
	set_selected(true)
