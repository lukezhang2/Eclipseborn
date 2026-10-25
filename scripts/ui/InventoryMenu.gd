extends CanvasLayer
## Player inventory — opens on B with the same fade as shop / fast travel.


var root: Control
var dim: ColorRect
var panel: PanelContainer
var gears_label: Label
var list_box: VBoxContainer
var status_label: Label
var hint_label: Label

var _busy: bool = false
var _open: bool = false
var _fade_tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 14
	_build_ui()
	root.visible = false
	root.modulate.a = 0.0
	add_to_group("inventory_menu")
	if not GameState.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_changed.connect(_on_inventory_changed)
	if not GameState.currency_changed.is_connected(_on_currency):
		GameState.currency_changed.connect(_on_currency)
	if not GameState.ability_unlocked.is_connected(_on_ability):
		GameState.ability_unlocked.connect(_on_ability)


func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UITheme.get_theme()
	add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITheme.COAL, 0.8)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(560, 520)
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
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, 32)
	vbox.add_child(title)

	gears_label = Label.new()
	gears_label.add_theme_font_size_override("font_size", 18)
	gears_label.add_theme_color_override("font_color", UITheme.LAMP)
	gears_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gears_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.name = "List"
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)

	status_label = Label.new()
	status_label.text = " "
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", UITheme.STEAM)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(150, 40)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", UITheme.STEAM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)
	_refresh_hint()


func _refresh_hint() -> void:
	var key := InputMapManager.get_slot_text("inventory", 0)
	hint_label.text = "%s or Esc to close" % key


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if _busy:
			get_viewport().set_input_as_handled()
			return
		if _open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not _open or _busy:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _busy or _open:
		return
	## Block if another modal already paused the game (shop / fast travel / pause).
	if GameState.is_paused:
		return
	_refresh_hint()
	status_label.text = " "
	_refresh_gears()
	_refresh_list()
	root.visible = true
	_open = true
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
	if not _open or _busy:
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
		_open = false
		_busy = false
		GameState.set_paused(false)
	)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _kill_fade() -> void:
	if _fade_tw and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = null


func _on_inventory_changed(_items: Dictionary) -> void:
	if _open:
		_refresh_list()


func _on_currency(_amount: int) -> void:
	if _open:
		_refresh_gears()


func _on_ability(_id: String) -> void:
	if _open:
		_refresh_list()


func _refresh_gears() -> void:
	gears_label.text = "Silver gears: %d" % GameState.currency


func _refresh_list() -> void:
	for c in list_box.get_children():
		c.queue_free()

	var consumables := _consumable_rows()
	var abilities := _ability_rows()
	var keys := _key_item_rows()

	if consumables.is_empty() and abilities.is_empty() and keys.is_empty():
		var empty := Label.new()
		empty.text = "(Empty — buy supplies at a shop, or find relics in the tower.)"
		empty.add_theme_color_override("font_color", UITheme.STEAM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_box.add_child(empty)
		return

	if not consumables.is_empty():
		list_box.add_child(_section("Supplies"))
		for row in consumables:
			list_box.add_child(row)
	if not abilities.is_empty():
		list_box.add_child(_section("Abilities"))
		for row in abilities:
			list_box.add_child(row)
	if not keys.is_empty():
		list_box.add_child(_section("Key Items"))
		for row in keys:
			list_box.add_child(row)


func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
	return l


func _consumable_rows() -> Array:
	var rows: Array = []
	for id in ["heal_tonic", "shade_vial"]:
		var n := GameState.get_inventory_count(id)
		if n <= 0:
			continue
		rows.append(_make_item_row(id, n, true))
	return rows


func _ability_rows() -> Array:
	var rows: Array = []
	for id in ShopCatalog.all_ids():
		var it := ShopCatalog.get_item(id)
		if str(it.get("kind", "")) != "ability":
			continue
		if not ShopCatalog.owns_ability(id):
			continue
		rows.append(_make_item_row(id, 1, false))
	return rows


func _key_item_rows() -> Array:
	var rows: Array = []
	if GameState.is_collected("tower_crystal_piece"):
		rows.append(_make_plain_row(
			"Shadow Crystal Piece",
			"A shard from the Dial Arena — unlocked Double Jump."
		))
	var hearts := int((GameState.max_health - 100) / float(GameState.SHADE_HEART_BONUS))
	if hearts > 0:
		rows.append(_make_plain_row(
			"Shade Hearts ×%d" % hearts,
			"Permanent health from crystal fragments."
		))
	if GameState.wickwright_defeated():
		rows.append(_make_plain_row(
			"Wickwright's Fall",
			"The dial boss is gone. The village descent is open."
		))
	return rows


func _make_plain_row(title: String, desc: String) -> Control:
	var row := _row_panel()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var name_l := Label.new()
	name_l.text = title
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", UITheme.CREAM)
	info.add_child(name_l)
	var desc_l := Label.new()
	desc_l.text = desc
	desc_l.add_theme_font_size_override("font_size", 11)
	desc_l.add_theme_color_override("font_color", UITheme.STEAM)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_l)
	return row


func _make_item_row(item_id: String, count: int, usable: bool) -> Control:
	var it := ShopCatalog.get_item(item_id)
	var row := _row_panel()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_l := Label.new()
	var title := str(it.get("name", item_id))
	if usable and count > 1:
		title = "%s ×%d" % [title, count]
	elif usable:
		title = "%s ×%d" % [title, count]
	name_l.text = title
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", UITheme.CREAM)
	info.add_child(name_l)

	var desc := Label.new()
	desc.text = str(it.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", UITheme.STEAM)
	info.add_child(desc)

	if usable:
		var use := Button.new()
		use.text = "Use"
		use.custom_minimum_size = Vector2(88, 36)
		use.pressed.connect(_on_use.bind(item_id))
		h.add_child(use)
	else:
		var owned := Label.new()
		owned.text = "Owned"
		owned.add_theme_font_size_override("font_size", 13)
		owned.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
		owned.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(owned)
	return row


func _row_panel() -> PanelContainer:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UITheme.IRON, 0.92)
	sb.border_color = Color(UITheme.BRASS_DARK, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)
	return row


func _on_use(item_id: String) -> void:
	if _busy:
		return
	if not GameState.use_inventory_item(item_id):
		status_label.text = "Can't use that right now."
		return
	AudioManager.play_currency()
	status_label.text = "Used %s." % ShopCatalog.display_name(item_id)
	SaveManager.autosave()
	_refresh_list()
	_refresh_gears()
