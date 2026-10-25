extends CanvasLayer
## Checkpoint fast-travel picker. Opened by interacting with a rest hearth.


var root: Control
var list: ItemList
var _entries: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	_build_ui()
	root.visible = false


func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(340, 120)
	panel.custom_minimum_size = Vector2(520, 420)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Fast Travel"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Rest hearths you've activated"
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	vbox.add_child(sub)

	list = ItemList.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(480, 280)
	list.item_activated.connect(_on_activated)
	vbox.add_child(list)

	var row := HBoxContainer.new()
	vbox.add_child(row)
	var go := Button.new()
	go.text = "Travel"
	go.pressed.connect(func() -> void:
		var sel := list.get_selected_items()
		if not sel.is_empty():
			_on_activated(sel[0])
	)
	row.add_child(go)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Double-click a hearth · Esc to close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	vbox.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if root == null or not root.visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	_entries = GameState.get_activated_checkpoints()
	list.clear()
	for e in _entries:
		var zone := str(e.get("zone", "")).replace("_", " ").capitalize()
		var name := str(e.get("name", e.get("id", "Rest")))
		var here := str(e.get("id", "")) == GameState.checkpoint_path and str(e.get("zone", "")) == GameState.current_zone_id
		list.add_item("%s — %s%s" % [name, zone, "  (here)" if here else ""])
	if _entries.is_empty():
		list.add_item("(No other hearths yet — rest at more checkpoints)")
	root.visible = true
	GameState.set_paused(true)


func close() -> void:
	root.visible = false
	GameState.set_paused(false)


func _on_activated(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var e: Dictionary = _entries[index]
	## Don't "travel" to the hearth you're already at in the same zone.
	if str(e.get("id", "")) == GameState.checkpoint_path and str(e.get("zone", "")) == GameState.current_zone_id:
		close()
		return
	close()
	GameState.travel_to_checkpoint(e)
