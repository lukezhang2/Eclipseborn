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
var light_intensity: float = 1.0
var light_kind: int = 0
var pushable: bool = true
var builtin: bool = false
var catalog_kind: String = "floor"
## "center" or "bottom" — must match PieceSpecs.anchor(catalog_kind).
var anchor_mode: String = "center"
## NPC dialogue lines (one string per line). Empty for non-NPCs / shopkeepers.
var dialogue_lines: PackedStringArray = PackedStringArray()
## Shopkeeper flag + stock list: [{id, stock, price}] with stock −1 = infinite.
## Empty array = nothing for sale (editor default for new shopkeepers).
var is_shopkeeper: bool = false
var shop_items: Array = []
## Optional tint for floors/walls/platforms/etc. White = no change.
var tint_color: Color = Color.WHITE
## World text (prop_text).
var label_text: String = "Text"
var font_size: int = 14
## Zone-link door (prop_exit) / house facade target.
var target_zone: String = "lantern_village"
var spawn_x: float = 520.0
var spawn_y: float = 460.0
var travel_caption: String = ""
## WorldArt style for prop_backdrop (0 brick&copper, 1 teal foundry, 2 riveted bulkhead).
var art_style: int = 0
## If true, gameplay should occlude lantern washes (no player collision required).
var blocks_light: bool = true
## Draw order (z_index). Player is PieceSpecs.PLAYER_DRAW_LAYER (0).
var draw_layer: int = 0
## Lever links: catalog ids of lights / doors this switch powers.
var target_ids: PackedStringArray = PackedStringArray()
## Door starts open / switch starts on.
var starts_on: bool = true
## prop_enemy. damage_custom stays false when the save has no damage key,
## so an already placed creature keeps the number in its script.
var enemy_kind: String = "wander"
var attack_damage: int = 10
var damage_custom: bool = false
var max_hp: int = 24
var hp_custom: bool = false
## Degrees — used by Rotate tool / JSON `rotation`.
var rotation_deg: float = 0.0
## Moving platform path/spin (prop_platform).
var move_amplitude: float = 90.0
var move_speed: float = 0.65
var move_vertical: bool = false
var path_y_amplitude: float = 0.0
var rotate_while_moving: bool = true
var rotate_speed: float = 1.0
var rotate_platform: bool = false

