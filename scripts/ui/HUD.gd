extends CanvasLayer
## Shade bar + health + currency (fades in on first gear pickup).

@onready var shade_fill: ColorRect = $Root/ShadeBar/Fill
@onready var shade_back: ColorRect = $Root/ShadeBar/Back
@onready var health_label: Label = $Root/HealthLabel
@onready var zone_label: Label = $Root/ZoneLabel

var _currency_root: Control
var _currency_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	GameState.room_entered.connect(_on_room)
	GameState.currency_changed.connect(_on_currency)
	GameState.currency_hud_reveal.connect(_reveal_currency)
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
	_currency_root.position = Vector2(24, 100)
	_currency_root.custom_minimum_size = Vector2(200, 28)
	$Root.add_child(_currency_root)
	var icon := Label.new()
	icon.text = "⚙"
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92))
	icon.position = Vector2(0, 0)
	_currency_root.add_child(icon)
	_currency_label = Label.new()
	_currency_label.name = "Amount"
	_currency_label.position = Vector2(28, 0)
	_currency_label.add_theme_font_size_override("font_size", 20)
	_currency_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_currency_label.text = "0"
	_currency_root.add_child(_currency_label)


func _on_health(current: int, maximum: int) -> void:
	health_label.text = "%d / %d" % [current, maximum]


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
