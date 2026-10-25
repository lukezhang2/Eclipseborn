extends CanvasLayer
## Shade bar + health + silver-gear currency (custom icon, fades in on first pickup).

@onready var shade_fill: ColorRect = $Root/ShadeBar/Fill
@onready var shade_back: ColorRect = $Root/ShadeBar/Back
@onready var health_label: Label = $Root/HealthLabel
@onready var zone_label: Label = $Root/ZoneLabel

var _currency_root: Control
var _currency_label: Label
var _health_fill: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	GameState.room_entered.connect(_on_room)
	GameState.currency_changed.connect(_on_currency)
	GameState.currency_hud_reveal.connect(_reveal_currency)
	_health_fill = UITheme.style_hud($Root)
	_build_currency_ui()
	_on_health(GameState.health, GameState.max_health)
	_on_shade(GameState.shade)
	_on_currency(GameState.currency)
	if GameState.currency_hud_unlocked:
		_currency_root.modulate.a = 1.0
		_currency_root.visible = true
	else:
		_currency_root.modulate.a = 0.0
		_currency_root.visible = false


func _build_currency_ui() -> void:
	_currency_root = Control.new()
	_currency_root.name = "CurrencyHud"
	_currency_root.position = Vector2(24, 112)  # Below the brass gauge plate.
	_currency_root.custom_minimum_size = Vector2(200, 32)
	$Root.add_child(_currency_root)
	var icon := TextureRect.new()
	icon.texture = _make_gear_icon()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(0, 0)
	icon.size = Vector2(28, 28)
	_currency_root.add_child(icon)
	_currency_label = Label.new()
	_currency_label.name = "Amount"
	_currency_label.position = Vector2(34, 2)
	_currency_label.add_theme_font_size_override("font_size", 20)
	_currency_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_currency_label.text = "0"
	_currency_root.add_child(_currency_label)


func _make_gear_icon() -> ImageTexture:
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(16, 16)
	# Teeth
	for i in 8:
		var a := TAU * float(i) / 8.0
		var tip := c + Vector2(cos(a), sin(a)) * 14.0
		_fill_circle(img, tip, 3.0, Color(0.78, 0.82, 0.9, 1))
	_fill_circle(img, c, 10.0, Color(0.72, 0.76, 0.84, 1))
	_fill_circle(img, c, 7.5, Color(0.55, 0.58, 0.64, 1))
	_fill_circle(img, c, 4.0, Color(0.9, 0.92, 0.96, 1))
	_fill_circle(img, c, 2.0, Color(0.15, 0.14, 0.16, 1))
	return ImageTexture.create_from_image(img)


func _fill_circle(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var r := int(ceil(radius))
	for y in range(int(center.y) - r, int(center.y) + r + 1):
		for x in range(int(center.x) - r, int(center.x) + r + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					img.set_pixel(x, y, col)


func _on_health(current: int, maximum: int) -> void:
	health_label.text = "%d / %d" % [current, maximum]
	var bar_w := (_health_fill.get_parent() as Control).size.x
	_health_fill.size.x = bar_w * clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0)


func _on_shade(ratio: float) -> void:
	var w := shade_back.size.x * clampf(ratio, 0.0, 1.0)
	shade_fill.size.x = w


func _on_room(zone_id: String, room_id: String) -> void:
	zone_label.text = "%s / %s" % [zone_id.replace("_", " "), room_id.replace("_", " ")]


func _on_currency(amount: int) -> void:
	if _currency_label:
		_currency_label.text = str(amount)


func _reveal_currency() -> void:
	if _currency_root == null:
		return
	_currency_root.visible = true
	_currency_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_currency_root, "modulate:a", 1.0, 0.85).set_ease(Tween.EASE_OUT)