var _visual: Sprite2D
var _outline: Line2D
var _name_label: Label
var _body: Node2D ## Offset for bottom-anchored pieces so position = feet.
var _dragging: bool = false
var _resizing: bool = false
var _resize_corner: int = -1
var _drag_off: Vector2 = Vector2.ZERO
## "" | "x" | "y" — constrained move via axis arrows (Move tool).
var _axis_drag: String = ""
var _axis_start_pos: Vector2 = Vector2.ZERO
var _axis_start_mouse: Vector2 = Vector2.ZERO
## When true (Move tool + selected), draw/drag X/Y arrows.
var show_move_arrows: bool = false
## When true (Resize tool + selected), draw N/E/S/W edge grips.
var show_resize_edges: bool = false
const AXIS_LEN := 52.0
const AXIS_HIT := 16.0
const EDGE_HIT := 10.0
## Corner handles 0–3 (NW/NE/SE/SW); edge handles 4–7 (N/E/S/W).
const HANDLE_NW := 0
const HANDLE_NE := 1
const HANDLE_SE := 2
const HANDLE_SW := 3
const HANDLE_N := 4
const HANDLE_E := 5
const HANDLE_S := 6
const HANDLE_W := 7
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
		"rotation": rotation_deg,
	}
	if kind == Kind.LIGHT:
		d["kind"] = "light"
		d["radius"] = light_radius
		d["intensity"] = light_intensity
		d["light_kind"] = light_kind
		d["pushable"] = pushable
	elif kind == Kind.BACKGROUND:
		d["kind"] = "background"
	elif has_meta("piece_kind"):
		d["kind"] = str(get_meta("piece_kind"))
	if catalog_kind == "prop_backdrop" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_backdrop"):
		d["kind"] = "prop_backdrop"
		d["style"] = art_style
	if PieceSpecs.supports_tint(catalog_kind) and tint_color != Color.WHITE:
		d["color"] = tint_color.to_html(false)
	if catalog_kind == "prop_npc" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_npc"):
		var lines_arr: Array = []
		for s in dialogue_lines:
			lines_arr.append(s)
		d["lines"] = lines_arr
		d["is_shopkeeper"] = is_shopkeeper
		d["shop_items"] = ShopCatalog.normalize_shop_items(shop_items)
		d["kind"] = "prop_npc"
	if catalog_kind == "prop_text" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_text"):
		d["kind"] = "prop_text"
		d["text"] = label_text
		d["font_size"] = font_size
		d["color"] = tint_color.to_html(false)
	if catalog_kind == "prop_exit" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_exit"):
		d["kind"] = "prop_exit"
		d["target_zone"] = target_zone
		d["spawn_x"] = spawn_x
		d["spawn_y"] = spawn_y
		d["caption"] = travel_caption
	if catalog_kind == "prop_house" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_house"):
		d["kind"] = "prop_house"
		d["target_zone"] = target_zone if target_zone != "" else piece_id
		d["spawn_x"] = spawn_x
		d["spawn_y"] = spawn_y
		d["caption"] = travel_caption
	if catalog_kind == "prop_hatch" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_hatch"):
		d["kind"] = "prop_hatch"
		d["target_zone"] = target_zone if target_zone != "" else "lantern_village"
		d["spawn_x"] = spawn_x
		d["spawn_y"] = spawn_y
		d["caption"] = travel_caption
	if catalog_kind == "prop_switch" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_switch"):
		d["kind"] = "prop_switch"
		d["starts_on"] = starts_on
		var tids: Array = []
		for t in target_ids:
			tids.append(t)
		d["target_ids"] = tids
	if catalog_kind == "prop_enemy" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_enemy"):
		d["kind"] = "prop_enemy"
		if enemy_kind != "" and enemy_kind != "wander":
			d["enemy_kind"] = enemy_kind
		if damage_custom:
			d["damage"] = attack_damage
		if hp_custom:
			d["hp"] = max_hp
	if catalog_kind == "prop_door" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_door"):
		d["kind"] = "prop_door"
		d["starts_open"] = starts_on
	if catalog_kind == "prop_platform" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_platform"):
		d["kind"] = "prop_platform"
		d["move_amplitude"] = move_amplitude
		d["move_speed"] = move_speed
		d["vertical"] = move_vertical
		d["path_y_amplitude"] = path_y_amplitude
		d["rotate_while_moving"] = rotate_while_moving
		d["rotate_speed"] = rotate_speed
		d["rotate_platform"] = rotate_platform
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
	if k == "prop_enemy":
		enemy_kind = str(d.get("enemy_kind", "wander"))
		damage_custom = d.has("damage")
		attack_damage = int(d.get("damage", PieceSpecs.creature_damage(enemy_kind)))
		hp_custom = d.has("hp")
		max_hp = int(d.get("hp", PieceSpecs.creature_hp(enemy_kind)))
	rotation_deg = float(d.get("rotation", 0.0))
	rotation_degrees = rotation_deg
	## Legacy village platforms were saved as floor — promote so the inspector appears.
	if k == "floor" and (piece_id.begins_with("platform_gear") or d.has("move_amplitude")):
		k = "prop_platform"
		catalog_kind = k
	if k == "prop_platform":
		move_amplitude = float(d.get("move_amplitude", d.get("amplitude", 90.0)))
		move_speed = float(d.get("move_speed", d.get("speed", 0.65)))
		move_vertical = bool(d.get("vertical", false))
		path_y_amplitude = float(d.get("path_y_amplitude", 0.0))
		rotate_while_moving = bool(d.get("rotate_while_moving", d.get("rotate", true)))
		rotate_speed = float(d.get("rotate_speed", 1.0))
		rotate_platform = bool(d.get("rotate_platform", false))
	tint_color = Color.WHITE
	if d.has("color"):
		tint_color = Color.html(str(d.get("color", "#ffffff")))
	elif k == "prop_text":
		tint_color = Color("c4b07a")
	label_text = str(d.get("text", label_text if label_text != "" else "Text"))
	font_size = clampi(int(d.get("font_size", font_size if font_size > 0 else 14)), 8, 72)
	match k:
		"background":
			kind = Kind.BACKGROUND
		"light":
			kind = Kind.LIGHT
			light_radius = float(d.get("radius", light_radius if light_radius > 0.0 else 280.0))
			light_intensity = float(d.get("intensity", light_intensity if light_intensity > 0.0 else 1.0))
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
				is_shopkeeper = bool(d.get("is_shopkeeper", true))
				## Empty shop_items = nothing for sale (do not fill catalog defaults).
				shop_items = ShopCatalog.normalize_shop_items(d.get("shop_items", []))
			if k == "prop_text":
				if str(d.get("text", "")) == "" and display_name != "" and display_name != "Piece":
					label_text = display_name
			if k == "prop_exit" or k == "prop_house" or k == "prop_hatch":
				var fallback_z := piece_id if k == "prop_house" else "lantern_village"
				target_zone = str(d.get("target_zone", d.get("house_id", fallback_z)))
				spawn_x = float(d.get("spawn_x", spawn_x))
				spawn_y = float(d.get("spawn_y", spawn_y))
				travel_caption = str(d.get("caption", d.get("travel_caption", travel_caption)))
			if k == "prop_backdrop":
				art_style = clampi(int(d.get("style", 0)), 0, 2)
	if display_name == "" or display_name == "Piece":
		display_name = piece_id if piece_id != "" else k
	_rebuild()

