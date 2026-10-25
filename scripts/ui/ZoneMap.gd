extends CanvasLayer
## Continuous side-view zone picture. Live player icon; does not pause the game.

## World-space panorama per zone: floor ribbon + landmarks + fog by room x-spans.
const ZONE_PICTURES := {
	"cursed_cottage": {
		"x_range": Vector2(0, 4000),
		"y_range": Vector2(180, 500),
		"rooms": [
			{"id": "hall", "x0": 0, "x1": 800},
			{"id": "crate", "x0": 800, "x1": 1600},
			{"id": "pull", "x0": 1600, "x1": 2400},
			{"id": "chest", "x0": 2400, "x1": 3200},
			{"id": "hatch", "x0": 3200, "x1": 4000},
		],
		"landmarks": [
			{"id": "hall", "x": 400, "y": 482, "kind": "lamp", "label": "Hall", "room": "hall"},
			{"id": "crate", "x": 1120, "y": 382, "kind": "platform", "label": "Crate", "room": "crate"},
			{"id": "pull", "x": 2080, "y": 482, "kind": "mark", "label": "Pull wall", "room": "pull"},
			{"id": "chest", "x": 2800, "y": 482, "kind": "platform", "label": "Ledges", "room": "chest"},
			{"id": "hatch", "x": 3600, "y": 482, "kind": "hatch", "label": "Hatch", "room": "hatch"},
		],
	},
	"lantern_village": {
		"x_range": Vector2(0, 3200),
		"y_range": Vector2(160, 520),
		"rooms": [
			{"id": "gate", "x0": 50, "x1": 550},
			{"id": "street_a", "x0": 550, "x1": 1150},
			{"id": "street_b", "x0": 1150, "x1": 1750},
			{"id": "square", "x0": 1750, "x1": 2450},
			{"id": "tower", "x0": 2450, "x1": 3200},
		],
		"landmarks": [
			{"id": "gate", "x": 200, "y": 500, "kind": "lamp", "label": "Gate", "room": "gate"},
			{"id": "house_keep", "x": 520, "y": 500, "kind": "house", "label": "Lantern Keep", "room": "gate"},
			{"id": "house_gear", "x": 980, "y": 500, "kind": "house", "label": "Gearwright", "room": "street_a"},
			{"id": "street_b", "x": 1500, "y": 500, "kind": "lamp", "label": "Street", "room": "street_b"},
			{"id": "house_inn", "x": 1780, "y": 500, "kind": "house", "label": "Shade Inn", "room": "square"},
			{"id": "tower", "x": 2900, "y": 500, "kind": "tower", "label": "Clockwork", "room": "tower"},
		],
	},
	"prototype": {
		"x_range": Vector2(0, 1200),
		"y_range": Vector2(160, 520),
		"rooms": [
			{"id": "puzzle", "x0": 0, "x1": 1200},
		],
		"landmarks": [
			{"id": "puzzle", "x": 600, "y": 500, "kind": "mark", "label": "Puzzle", "room": "puzzle"},
		],
	},
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
	var hint := root.get_node_or_null("Hint")
	if hint is Label:
		(hint as Label).text = "Tab to close · your position updates live"


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
	title.text = "Zone: %s" % GameState.current_zone_id.replace("_", " ").capitalize()
	_refresh_map()


func close() -> void:
	root.visible = false


func _refresh_map() -> void:
	var zone := GameState.current_zone_id
	var discovered: Array = GameState.discovered_rooms.get(zone, [])
	var picture: Dictionary = ZONE_PICTURES.get(zone, {})
	if picture.is_empty():
		picture = _fallback_picture(zone)

	var x_range: Vector2 = picture.get("x_range", Vector2(GameState.map_min_x, GameState.map_max_x))
	var y_range: Vector2 = picture.get("y_range", Vector2(160, 520))
	var landmarks: Array = picture.get("landmarks", [])
	var rooms: Array = picture.get("rooms", [])

	var player_pos := Vector2.ZERO
	var has_player := false
	if GameState.player != null and is_instance_valid(GameState.player):
		player_pos = (GameState.player as Node2D).global_position
		has_player = true
	elif GameState.last_position != Vector2.ZERO:
		player_pos = GameState.last_position
		has_player = true

	if not draw_area.has_method("set_picture_data"):
		draw_area.set_script(preload("res://scripts/ui/MapDraw.gd"))
	draw_area.set_picture_data(
		zone,
		discovered,
		x_range,
		y_range,
		landmarks,
		rooms,
		player_pos,
		has_player
	)


func _fallback_picture(zone: String) -> Dictionary:
	## House interiors and unknown zones: one continuous strip from live map bounds.
	var x0 := GameState.map_min_x
	var x1 := maxf(GameState.map_max_x, x0 + 200.0)
	var room_id := GameState.current_room_id if GameState.current_room_id != "" else "interior"
	var mid_x := (x0 + x1) * 0.5
	var label := zone.replace("_", " ").capitalize()
	return {
		"x_range": Vector2(x0 - 20.0, x1 + 20.0),
		"y_range": Vector2(160, 520),
		"rooms": [{"id": room_id, "x0": x0, "x1": x1}],
		"landmarks": [
			{"id": room_id, "x": mid_x, "y": 500, "kind": "house", "label": label, "room": room_id},
		],
	}
