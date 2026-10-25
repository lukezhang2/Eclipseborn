extends CanvasLayer
## Backpack (B) — does NOT pause. Equipment + Consumables tabs; player preview + 3 accessory slots.


enum Tab { EQUIPMENT, CONSUMABLES }

var root: Control
var dim: ColorRect
var panel: PanelContainer
var gears_label: Label
var status_label: Label
var hint_label: Label
var tab_equip_btn: Button
var tab_consumable_btn: Button
var content: Control
var equip_page: Control
var consumable_page: Control
var preview_sprite: AnimatedSprite2D
var slot_buttons: Array = []
var unequipped_box: VBoxContainer
var consumable_box: VBoxContainer

var _busy: bool = false
var _open: bool = false
var _fade_tw: Tween
var _tab: int = Tab.EQUIPMENT
var _picking_slot: int = -1 ## When >= 0, next unequipped click equips into this slot.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 14
	_build_ui()
	root.visible = false
	root.modulate.a = 0.0
	add_to_group("inventory_menu")
	if not GameState.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_changed.connect(_on_inventory_changed)
	if not GameState.equipment_changed.is_connected(_on_equipment_changed):
		GameState.equipment_changed.connect(_on_equipment_changed)
	if not GameState.currency_changed.is_connected(_on_currency):
		GameState.currency_changed.connect(_on_currency)
	if not GameState.ability_unlocked.is_connected(_on_ability):
		GameState.ability_unlocked.connect(_on_ability)


func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Let world clicks/keys through outside the plate — game stays live.
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITheme.COAL, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(620, 560)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	center.add_child(panel)
	UITheme.add_plate(panel, Vector2(28, 24))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Backpack"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, 30)
	vbox.add_child(title)

	gears_label = Label.new()
	gears_label.add_theme_font_size_override("font_size", 16)
	gears_label.add_theme_color_override("font_color", UITheme.LAMP)
	gears_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(UITheme.gear_row(gears_label, 20.0))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	vbox.add_child(tabs)
	tab_equip_btn = Button.new()
	tab_equip_btn.text = "Equipment"
	tab_equip_btn.custom_minimum_size = Vector2(150, 36)
	tab_equip_btn.pressed.connect(func() -> void: _set_tab(Tab.EQUIPMENT))
	tabs.add_child(tab_equip_btn)
	tab_consumable_btn = Button.new()
	tab_consumable_btn.text = "Consumables"
	tab_consumable_btn.custom_minimum_size = Vector2(150, 36)
	tab_consumable_btn.pressed.connect(func() -> void: _set_tab(Tab.CONSUMABLES))
	tabs.add_child(tab_consumable_btn)

	content = Control.new()
	content.custom_minimum_size = Vector2(560, 360)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	equip_page = _build_equipment_page()
	content.add_child(equip_page)
	consumable_page = _build_consumables_page()
	content.add_child(consumable_page)

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
	close_btn.custom_minimum_size = Vector2(140, 38)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", UITheme.STEAM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)
	_refresh_hint()
	_set_tab(Tab.EQUIPMENT)


