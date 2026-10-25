extends CanvasLayer
## Checkpoint fast-travel picker. Fades open/closed from rest hearths.


var root: Control
var dim: ColorRect
var panel: PanelContainer
var list: ItemList
var _entries: Array = []
var _busy: bool = false
var _fade_tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	_build_ui()
	root.visible = false
	root.modulate.a = 0.0


func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UITheme.get_theme()
	add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITheme.COAL, 0.78)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(540, 440)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	center.add_child(panel)
	UITheme.add_plate(panel, Vector2(28, 24))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Fast Travel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, 34)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Rest hearths you've activated"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", UITheme.STEAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	list = ItemList.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(460, 250)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_color_override("font_color", UITheme.CREAM)
	list.add_theme_color_override("font_hovered_color", UITheme.LAMP)
	list.add_theme_color_override("font_selected_color", UITheme.BRASS_LIGHT)
	list.item_activated.connect(_on_activated)
	vbox.add_child(list)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	vbox.add_child(row)

	var go := Button.new()
	go.text = "Travel"
	go.custom_minimum_size = Vector2(150, 40)
	go.pressed.connect(func() -> void:
		var sel := list.get_selected_items()
		if not sel.is_empty():
			_on_activated(sel[0])
	)
	row.add_child(go)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(150, 40)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Double-click a hearth · Esc to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", UITheme.STEAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if root == null or not root.visible or _busy:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("menu"):
		close()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	if _busy:
		return
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
	root.modulate.a = 0.0
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.96, 0.96)
	GameState.set_paused(true)
	_kill_fade()
	_fade_tw = create_tween()
	_fade_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tw.set_parallel(true)
	_fade_tw.tween_property(root, "modulate:a", 1.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_fade_tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func close() -> void:
	if not root.visible or _busy:
		return
	_busy = true
	_kill_fade()
	_fade_tw = create_tween()
	_fade_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tw.set_parallel(true)
	_fade_tw.tween_property(root, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_fade_tw.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.22).set_ease(Tween.EASE_IN)
	_fade_tw.set_parallel(false)
	_fade_tw.tween_callback(func() -> void:
		root.visible = false
		_busy = false
		GameState.set_paused(false)
	)


func _kill_fade() -> void:
	if _fade_tw and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = null


func _on_activated(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var e: Dictionary = _entries[index]
	if str(e.get("id", "")) == GameState.checkpoint_path and str(e.get("zone", "")) == GameState.current_zone_id:
		close()
		return
	close()
	await get_tree().create_timer(0.24, true, false, true).timeout
	GameState.travel_to_checkpoint(e)
