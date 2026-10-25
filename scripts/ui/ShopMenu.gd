extends CanvasLayer
## Shopkeeper buy menu — fades open/closed; gear prices + stock.


var root: Control
var dim: ColorRect
var panel: PanelContainer
var title_label: Label
var gears_label: Label
var list_box: VBoxContainer
var status_label: Label

var _shop_key: String = ""
var _keeper_name: String = "Shop"
var _entries: Array = []
var _busy: bool = false
var _fade_tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 13
	_build_ui()
	root.visible = false
	root.modulate.a = 0.0
	add_to_group("shop_menu")


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
	panel.custom_minimum_size = Vector2(580, 500)
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

	title_label = Label.new()
	title_label.text = "Shop"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title_label, 32)
	vbox.add_child(title_label)

	var sub := Label.new()
	sub.text = "Spend silver gears"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", UITheme.STEAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	gears_label = Label.new()
	gears_label.add_theme_font_size_override("font_size", 18)
	gears_label.add_theme_color_override("font_color", UITheme.LAMP)
	gears_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gears_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 300)
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

	var hint := Label.new()
	hint.text = "Esc to close"
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


func open_shop(keeper_name: String, shop_key: String, shop_items: Array) -> void:
	if _busy:
		return
	_keeper_name = keeper_name if keeper_name != "" else "Shop"
	_shop_key = shop_key if shop_key != "" else "shop"
	## Empty list = nothing for sale (editor shopkeepers default to all off).
	_entries = ShopCatalog.normalize_shop_items(shop_items)
	title_label.text = _keeper_name
	UITheme.style_title(title_label, 32)
	status_label.text = " "
	_refresh_list()
	_refresh_gears()
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


func _refresh_gears() -> void:
	gears_label.text = "Silver gears: %d" % GameState.currency


func _refresh_list() -> void:
	for c in list_box.get_children():
		c.queue_free()
	if _entries.is_empty():
		var empty := Label.new()
		empty.text = "(Nothing for sale)"
		empty.add_theme_color_override("font_color", UITheme.STEAM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_box.add_child(empty)
		return
	for entry in _entries:
		var id := str(entry.get("id", ""))
		var base_stock := int(entry.get("stock", -1))
		var remaining := GameState.get_shop_stock(_shop_key, id, base_stock)
		list_box.add_child(_make_row(entry, remaining))


func _make_row(entry: Dictionary, remaining: int) -> Control:
	var item_id := str(entry.get("id", ""))
	var it := ShopCatalog.get_item(item_id)
	var price := ShopCatalog.entry_price(entry)
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

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_l := Label.new()
	name_l.text = str(it.get("name", item_id))
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_color", UITheme.CREAM)
	info.add_child(name_l)

	var desc := Label.new()
	desc.text = str(it.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", UITheme.STEAM)
	info.add_child(desc)

	var meta := VBoxContainer.new()
	meta.custom_minimum_size.x = 110
	h.add_child(meta)

	var price_l := Label.new()
	price_l.text = "%d gears" % price
	price_l.add_theme_font_size_override("font_size", 14)
	price_l.add_theme_color_override("font_color", UITheme.LAMP)
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(price_l)

	var stock_l := Label.new()
	if remaining < 0:
		stock_l.text = "Stock ∞"
	else:
		stock_l.text = "Stock %d" % remaining
	stock_l.add_theme_font_size_override("font_size", 11)
	stock_l.add_theme_color_override("font_color", UITheme.STEAM)
	stock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(stock_l)

	var buy := Button.new()
	buy.text = "Buy"
	buy.custom_minimum_size = Vector2(88, 36)
	h.add_child(buy)

	var owned := ShopCatalog.owns_ability(item_id)
	var sold_out := remaining == 0
	var can_afford := GameState.currency >= price
	if owned:
		buy.text = "Owned"
		buy.disabled = true
	elif sold_out:
		buy.text = "Sold"
		buy.disabled = true
	elif not can_afford:
		buy.disabled = true
	else:
		buy.pressed.connect(_on_buy.bind(item_id, remaining, price))
	return row


func _on_buy(item_id: String, remaining: int, price: int = -1) -> void:
	if _busy:
		return
	var it := ShopCatalog.get_item(item_id)
	if it.is_empty():
		return
	if ShopCatalog.owns_ability(item_id):
		status_label.text = "Already owned."
		return
	if remaining == 0:
		status_label.text = "Sold out."
		return
	if price < 0:
		price = ShopCatalog.price(item_id)
		for entry in _entries:
			if str(entry.get("id", "")) == item_id:
				price = ShopCatalog.entry_price(entry)
				break
	if not GameState.spend_currency(price):
		status_label.text = "Not enough silver gears."
		_refresh_gears()
		return
	if not ShopCatalog.apply_purchase(item_id):
		GameState.add_currency(price)
		status_label.text = "Can't buy that."
		_refresh_gears()
		return
	if remaining > 0:
		GameState.set_shop_stock(_shop_key, item_id, remaining - 1)
	AudioManager.play_currency()
	var bought_name := str(it.get("name", item_id))
	if str(it.get("kind", "")) == "consumable":
		status_label.text = "Bought %s — press B to use from Inventory." % bought_name
	else:
		status_label.text = "Bought %s." % bought_name
	SaveManager.autosave()
	_refresh_gears()
	_refresh_list()