func _build_equipment_page() -> Control:
	var page := HBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 18)
	page.visible = true

	## Left: player preview + accessory slots.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	left.add_theme_constant_override("separation", 10)
	page.add_child(left)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(200, 200)
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(UITheme.COAL, 0.85)
	frame_sb.border_color = Color(UITheme.BRASS_DARK, 0.9)
	frame_sb.set_border_width_all(2)
	frame_sb.set_corner_radius_all(6)
	preview_frame.add_theme_stylebox_override("panel", frame_sb)
	left.add_child(preview_frame)

	var preview_center := CenterContainer.new()
	preview_center.custom_minimum_size = Vector2(200, 200)
	preview_frame.add_child(preview_center)

	preview_sprite = AnimatedSprite2D.new()
	preview_sprite.sprite_frames = SpiritSprites.build_frames()
	preview_sprite.play("idle")
	preview_sprite.centered = true
	preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_sprite.scale = Vector2(2.4, 2.4)
	## AnimatedSprite2D isn't a Control — wrap in a Control holder for CenterContainer.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(120, 160)
	holder.add_child(preview_sprite)
	preview_sprite.position = Vector2(60, 90)
	preview_center.add_child(holder)

	var slot_row := HBoxContainer.new()
	slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_row.add_theme_constant_override("separation", 8)
	left.add_child(slot_row)
	slot_buttons.clear()
	for i in GameState.ACCESSORY_SLOT_COUNT:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.clip_text = true
		slot.pressed.connect(_on_slot_pressed.bind(i))
		slot_row.add_child(slot)
		slot_buttons.append(slot)

	var slot_hint := Label.new()
	slot_hint.text = "Accessories"
	slot_hint.add_theme_font_size_override("font_size", 12)
	slot_hint.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
	slot_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(slot_hint)

	## Right: unequipped accessories + key items.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	page.add_child(right)

	var owned_title := Label.new()
	owned_title.text = "Owned accessories"
	owned_title.add_theme_font_size_override("font_size", 14)
	owned_title.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
	right.add_child(owned_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(300, 280)
	right.add_child(scroll)
	unequipped_box = VBoxContainer.new()
	unequipped_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unequipped_box.add_theme_constant_override("separation", 6)
	scroll.add_child(unequipped_box)
	return page


func _build_consumables_page() -> Control:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 8)
	page.visible = false

	var title := Label.new()
	title.text = "Supplies"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
	page.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(520, 300)
	page.add_child(scroll)
	consumable_box = VBoxContainer.new()
	consumable_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consumable_box.add_theme_constant_override("separation", 8)
	scroll.add_child(consumable_box)
	return page


func _set_tab(which: int) -> void:
	_tab = which
	_picking_slot = -1
	equip_page.visible = _tab == Tab.EQUIPMENT
	consumable_page.visible = _tab == Tab.CONSUMABLES
	tab_equip_btn.disabled = _tab == Tab.EQUIPMENT
	tab_consumable_btn.disabled = _tab == Tab.CONSUMABLES
	if _open:
		_refresh_active_page()