func is_npc() -> bool:
	return catalog_kind == "prop_npc" or (has_meta("piece_kind") and str(get_meta("piece_kind")) == "prop_npc")


func set_dialogue_text(text: String) -> void:
	dialogue_lines = HouseProfiles.lines_to_packed(text)


func get_dialogue_text() -> String:
	return "\n".join(dialogue_lines)


func set_shop_item_stock(item_id: String, stock: int, enabled: bool, item_price: int = -1) -> void:
	var next: Array = []
	var found := false
	var p := item_price if item_price >= 0 else ShopCatalog.price(item_id)
	for entry in ShopCatalog.normalize_shop_items(shop_items):
		var id := str(entry.get("id", ""))
		if id == item_id:
			found = true
			if enabled:
				if item_price < 0:
					p = ShopCatalog.entry_price(entry)
				next.append({"id": id, "stock": stock, "price": p})
		else:
			next.append(entry)
	if enabled and not found:
		next.append({"id": item_id, "stock": stock, "price": p})
	shop_items = next


func get_shop_item_stock(item_id: String) -> int:
	## Returns stock if listed, or −2 if not sold by this keeper.
	for entry in ShopCatalog.normalize_shop_items(shop_items):
		if str(entry.get("id", "")) == item_id:
			return int(entry.get("stock", -1))
	return -2


func get_shop_item_price(item_id: String) -> int:
	for entry in ShopCatalog.normalize_shop_items(shop_items):
		if str(entry.get("id", "")) == item_id:
			return ShopCatalog.entry_price(entry)
	return ShopCatalog.price(item_id)


func set_draw_layer(layer: int) -> void:
	draw_layer = clampi(layer, -20, 20)
	z_index = draw_layer


func set_rotation_deg(deg: float) -> void:
	rotation_deg = deg
	rotation_degrees = deg


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
	queue_redraw()


func _draw() -> void:
	if not is_selected:
		return
	## Travel path ghost when a moving platform is selected.
	if PieceSpecs.is_platform_kind(catalog_kind):
		var amp := move_amplitude
		var wobble := path_y_amplitude
		if amp > 0.0 or wobble > 0.0:
			var prev := Vector2.ZERO
			var first := true
			for i in 49:
				var t := float(i) / 48.0 * TAU
				var sx := sin(t)
				var cx := cos(t)
				var ox := 0.0
				var oy := 0.0
				if move_vertical:
					oy = sx * amp
					ox = cx * wobble
				else:
					ox = sx * amp
					oy = cx * wobble
				var pt := Vector2(ox, oy)
				if not first:
					draw_line(prev, pt, Color(0.45, 0.8, 1.0, 0.75), 2.0)
				prev = pt
				first = false
			var a := Vector2(0, -amp) if move_vertical else Vector2(-amp, 0)
			var b := Vector2(0, amp) if move_vertical else Vector2(amp, 0)
			draw_circle(a, 4.0, Color(0.95, 0.85, 0.35, 0.95))
			draw_circle(b, 4.0, Color(0.95, 0.85, 0.35, 0.95))
	## Move-tool axis arrows (precise one-direction drag).
	if show_move_arrows:
		_draw_axis_arrows()
	## Resize-tool edge grips (N/E/S/W length drag).
	if show_resize_edges:
		_draw_resize_edges()


