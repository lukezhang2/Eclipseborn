extends RefCounted
class_name UITheme
## "Brass & Rivets" UI look from the README: iron, rust, brass, coal and steam, with warm
## lamplight against deep black. Shade reads as purple ink, health as ember.
## Menus: set `theme = UITheme.get_theme()` on the root Control, then `add_plate()` each panel.

# Palette
const COAL := Color("0d0b0c")
const IRON := Color("1c1a1b")
const IRON_LIGHT := Color("2c2624")
const IRON_EDGE := Color("3a3433")
const BRASS := Color("b08d57")
const BRASS_LIGHT := Color("e0c07f")
const BRASS_DARK := Color("6e5530")
const LAMP := Color("f0b45a")
const CREAM := Color("efe3c8")
const STEAM := Color("9c968f")
const EMBER := Color("c2412d")
const INK := Color("6b4c9a")
const INK_LIGHT := Color("b8a3e0")

## Steampunk typefaces (SIL Open Font License; licenses sit next to the .ttf files).
const TITLE_FONT := "res://assets/fonts/IMFellEnglishSC-Regular.ttf"
const PROMPT_FONT := "res://assets/fonts/IMFellEnglishSC-Regular.ttf"

static var _theme: Theme


## Shared Theme for every menu. Built once.
static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func _build() -> Theme:
	var t := Theme.new()

	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", COAL)
	t.set_constant("outline_size", "Label", 4)
	t.set_font_size("font_size", "Label", 17)

	t.set_font_size("font_size", "Button", 19)
	t.set_font("font", "Button", spaced_font(2, 0.4))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", LAMP)
	t.set_color("font_focus_color", "Button", LAMP)
	t.set_color("font_hover_pressed_color", "Button", BRASS_LIGHT)
	t.set_color("font_pressed_color", "Button", BRASS_LIGHT)
	t.set_color("font_disabled_color", "Button", STEAM)
	t.set_color("font_outline_color", "Button", COAL)
	t.set_constant("outline_size", "Button", 4)
	t.set_stylebox("normal", "Button", _box(IRON, BRASS_DARK, 2, 3))
	t.set_stylebox("hover", "Button", _glow(_box(IRON_LIGHT, BRASS_LIGHT, 2, 3)))
	t.set_stylebox("pressed", "Button", _box(COAL, BRASS, 2, 3))
	t.set_stylebox("disabled", "Button", _box(COAL, IRON_EDGE, 2, 3))
	t.set_stylebox("focus", "Button", _glow(_box(Color(0, 0, 0, 0), LAMP, 2, 3, false)))
	for sb_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb: StyleBox = t.get_stylebox(sb_name, "Button")
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
	# Compact key buttons for the Controls list (13 rows must fit on screen)
	t.set_type_variation("KeyButton", "Button")
	t.set_font_size("font_size", "KeyButton", 15)
	for sb_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var key_sb := t.get_stylebox(sb_name, "Button").duplicate() as StyleBox
		key_sb.content_margin_left = 10
		key_sb.content_margin_right = 10
		key_sb.content_margin_top = 2
		key_sb.content_margin_bottom = 2
		t.set_stylebox(sb_name, "KeyButton", key_sb)

	# Sliders: coal groove, brass fill, brass knob that turns lamp-amber when grabbed
	var groove := _box(COAL, IRON_EDGE, 1, 4)
	groove.content_margin_top = 4
	groove.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", groove)
	var fill := _box(BRASS, Color(0, 0, 0, 0), 0, 4)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	var fill_hi := fill.duplicate() as StyleBoxFlat
	fill_hi.bg_color = BRASS_LIGHT
	t.set_stylebox("grabber_area_highlight", "HSlider", fill_hi)
	t.set_icon("grabber", "HSlider", _dot(18, BRASS_LIGHT, COAL))
	t.set_icon("grabber_highlight", "HSlider", _dot(18, LAMP, COAL))

	t.set_icon("checked", "CheckButton", _toggle(true))
	t.set_icon("unchecked", "CheckButton", _toggle(false))
	for sb_name in ["normal", "hover", "pressed", "focus"]:
		t.set_stylebox(sb_name, "CheckButton", StyleBoxEmpty.new())
	return t


## Brass nameplate lettering in the steampunk display face (title + menu headings).
static func style_title(label: Label, size: int = 64) -> void:
	var f := FontVariation.new()
	f.base_font = load(TITLE_FONT)
	f.spacing_glyph = 6 if size >= 48 else 2
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", BRASS_LIGHT)
	label.add_theme_color_override("font_outline_color", Color("1a1210"))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_shadow_color", Color(LAMP, 0.25))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_constant_override("shadow_outline_size", 18)


## In-world "E — …" prompts: steampunk face on a light translucent plaque, drawn above the
## scenery so houses and props never cover it. Use set_prompt_text() so it stays centered.
static func style_prompt(label: Label, size: int = 13) -> void:
	label.add_theme_font_override("font", load(PROMPT_FONT))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", COAL)
	label.add_theme_constant_override("outline_size", 3)
	var plaque := _box(Color(0.05, 0.04, 0.05, 0.5), Color(BRASS, 0.5), 1, 3)
	plaque.content_margin_left = 7
	plaque.content_margin_right = 7
	plaque.content_margin_top = 1
	plaque.content_margin_bottom = 2
	label.add_theme_stylebox_override("normal", plaque)
	label.z_as_relative = false
	label.z_index = 40
	set_prompt_text(label, label.text)


