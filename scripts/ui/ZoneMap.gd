extends CanvasLayer
## Tab map of the current zone with player icons. Does not pause the game.

const ZONE_LAYOUTS := {
	"cursed_cottage": [
		{"id": "hall", "rect": Rect2(40, 120, 160, 80)},
		{"id": "crate", "rect": Rect2(220, 120, 160, 80)},
		{"id": "chest", "rect": Rect2(400, 120, 160, 80)},
		{"id": "hatch", "rect": Rect2(580, 120, 160, 80)},
	],
	"lantern_village": [
		{"id": "gate", "rect": Rect2(40, 100, 140, 70)},
		{"id": "street_a", "rect": Rect2(200, 100, 140, 70)},
		{"id": "street_b", "rect": Rect2(360, 100, 140, 70)},
		{"id": "square", "rect": Rect2(200, 200, 200, 90)},
	],
	"prototype": [
		{"id": "puzzle", "rect": Rect2(80, 100, 400, 200)},
	],
}

@onready var root: Control = $Root
@onready var draw_area: Control = $Root/MapArea
@onready var title: Label = $Root/Title


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	if draw_area.get_script() == null:
		draw_area.set_script(preload("res://scripts/ui/MapDraw.gd"))
	var dim := root.get_node_or_null("Dim")
	if dim is ColorRect:
		(dim as ColorRect).color = Color(0, 0, 0, 0.35)
		(dim as ColorRect).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if root.visible:
		_refresh_map()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zone_map"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if root.visible:
		close()
	else:
		open()


func open() -> void:
	root.visible = true
	title.text = "Zone: %s (live)" % GameState.current_zone_id.replace("_", " ").capitalize()
	_refresh_map()


func close() -> void:
	root.visible = false


func _refresh_map() -> void:
	var zone := GameState.current_zone_id
	var layout: Array = ZONE_LAYOUTS.get(zone, [])
	var discovered: Array = GameState.discovered_rooms.get(zone, [])
	if not draw_area.has_method("set_map_data"):
		draw_area.set_script(preload("res://scripts/ui/MapDraw.gd"))
	draw_area.set_map_data(layout, discovered, GameState.current_room_id)