func _axis_origin() -> Vector2:
	## Arrows sit at the visual center of the piece.
	return _local_origin_offset()


func _draw_axis_arrows() -> void:
	var o := _axis_origin()
	var x_tip := o + Vector2(AXIS_LEN, 0)
	var y_tip := o + Vector2(0, -AXIS_LEN)
	## X (right) — amber
	draw_line(o, x_tip, Color(0.95, 0.75, 0.25, 0.95), 3.0)
	draw_colored_polygon(PackedVector2Array([
		x_tip,
		x_tip + Vector2(-10, -6),
		x_tip + Vector2(-10, 6),
	]), Color(0.95, 0.75, 0.25, 1.0))
	## Y (up) — cyan
	draw_line(o, y_tip, Color(0.35, 0.85, 0.95, 0.95), 3.0)
	draw_colored_polygon(PackedVector2Array([
		y_tip,
		y_tip + Vector2(-6, 10),
		y_tip + Vector2(6, 10),
	]), Color(0.35, 0.85, 0.95, 1.0))
	draw_circle(o, 4.0, Color(0.95, 0.95, 0.9, 0.95))


func axis_handle_at(local_pt: Vector2) -> String:
	## Returns "x" / "y" if the cursor is on a move arrow tip, else "".
	if not show_move_arrows:
		return ""
	var o := _axis_origin()
	var x_tip := o + Vector2(AXIS_LEN, 0)
	var y_tip := o + Vector2(0, -AXIS_LEN)
	if local_pt.distance_to(x_tip) <= AXIS_HIT:
		return "x"
	if local_pt.distance_to(y_tip) <= AXIS_HIT:
		return "y"
	## Also allow grabbing along the shaft.
	if absf(local_pt.y - o.y) <= 8.0 and local_pt.x >= o.x - 4.0 and local_pt.x <= o.x + AXIS_LEN + 4.0:
		return "x"
	if absf(local_pt.x - o.x) <= 8.0 and local_pt.y <= o.y + 4.0 and local_pt.y >= o.y - AXIS_LEN - 4.0:
		return "y"
	return ""