func _refresh_hint() -> void:
	var key := InputMapManager.get_slot_text("inventory", 0)
	hint_label.text = "%s to close · game stays running" % key


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
	## Esc closes bag without opening the pause menu.
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _busy or _open:
		return
	## Still avoid stacking over shop / pause / fast travel.
	if GameState.is_paused:
		return
	_picking_slot = -1
	_refresh_hint()
	status_label.text = " "
	_refresh_gears()
	_refresh_active_page()
	root.visible = true
	_open = true
	root.modulate.a = 0.0
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.96, 0.96)
	## Do NOT pause — player keeps moving while the bag is open.
	_kill_fade()
	_fade_tw = create_tween()
	_fade_tw.set_parallel(true)
	_fade_tw.tween_property(root, "modulate:a", 1.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_fade_tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if preview_sprite and preview_sprite.sprite_frames:
		preview_sprite.play("idle")


func close() -> void:
	if not _open or _busy:
		return
	_busy = true
	_picking_slot = -1
	_kill_fade()
	_fade_tw = create_tween()
	_fade_tw.set_parallel(true)
	_fade_tw.tween_property(root, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_fade_tw.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.22).set_ease(Tween.EASE_IN)
	_fade_tw.set_parallel(false)
	_fade_tw.tween_callback(func() -> void:
		root.visible = false
		_open = false
		_busy = false
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
		_refresh_active_page()


func _on_equipment_changed(_slots: Array) -> void:
	if _open:
		_refresh_active_page()


func _on_currency(_amount: int) -> void:
	if _open:
		_refresh_gears()


func _on_ability(_id: String) -> void:
	if _open:
		_refresh_active_page()


func _refresh_gears() -> void:
	gears_label.text = "Silver gears: %d" % GameState.currency


func _refresh_active_page() -> void:
	if _tab == Tab.EQUIPMENT:
		_refresh_equipment()
	else:
		_refresh_consumables()


func _refresh_equipment() -> void:
	var slots := GameState._normalize_equipment_slots(GameState.equipment_slots)
	GameState.equipment_slots = slots
	for i in slot_buttons.size():
		var btn: Button = slot_buttons[i]
		var id := str(slots[i])
		if id == "":
			btn.text = "—"
			btn.tooltip_text = "Empty accessory slot — click, then pick an item"
			btn.modulate = Color(1, 1, 1, 0.85)
		else:
			var short := ShopCatalog.display_name(id)
			if short.length() > 10:
				short = short.substr(0, 9) + "…"
			btn.text = short
			btn.tooltip_text = "%s — click to unequip" % ShopCatalog.display_name(id)
			btn.modulate = Color.WHITE
		if _picking_slot == i:
			btn.modulate = Color(UITheme.LAMP.r, UITheme.LAMP.g, UITheme.LAMP.b, 1.0)

	for c in unequipped_box.get_children():
		c.queue_free()

	var any := false
	for id in ShopCatalog.all_ids():
		var it := ShopCatalog.get_item(id)
		if str(it.get("kind", "")) != "ability":
			continue
		if not ShopCatalog.owns_ability(id):
			continue
		any = true
		var equipped := GameState.is_accessory_equipped(id)
		unequipped_box.add_child(_make_accessory_row(id, equipped))

	## Key relics under the accessory list.
	var keys := _key_item_rows()
	if not keys.is_empty():
		var sep := Label.new()
		sep.text = "Key items"
		sep.add_theme_font_size_override("font_size", 13)
		sep.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
		unequipped_box.add_child(sep)
		for row in keys:
			unequipped_box.add_child(row)

	if not any and keys.is_empty():
		var empty := Label.new()
		empty.text = "(No accessories yet — buy abilities at a shop or earn them.)"
		empty.add_theme_color_override("font_color", UITheme.STEAM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unequipped_box.add_child(empty)

	if _picking_slot >= 0:
		status_label.text = "Choose an accessory for slot %d…" % (_picking_slot + 1)
	elif status_label.text.begins_with("Choose"):
		status_label.text = " "


func _refresh_consumables() -> void:
	for c in consumable_box.get_children():
		c.queue_free()
	var rows := _consumable_rows()
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "(No supplies — buy tonics at a shop.)"
		empty.add_theme_color_override("font_color", UITheme.STEAM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		consumable_box.add_child(empty)
		return
	for row in rows:
		consumable_box.add_child(row)


func _on_slot_pressed(slot: int) -> void:
	var id := str(GameState.equipment_slots[slot]) if slot < GameState.equipment_slots.size() else ""
	if id != "":
		GameState.unequip_accessory_slot(slot)
		status_label.text = "Unequipped %s." % ShopCatalog.display_name(id)
		SaveManager.autosave()
		_picking_slot = -1
		_refresh_equipment()
		return
	## Empty slot — enter pick mode.
	_picking_slot = slot
	status_label.text = "Choose an accessory for slot %d…" % (slot + 1)
	_refresh_equipment()


func _on_equip_pressed(item_id: String) -> void:
	var slot := _picking_slot
	_picking_slot = -1
	if GameState.equip_accessory(item_id, slot):
		status_label.text = "Equipped %s." % ShopCatalog.display_name(item_id)
		SaveManager.autosave()
	else:
		status_label.text = "No empty accessory slot."
	_refresh_equipment()


func _on_unequip_pressed(item_id: String) -> void:
	if GameState.unequip_accessory(item_id):
		status_label.text = "Unequipped %s." % ShopCatalog.display_name(item_id)
		SaveManager.autosave()
	_picking_slot = -1
	_refresh_equipment()


func _make_accessory_row(item_id: String, equipped: bool) -> Control:
	var it := ShopCatalog.get_item(item_id)
	var row := _row_panel()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var name_l := Label.new()
	name_l.text = str(it.get("name", item_id))
	name_l.add_theme_font_size_override("font_size", 15)
	name_l.add_theme_color_override("font_color", UITheme.CREAM)
	info.add_child(name_l)
	var desc := Label.new()
	desc.text = str(it.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", UITheme.STEAM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 34)
	if equipped:
		btn.text = "Unequip"
		btn.pressed.connect(_on_unequip_pressed.bind(item_id))
	else:
		btn.text = "Equip"
		btn.pressed.connect(_on_equip_pressed.bind(item_id))
	h.add_child(btn)
	return row


func _consumable_rows() -> Array:
	var rows: Array = []
	for id in ["heal_tonic", "shade_vial"]:
		var n := GameState.get_inventory_count(id)
		if n <= 0:
			continue
		rows.append(_make_item_row(id, n, true))
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
	name_l.add_theme_font_size_override("font_size", 15)
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
	name_l.text = "%s ×%d" % [str(it.get("name", item_id)), count]
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
	_refresh_consumables()
	_refresh_gears()
