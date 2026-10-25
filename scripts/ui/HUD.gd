extends CanvasLayer
## Shade bar + health + gear currency (Pearl gear icon, fades in on first pickup).

@onready var shade_fill: ColorRect = $Root/ShadeBar/Fill
@onready var shade_back: ColorRect = $Root/ShadeBar/Back
@onready var health_label: Label = $Root/HealthLabel
@onready var zone_label: Label = $Root/ZoneLabel

var _currency_root: Control
var _currency_label: Label
var _health_fill: ColorRect
var _bag_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	GameState.room_entered.connect(_on_room)
	GameState.currency_changed.connect(_on_currency)
	GameState.currency_hud_reveal.connect(_reveal_currency)
	InputMapManager.bindings_changed.connect(_refresh_bag_label)
	_health_fill = UITheme.style_hud($Root)
	_build_currency_ui()
	_build_bag_button()
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
	var icon := UITheme.make_gear_icon(28.0)
	icon.position = Vector2(0, 0)
	_currency_root.add_child(icon)
	_currency_label = Label.new()
	_currency_label.name = "Amount"
	_currency_label.position = Vector2(34, 2)
	_currency_label.add_theme_font_size_override("font_size", 20)
	_currency_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_currency_label.text = "0"
	_currency_root.add_child(_currency_label)


func _build_bag_button() -> void:
	## Top-right Bag button — same inventory as the B key, with shop-style fade.
	_bag_btn = Button.new()
	_bag_btn.name = "BagButton"
	_bag_btn.theme = UITheme.get_theme()
	_bag_btn.theme_type_variation = "KeyButton"
	_bag_btn.focus_mode = Control.FOCUS_NONE
	_bag_btn.anchor_left = 1.0
	_bag_btn.anchor_right = 1.0
	_bag_btn.offset_left = -132.0
	_bag_btn.offset_right = -24.0
	_bag_btn.offset_top = 20.0
	_bag_btn.offset_bottom = 52.0
	_bag_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_bag_btn.pressed.connect(_on_bag_pressed)
	$Root.add_child(_bag_btn)
	_refresh_bag_label()


func _refresh_bag_label() -> void:
	if _bag_btn == null:
		return
	var key := InputMapManager.get_slot_text("inventory", 0)
	_bag_btn.text = "Bag (%s)" % key


func _on_bag_pressed() -> void:
	var menu := get_tree().get_first_node_in_group("inventory_menu")
	if menu and menu.has_method("toggle"):
		menu.toggle()


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