func _draw_resize_edges() -> void:
	## Mid-edge bars: drag to grow/shrink that side only.
	if kind == Kind.LIGHT:
		return
	var o := _local_origin_offset()
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var col := Color(0.35, 0.95, 0.7, 0.95)
	var thick := 4.0
	## Short bars centered on each side (corners keep separate corner hits).
	var n_len := minf(size.x * 0.55, 56.0)
	var e_len := minf(size.y * 0.55, 56.0)
	draw_line(o + Vector2(-n_len * 0.5, -hy), o + Vector2(n_len * 0.5, -hy), col, thick)
	draw_line(o + Vector2(hx, -e_len * 0.5), o + Vector2(hx, e_len * 0.5), col, thick)
	draw_line(o + Vector2(-n_len * 0.5, hy), o + Vector2(n_len * 0.5, hy), col, thick)
	draw_line(o + Vector2(-hx, -e_len * 0.5), o + Vector2(-hx, e_len * 0.5), col, thick)
	for c in [
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	]:
		draw_circle(o + c, 5.0, Color(0.25, 1.0, 0.55, 1.0))


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
			_visual.modulate = Color(tint_color.r, tint_color.g, tint_color.b, 0.85)
		Kind.LIGHT:
			_visual.texture = _make_light_tex(28, 36)
			size = Vector2(28, 36)
		Kind.PROP:
			if catalog_kind == "prop_text":
				_visual.texture = _make_text_tex(int(size.x), int(size.y))
			elif catalog_kind == "prop_backdrop":
				## Live WorldArt sample so styles read clearly in the editor.
				## BACKDROP draws upward from its origin (bottom-center).
				_visual.visible = false
				var art := WorldArt.new()
				art.kind = WorldArt.Kind.BACKDROP
				art.style = clampi(art_style, 0, 2)
				art.size = size
				## Body is AABB-centered; BACKDROP origin is bottom-center of the panel.
				art.position = Vector2(0, size.y * 0.5)
				_body.add_child(art)
			else:
				_visual.texture = _make_prop_tex(int(size.x), int(size.y), catalog_kind)
		_:
			if catalog_kind == "crate":
				_visual.texture = _make_crate_tex(int(size.x), int(size.y))
			else:
				_visual.texture = _make_block_tex(int(size.x), int(size.y), catalog_kind)
	## Texture pixels == world size (same contract as PushableBox / steel floors).
	if _visual.texture != null:
		var tw := maxi(_visual.texture.get_width(), 1)
		var th := maxi(_visual.texture.get_height(), 1)
		_visual.scale = Vector2(size.x / float(tw), size.y / float(th))
	if PieceSpecs.supports_tint(catalog_kind) and catalog_kind != "background" and catalog_kind != "prop_text" and catalog_kind != "prop_backdrop":
		_visual.modulate = tint_color
	_body.add_child(_visual)
	if catalog_kind == "prop_text":
		var txt := Label.new()
		txt.text = label_text if label_text != "" else "Text"
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.add_theme_font_size_override("font_size", font_size)
		txt.add_theme_color_override("font_color", tint_color if tint_color.a > 0.01 else Color(0.85, 0.78, 0.55))
		txt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		txt.add_theme_constant_override("outline_size", 3)
		txt.size = size
		txt.position = Vector2(-size.x * 0.5, -size.y * 0.5)
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_body.add_child(txt)

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
		ring.width = 1.0 + light_intensity * 0.5
		var kc := _light_kind_color()
		ring.default_color = Color(kc.r, kc.g, kc.b, clampf(0.35 + light_intensity * 0.2, 0.35, 0.85))
		for i in 24:
			var a := TAU * float(i) / 24.0
			## Match LightSource ring offset (burn center slightly above body).
			ring.add_point(Vector2(cos(a), sin(a)) * light_radius + Vector2(0, -8))
		ring.add_point(ring.get_point_position(0))
		_body.add_child(ring)
		## Intensity preview disc (brighter = hotter).
		if light_intensity > 1.01:
			var hot := Polygon2D.new()
			var hot_pts := PackedVector2Array()
			var hr := mini(light_radius * 0.2 * light_intensity, 48.0)
			for i in 16:
				var a := TAU * float(i) / 16.0
				hot_pts.append(Vector2(cos(a), sin(a)) * hr + Vector2(0, -8))
			hot.polygon = hot_pts
			hot.color = Color(kc.r, kc.g, kc.b, clampf(0.15 * (light_intensity - 0.5), 0.08, 0.4))
			_body.add_child(hot)

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
		"prop_ladder":
			col = Color(0.5, 0.4, 0.26)
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
		"prop_platform":
			col = Color(0.35, 0.42, 0.5)
		"prop_pickup":
			col = Color(0.28, 0.14, 0.42)
		"prop_text":
			col = Color(0.2, 0.18, 0.16, 0.35)
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
	if k == "prop_pickup":
		## Jagged shard preview — dark violet with a bright ridge.
		img.fill(Color(0, 0, 0, 0))
		var cx2 := w / 2
		var cy2 := h / 2
		for y in h:
			for x in w:
				var dx := float(x - cx2) / maxf(float(w) * 0.5, 1.0)
				var dy := float(y - cy2) / maxf(float(h) * 0.5, 1.0)
				## Rough diamond with a bite taken out.
				var inside := absf(dx) + absf(dy) < 0.85 and not (dx > 0.25 and dy > 0.15)
				if inside:
					var shade := 0.2 + (0.35 * (1.0 - absf(dx) - absf(dy)))
					var c := Color(0.18 + shade * 0.2, 0.08 + shade * 0.1, 0.32 + shade * 0.35)
					if dx < -0.15 and dy < 0.0:
						c = c.lightened(0.25)
					if absf(dx) + absf(dy) > 0.7:
						c = c.darkened(0.35)
					img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_text_tex(w: int, h: int) -> ImageTexture:
	w = clampi(w, 24, 512)
	h = clampi(h, 16, 256)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.12, 0.1, 0.08, 0.25))
	for x in w:
		img.set_pixel(x, 0, Color(0.55, 0.48, 0.35, 0.7))
		img.set_pixel(x, h - 1, Color(0.55, 0.48, 0.35, 0.7))
	for y in h:
		img.set_pixel(0, y, Color(0.55, 0.48, 0.35, 0.7))
		img.set_pixel(w - 1, y, Color(0.55, 0.48, 0.35, 0.7))
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