## Set a prompt's text and keep it centered over its object.
static func set_prompt_text(label: Label, text: String) -> void:
	if label.text == text and label.size.x > 0.0:
		return
	label.text = text
	label.reset_size()
	label.position.x = -label.size.x * 0.5


## Riveted iron plate drawn behind a container (containers lay out every child, so we draw instead).
static func add_plate(c: Control, pad: Vector2 = Vector2(44, 32)) -> void:
	c.draw.connect(func() -> void:
		var r := Rect2(-pad, c.size + pad * 2.0)
		var sb := _box(Color(IRON, 0.94), BRASS_DARK, 3, 4)
		sb.shadow_color = Color(0, 0, 0, 0.6)
		sb.shadow_size = 18
		c.draw_style_box(sb, r)
		c.draw_style_box(_box(Color(0, 0, 0, 0), Color(BRASS, 0.35), 1, 2, false), r.grow(-8))
		for corner in [r.position + Vector2(14, 14), Vector2(r.end.x - 14, r.position.y + 14),
				Vector2(r.position.x + 14, r.end.y - 14), r.end - Vector2(14, 14)]:
			c.draw_circle(corner, 4.0, BRASS_DARK)
			c.draw_circle(corner - Vector2(1, 1), 2.5, BRASS_LIGHT)
	)
	c.queue_redraw()


## Restyles the HUD into a brass gauge cluster: ink shade bar, ember health bar, zone name.
## Returns the health fill so the HUD can resize it.
static func style_hud(root: Control) -> ColorRect:
	var bar: Control = root.get_node("ShadeBar")
	var back: ColorRect = bar.get_node("Back")
	var fill: ColorRect = bar.get_node("Fill")
	var shade_l: Label = root.get_node("ShadeLabel")
	var hp_l: Label = root.get_node("HealthLabel")
	var zone_l: Label = root.get_node("ZoneLabel")

	var plate := Panel.new()
	plate.add_theme_stylebox_override("panel", _box(Color(0.05, 0.04, 0.05, 0.82), Color(BRASS, 0.6), 2, 4))
	plate.position = Vector2(12, 8)
	plate.size = Vector2(268, 96)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plate)
	root.move_child(plate, 0)

	shade_l.position = Vector2(24, 14)
	shade_l.add_theme_font_override("font", spaced_font(3, 0.5))
	shade_l.add_theme_color_override("font_color", INK_LIGHT)
	shade_l.add_theme_font_size_override("font_size", 11)

	bar.position = Vector2(24, 34)
	bar.size = Vector2(244, 14)
	back.color = COAL
	fill.size = Vector2(244, 14)
	fill.color = INK
	bar.add_child(_frame())

	var hp_bar := Control.new()
	hp_bar.name = "HealthBar"
	hp_bar.position = Vector2(24, 58)
	hp_bar.size = Vector2(244, 18)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_bar)
	var hp_back := ColorRect.new()
	hp_back.color = COAL
	hp_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_bar.add_child(hp_back)
	var hp_fill := ColorRect.new()
	hp_fill.name = "Fill"
	hp_fill.color = EMBER
	hp_fill.size = hp_bar.size
	hp_bar.add_child(hp_fill)
	hp_bar.add_child(_frame())
	hp_l.reparent(hp_bar)
	hp_l.position = Vector2(0, -3)
	hp_l.size = Vector2(244, 22)
	hp_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_l.add_theme_font_size_override("font_size", 14)

	zone_l.position = Vector2(24, 82)
	zone_l.add_theme_font_override("font", spaced_font(2, 0.0))
	zone_l.add_theme_color_override("font_color", STEAM)
	zone_l.add_theme_font_size_override("font_size", 11)
	zone_l.uppercase = true
	return hp_fill


static func spaced_font(spacing: int, bold: float) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.spacing_glyph = spacing
	f.variation_embolden = bold
	return f


# --- helpers ---

static func _frame() -> Panel:
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), BRASS, 2, 2, false))
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = -2
	frame.offset_top = -2
	frame.offset_right = 2
	frame.offset_bottom = 2
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return frame


static func _box(bg: Color, border: Color, width: int, radius: int, center: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.draw_center = center
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb


static func _glow(sb: StyleBoxFlat) -> StyleBoxFlat:
	sb.shadow_color = Color(LAMP, 0.35)
	sb.shadow_size = 8
	return sb


static func _dot(d: int, col: Color, edge: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(d, d) * 0.5
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if dist <= d * 0.5 - 0.5:
				img.set_pixel(x, y, edge if dist > d * 0.5 - 2.5 else col)
	return ImageTexture.create_from_image(img)


static func _toggle(on: bool) -> ImageTexture:
	var w := 44
	var h := 22
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var track := BRASS_DARK if on else COAL
	var knob := LAMP if on else STEAM
	var r := h * 0.5
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(Vector2(clampf(p.x, r, w - r), r))
			if d <= r - 0.5:
				img.set_pixel(x, y, BRASS if d > r - 2.0 else track)
	var kc := Vector2(w - r if on else r, r)
	for y in h:
		for x in w:
			if Vector2(x + 0.5, y + 0.5).distance_to(kc) <= r - 4.0:
				img.set_pixel(x, y, knob)
	return ImageTexture.create_from_image(img)
