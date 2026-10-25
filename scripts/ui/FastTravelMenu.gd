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
	add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.7)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(540, 440)
	_style_panel(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Fast Travel"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Rest hearths you've activated"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.62, 0.56, 0.48))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(0.55, 0.4, 0.25, 0.55)
	vbox.add_child(rule)

	list = ItemList.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(480, 260)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	list.add_theme_color_override("font_hovered_color", Color(1.0, 0.95, 0.85))
	list.add_theme_color_override("font_selected_color", Color(1.0, 0.92, 0.7))
	list.item_activated.connect(_on_activated)
	vbox.add_child(list)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var go := Button.new()
	go.text = "Travel"
	go.custom_minimum_size = Vector2(140, 36)
	_style_button(go, true)
	go.pressed.connect(func() -> void:
		var sel := list.get_selected_items()
		if not sel.is_empty():
			_on_activated(sel[0])
	)
	row.add_child(go)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(140, 36)
	_style_button(close_btn, false)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Double-click a hearth · Esc to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _style_panel(p: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.1, 0.96)
	sb.border_color = Color(0.7, 0.5, 0.28, 0.92)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	p.add_theme_stylebox_override("panel", sb)


func _style_button(btn: Button, accent: bool) -> void:
	var sb := StyleBoxFlat.new()
	if accent:
		sb.bg_color = Color(0.34, 0.24, 0.12, 1.0)
		sb.border_color = Color(0.9, 0.68, 0.35, 0.95)
	else:
		sb.bg_color = Color(0.15, 0.13, 0.15, 1.0)
		sb.border_color = Color(0.45, 0.4, 0.35, 0.8)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate()
	hover.bg_color = sb.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := sb.duplicate()
	pressed.bg_color = sb.bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))


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
	## Don't "travel" to the hearth you're already at in the same zone.
	if str(e.get("id", "")) == GameState.checkpoint_path and str(e.get("zone", "")) == GameState.current_zone_id:
		close()
		return
	close()
	## Let fade start, then travel after a beat so close tween isn't cut mid-scene-change.
	await get_tree().create_timer(0.24, true, false, true).timeout
	GameState.travel_to_checkpoint(e)