func _light_kind_color() -> Color:
	match light_kind:
		GameState.LightKind.CANDLE:
			return Color(1.0, 0.7, 0.4)
		GameState.LightKind.MOON:
			return Color(0.7, 0.85, 1.0)
		GameState.LightKind.CRIMSON:
			return Color(0.95, 0.2, 0.25)
		GameState.LightKind.SUNSHAFT:
			return Color(1.0, 1.0, 0.95)
		_:
			return Color(1.0, 0.78, 0.35)


func _make_light_tex(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w * 0.5, h * 0.5)
	var kc := _light_kind_color()
	for y in h:
		for x in w:
			var d := Vector2(x, y).distance_to(c) / (w * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(kc.r, kc.g, kc.b, a))
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
	## Corners first, then N/E/S/W edge midpoints (Resize tool).
	if kind == Kind.LIGHT:
		return -1
	var p := _to_body_local(local_pt)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var corners := [
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	]
	for i in 4:
		if p.distance_to(corners[i]) < 14.0:
			return i
	var n_len := minf(size.x * 0.55, 56.0)
	var e_len := minf(size.y * 0.55, 56.0)
	if absf(p.y + hy) <= EDGE_HIT and absf(p.x) <= n_len * 0.5 + 4.0:
		return HANDLE_N
	if absf(p.x - hx) <= EDGE_HIT and absf(p.y) <= e_len * 0.5 + 4.0:
		return HANDLE_E
	if absf(p.y - hy) <= EDGE_HIT and absf(p.x) <= n_len * 0.5 + 4.0:
		return HANDLE_S
	if absf(p.x + hx) <= EDGE_HIT and absf(p.y) <= e_len * 0.5 + 4.0:
		return HANDLE_W
	return -1


func begin_drag(world: Vector2) -> void:
	_dragging = true
	_axis_drag = ""
	_drag_off = position - world


func begin_axis_drag(axis: String, world: Vector2) -> void:
	_axis_drag = axis
	_dragging = false
	_axis_start_pos = position
	_axis_start_mouse = world


func begin_resize(corner: int) -> void:
	_resizing = true
	_resize_corner = corner


func end_interact() -> void:
	_dragging = false
	_resizing = false
	_resize_corner = -1
	_axis_drag = ""


func drag_to(world: Vector2) -> void:
	if _axis_drag == "x":
		position = Vector2(_axis_start_pos.x + (world.x - _axis_start_mouse.x), _axis_start_pos.y)
	elif _axis_drag == "y":
		position = Vector2(_axis_start_pos.x, _axis_start_pos.y + (world.y - _axis_start_mouse.y))
	elif _dragging:
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
		HANDLE_NW:
			min_x = local.x
			min_y = local.y
		HANDLE_NE:
			max_x = local.x
			min_y = local.y
		HANDLE_SE:
			max_x = local.x
			max_y = local.y
		HANDLE_SW:
			min_x = local.x
			max_y = local.y
		HANDLE_N:
			min_y = local.y
		HANDLE_E:
			max_x = local.x
		HANDLE_S:
			max_y = local.y
		HANDLE_W:
			min_x = local.x
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
