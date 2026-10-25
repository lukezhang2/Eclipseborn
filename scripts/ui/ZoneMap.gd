extends CanvasLayer
## Whole-zone side view fitted into the map panel. Live player icon; does not pause the game.

@onready var root: Control = $Root
@onready var draw_area: Control = $Root/MapArea


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
		(hint as Label).text = "Tab to close"
		var hint_label := hint as Label
		hint_label.add_theme_font_override("font", UITheme.spaced_font(2, 0.35))
		hint_label.add_theme_font_size_override("font_size", 18)
		hint_label.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
		hint_label.add_theme_color_override("font_outline_color", UITheme.COAL)
		hint_label.add_theme_constant_override("outline_size", 4)


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
	GameState.reveal_screen()
	_refresh_map()


func close() -> void:
	root.visible = false
	SaveManager.autosave()


func _refresh_map() -> void:
	var zone := GameState.current_zone_id
	var player_pos := Vector2.ZERO
	var has_player := false
	if GameState.player != null and is_instance_valid(GameState.player):
		player_pos = (GameState.player as Node2D).global_position
		has_player = true
	elif GameState.last_position != Vector2.ZERO:
		player_pos = GameState.last_position
		has_player = true
	if not draw_area.has_method("set_zone_map"):
		draw_area.set_script(preload("res://scripts/ui/MapDraw.gd"))
	draw_area.set_zone_map(zone, player_pos, has_player)
