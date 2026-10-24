extends CanvasLayer
## Shade bar + numeric health. Always on during gameplay.

@onready var shade_fill: ColorRect = $Root/ShadeBar/Fill
@onready var shade_back: ColorRect = $Root/ShadeBar/Back
@onready var health_label: Label = $Root/HealthLabel
@onready var zone_label: Label = $Root/ZoneLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	GameState.room_entered.connect(_on_room)
	_on_health(GameState.health, GameState.max_health)
	_on_shade(GameState.shade)


func _on_health(current: int, maximum: int) -> void:
	health_label.text = "%d / %d" % [current, maximum]


func _on_shade(ratio: float) -> void:
	var w := shade_back.size.x * clampf(ratio, 0.0, 1.0)
	shade_fill.size.x = w


func _on_room(zone_id: String, room_id: String) -> void:
	zone_label.text = "%s / %s" % [zone_id.replace("_", " "), room_id.replace("_", " ")]
