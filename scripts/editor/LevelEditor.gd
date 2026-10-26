extends Control
## Level editor: fixed left toolbar, world SubViewport, bottom scrub for long levels.


enum Tool { SELECT, MOVE, RESIZE, ROTATE, DELETE }
enum EditMode { PIECES, BACKGROUND }

const PANEL_W := 320.0
const BOTTOM_H := 44.0
const OVERSCROLL := 960.0 ## How far past the rightmost piece you can pan to keep building.
const MIN_WORLD_RIGHT := 1600.0
const MIN_WORLD_BOTTOM := 900.0
const CAM_Y := 360.0 ## Default Y for short horizontal zones.
const SNAP_DIST := 12.0
const HISTORY_MAX := 80


var zone_id: String = "cursed_cottage"
var tool: Tool = Tool.SELECT
var edit_mode: EditMode = EditMode.PIECES
var snap_enabled: bool = true
var _palette_id: String = "floor"
## Normalized kind for Add (prop_backdrop_1 → prop_backdrop + style).
var _palette_style: int = 0
var _pieces: Array[EditorPiece] = []
var _removed_ids: Array = []
## Primary selection (inspector focus). `_selection` holds all selected pieces.
var _selected: EditorPiece = null
var _selection: Array[EditorPiece] = []
## Piece → start position while group-dragging under Move.
var _group_drag_starts: Dictionary = {}
var _backdrop: Dictionary = {}
var _sky: BlackFireSky = null
var _world: Node2D
var _cam: Camera2D
var _bg: Polygon2D
var _viewport: SubViewport
var _vp_container: SubViewportContainer
var _piece_list: ItemList
var _name_edit: LineEdit
var _radius_spin: SpinBox
var _radius_row: HBoxContainer
var _intensity_spin: SpinBox
var _intensity_row: HBoxContainer
var _kind_row: HBoxContainer
var _kind_option: OptionButton
var _dialogue_row: VBoxContainer
var _dialogue_edit: TextEdit
var _shop_row: VBoxContainer
var _shopkeeper_check: CheckButton
var _shop_list: VBoxContainer
var _syncing_shop: bool = false
var _link_row: VBoxContainer
var _link_list: ItemList
var _starts_on_check: CheckButton
var _syncing_switch: bool = false
var _syncing_links: bool = false
var _creature_row: VBoxContainer
var _creature_option: OptionButton
var _damage_spin: SpinBox
var _hp_spin: SpinBox
var _syncing_creature: bool = false
var _platform_row: VBoxContainer
var _plat_amp: SpinBox
var _plat_speed: SpinBox
var _plat_path_y: SpinBox
var _plat_rot_speed: SpinBox
var _plat_vertical: CheckButton
var _plat_rotate: CheckButton
var _plat_rotate_body: CheckButton
var _syncing_platform: bool = false
var _color_row: VBoxContainer
var _color_picker: ColorPickerButton
var _color_hex: LineEdit
var _syncing_color: bool = false
var _text_row: VBoxContainer
var _text_edit: TextEdit
var _font_size_spin: SpinBox
var _syncing_text: bool = false
var _link_zone_row: VBoxContainer
var _target_zone_option: OptionButton
var _spawn_x_spin: SpinBox
var _spawn_y_spin: SpinBox
var _caption_edit: LineEdit
var _syncing_zone_link: bool = false
var _backdrop_style_row: VBoxContainer
var _backdrop_style_option: OptionButton
var _syncing_backdrop_style: bool = false
var _blocks_light_btn: CheckButton
var _layer_label: Label
var _status: Label
var _tool_label: Label
var _zone_option: OptionButton
var _mode_pieces_btn: Button
var _mode_bg_btn: Button
var _pieces_block: VBoxContainer
var _backdrop_block: VBoxContainer
var _bg_enabled: CheckButton
var _bg_offset_spin: SpinBox
var _bg_count_spin: SpinBox
var _bg_r: SpinBox
var _bg_g: SpinBox
var _bg_b: SpinBox
var _syncing_backdrop: bool = false
var _scrub: HScrollBar
var _scrub_label: Label
var _extent_label: Label
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO
var _rotating: bool = false
var _rotate_start_angle: float = 0.0
var _rotate_piece_start: float = 0.0
var _syncing_list: bool = false
var _syncing_scrub: bool = false
var _syncing_dialogue: bool = false
var _syncing_light: bool = false
var _world_right: float = MIN_WORLD_RIGHT
var _world_top: float = -80.0
var _world_bottom: float = MIN_WORLD_BOTTOM
## Undo / redo: snapshots of zone JSON + selected piece id.
var _undo_stack: Array = []
var _redo_stack: Array = []
var _history_restoring: bool = false
var _undo_btn: Button
var _redo_btn: Button
var _gesture_snap: Dictionary = {}
var _gesture_active: bool = false
## Collapse rapid inspector spinbox tweaks into one undo step.
var _coalesce_inspector: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_layout()
	_load_zone()


func _build_layout() -> void:
	## Full-screen world; left panel + bottom scrub are screen-locked overlays.
	_vp_container = SubViewportContainer.new()
	_vp_container.name = "WorldView"
	_vp_container.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_vp_container.offset_left = PANEL_W
	_vp_container.offset_bottom = -BOTTOM_H
	_vp_container.stretch = true
	_vp_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_vp_container.gui_input.connect(_on_vp_gui_input)
	add_child(_vp_container)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(960, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = true
	_viewport.physics_object_picking = true
	_vp_container.add_child(_viewport)

	_world = Node2D.new()
	_world.name = "World"
	_viewport.add_child(_world)

	_bg = Polygon2D.new()
	_bg.z_index = -100
	_bg.color = Color(0.05, 0.045, 0.06)
	_world.add_child(_bg)

	_cam = Camera2D.new()
	_cam.position = Vector2(700, CAM_Y)
	_world.add_child(_cam)
	_cam.make_current()

	_build_left_panel()
	_build_bottom_scrub()
	_rebuild_bg()


func _build_left_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "LeftPanel"
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 0
	panel.offset_right = PANEL_W
	panel.offset_top = 0
	panel.offset_bottom = -BOTTOM_H
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 20
	add_child(panel)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 10)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)
	_build_sidebar(col)


func _build_bottom_scrub() -> void:
	var bar := PanelContainer.new()
	bar.name = "BottomScrub"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -BOTTOM_H
	bar.offset_bottom = 0
	bar.offset_left = 0
	bar.offset_right = 0
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.z_index = 20
	add_child(bar)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	_scrub_label = Label.new()
	_scrub_label.text = "Scroll"
	_scrub_label.custom_minimum_size.x = 56
	row.add_child(_scrub_label)

	_scrub = HScrollBar.new()
	_scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scrub.custom_minimum_size = Vector2(0, 18)
	_scrub.min_value = 0
	_scrub.max_value = MIN_WORLD_RIGHT + OVERSCROLL
	_scrub.page = 640
	_scrub.value = 0
	_scrub.value_changed.connect(_on_scrub_changed)
	row.add_child(_scrub)

	_extent_label = Label.new()
	_extent_label.name = "ExtentLabel"
	_extent_label.text = "0"
	_extent_label.custom_minimum_size.x = 72
	_extent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_extent_label)


func _build_sidebar(col: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Level Editor"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	var zone_row := HBoxContainer.new()
	col.add_child(zone_row)
	zone_row.add_child(_lbl("Zone"))
	_zone_option = OptionButton.new()
	_zone_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rebuild_zone_option()
	_zone_option.item_selected.connect(func(i: int) -> void:
		zone_id = _zone_option.get_item_text(i)
		_load_zone()
	)
	zone_row.add_child(_zone_option)

	var mode_row := HBoxContainer.new()
	col.add_child(mode_row)
	mode_row.add_child(_lbl("Mode"))
	_mode_pieces_btn = Button.new()
	_mode_pieces_btn.text = "Pieces"
	_mode_pieces_btn.toggle_mode = true
	_mode_pieces_btn.button_pressed = true
	_mode_pieces_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_pieces_btn.pressed.connect(func() -> void: _set_edit_mode(EditMode.PIECES))
	mode_row.add_child(_mode_pieces_btn)
	_mode_bg_btn = Button.new()
	_mode_bg_btn.text = "Background"
	_mode_bg_btn.toggle_mode = true
	_mode_bg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_bg_btn.pressed.connect(func() -> void: _set_edit_mode(EditMode.BACKGROUND))
	mode_row.add_child(_mode_bg_btn)

	_backdrop_block = VBoxContainer.new()
	_backdrop_block.visible = false
	_backdrop_block.add_theme_constant_override("separation", 6)
	col.add_child(_backdrop_block)
	_backdrop_block.add_child(_section("Black-fire sky"))
	_bg_enabled = CheckButton.new()
	_bg_enabled.text = "Enabled"
	_bg_enabled.toggled.connect(func(on: bool) -> void:
		if _syncing_backdrop or _history_restoring:
			return
		_push_undo()
		_backdrop["enabled"] = on
		_backdrop["kind"] = "black_fire" if on else "none"
		_refresh_sky_preview()
		_save()
	)
	_backdrop_block.add_child(_bg_enabled)
	_bg_offset_spin = _bg_spin_row(_backdrop_block, "Flame band Y offset", -40.0, 120.0, 1.0, 12.0, func(v: float) -> void:
		_backdrop["flame_band_offset"] = v
		_refresh_sky_preview()
	)
	_bg_count_spin = _bg_spin_row(_backdrop_block, "Flame count", 8.0, 96.0, 1.0, 48.0, func(v: float) -> void:
		_backdrop["flame_count"] = int(v)
		_refresh_sky_preview()
	)
	_backdrop_block.add_child(_lbl("Void color (purple fill)"))
	var color_row := HBoxContainer.new()
	_backdrop_block.add_child(color_row)
	_bg_r = _bg_color_spin(color_row, "R", func(v: float) -> void: _set_void_channel(0, v))
	_bg_g = _bg_color_spin(color_row, "G", func(v: float) -> void: _set_void_channel(1, v))
	_bg_b = _bg_color_spin(color_row, "B", func(v: float) -> void: _set_void_channel(2, v))
	var tip := Label.new()
	tip.text = "Anim sits at roof + offset. Lower offset = higher on screen. Middle/right-mouse pan to the top."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	_backdrop_block.add_child(tip)

	_pieces_block = VBoxContainer.new()
	_pieces_block.add_theme_constant_override("separation", 8)
	col.add_child(_pieces_block)
	_pieces_block.add_child(_section("Pieces"))
	_piece_list = ItemList.new()
	_piece_list.custom_minimum_size = Vector2(280, 200)
	_piece_list.select_mode = ItemList.SELECT_MULTI
	_piece_list.item_selected.connect(_on_list_selected)
	_pieces_block.add_child(_piece_list)

	var sel_row := HBoxContainer.new()
	_pieces_block.add_child(sel_row)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_submitted.connect(func(t: String) -> void:
		if _selected and _selected.display_name != t:
			_push_undo()
			_selected.display_name = t
			if _selected.catalog_kind == "prop_house" and LevelData.is_editor_house_zone(_selected.target_zone):
				LevelData.rename_editor_house_zone(_selected.target_zone, t)
			_selected._rebuild()
			_selected.set_selected(true)
			_refresh_list()
			_save()
	)
	sel_row.add_child(_name_edit)
	var dup := Button.new()
	dup.text = "Duplicate"
	dup.pressed.connect(_duplicate_selected)
	sel_row.add_child(dup)
	var del := Button.new()
	del.text = "Delete"
	del.pressed.connect(_delete_selected)
	sel_row.add_child(del)

	_radius_row = HBoxContainer.new()
	_radius_row.visible = false
	_pieces_block.add_child(_radius_row)
	_radius_row.add_child(_lbl("Lantern radius"))
	_radius_spin = SpinBox.new()
	_radius_spin.min_value = 40
	_radius_spin.max_value = 900
	_radius_spin.step = 10
	_radius_spin.value = 280
	_radius_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commit_spin_on_enter(_radius_spin)
	_radius_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_light or _history_restoring:
			return
		var any := false
		for p in _selection:
			if p and is_instance_valid(p) and p.kind == EditorPiece.Kind.LIGHT:
				if not any:
					_push_undo_inspector()
					any = true
				p.light_radius = v
				p._rebuild()
				p.set_selected(true)
		if any:
			_refresh_world_extent()
	)
	_radius_row.add_child(_radius_spin)

	_intensity_row = HBoxContainer.new()
	_intensity_row.visible = false
	_pieces_block.add_child(_intensity_row)
	_intensity_row.add_child(_lbl("Light intensity"))
	_intensity_spin = SpinBox.new()
	_intensity_spin.min_value = 0.25
	_intensity_spin.max_value = 3.0
	_intensity_spin.step = 0.05
	_intensity_spin.value = 1.0
	_intensity_spin.tooltip_text = "Wash brightness + shade/HP burn speed (1.0 = normal)"
	_intensity_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commit_spin_on_enter(_intensity_spin)
	_intensity_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_light or _history_restoring:
			return
		var any := false
		for p in _selection:
			if p and is_instance_valid(p) and p.kind == EditorPiece.Kind.LIGHT:
				if not any:
					_push_undo_inspector()
					any = true
				p.light_intensity = v
				p._rebuild()
				p.set_selected(true)
	)
	_intensity_row.add_child(_intensity_spin)

	_kind_row = HBoxContainer.new()
	_kind_row.visible = false
	_pieces_block.add_child(_kind_row)
	_kind_row.add_child(_lbl("Lantern kind"))
	_kind_option = OptionButton.new()
	_kind_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kind_option.tooltip_text = "Moon is safe shade light; Hearth/Candle burn; Crimson is safe red; Sunshaft is harsh"
	for pair in [
		["Hearth", GameState.LightKind.HEARTH],
		["Candle", GameState.LightKind.CANDLE],
		["Moon", GameState.LightKind.MOON],
		["Crimson", GameState.LightKind.CRIMSON],
		["Sunshaft", GameState.LightKind.SUNSHAFT],
	]:
		_kind_option.add_item(str(pair[0]), int(pair[1]))
	_kind_option.item_selected.connect(func(i: int) -> void:
		if _syncing_light or _history_restoring:
			return
		var lights: Array[EditorPiece] = []
		for p in _selection:
			if p and is_instance_valid(p) and p.kind == EditorPiece.Kind.LIGHT:
				lights.append(p)
		if lights.is_empty():
			return
		_push_undo()
		var kid := _kind_option.get_item_id(i)
		for p in lights:
			p.light_kind = kid
			p._rebuild()
			p.set_selected(true)
		_status.text = "Lantern kind: %s%s" % [
			_kind_option.get_item_text(i),
			" (%d)" % lights.size() if lights.size() > 1 else "",
		]
	)
	_kind_row.add_child(_kind_option)

	_dialogue_row = VBoxContainer.new()
	_dialogue_row.visible = false
	_dialogue_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_dialogue_row)
	_dialogue_row.add_child(_lbl("NPC dialogue (one line per entry)"))
	_dialogue_edit = TextEdit.new()
	_dialogue_edit.custom_minimum_size = Vector2(280, 90)
	_dialogue_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_dialogue_edit.placeholder_text = "Line 1\nLine 2\nLine 3"
	_dialogue_edit.text_changed.connect(_on_dialogue_changed)
	_dialogue_row.add_child(_dialogue_edit)
	var dlg_hint := Label.new()
	dlg_hint.text = "Only for non-shop NPCs. Shopkeepers open a buy GUI."
	dlg_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_hint.add_theme_font_size_override("font_size", 11)
	dlg_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_dialogue_row.add_child(dlg_hint)

	_shop_row = VBoxContainer.new()
	_shop_row.visible = false
	_shop_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_shop_row)
	_shop_row.add_child(_section("Shop inventory"))
	_shopkeeper_check = CheckButton.new()
	_shopkeeper_check.text = "Shopkeeper (opens buy GUI)"
	_shopkeeper_check.toggled.connect(_on_shopkeeper_toggled)
	_shop_row.add_child(_shopkeeper_check)
	var shop_hint := Label.new()
	shop_hint.text = "New shopkeepers sell nothing until you tick items. Set stock + price per keeper."
	shop_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_hint.add_theme_font_size_override("font_size", 11)
	shop_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_shop_row.add_child(shop_hint)
	var shop_scroll := ScrollContainer.new()
	shop_scroll.custom_minimum_size = Vector2(280, 260)
	_shop_row.add_child(shop_scroll)
	_shop_list = VBoxContainer.new()
	_shop_list.add_theme_constant_override("separation", 6)
	_shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.add_child(_shop_list)

	_color_row = VBoxContainer.new()
	_color_row.visible = false
	_color_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_color_row)
	_color_row.add_child(_section("Tint color"))
	var color_hint := Label.new()
	color_hint.text = "Color wheel or #hex for floors, walls, platforms, text…"
	color_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	color_hint.add_theme_font_size_override("font_size", 11)
	color_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_color_row.add_child(color_hint)
	var color_bar := HBoxContainer.new()
	color_bar.add_theme_constant_override("separation", 8)
	_color_row.add_child(color_bar)
	_color_picker = ColorPickerButton.new()
	_color_picker.custom_minimum_size = Vector2(48, 28)
	_color_picker.edit_alpha = false
	_color_picker.color_changed.connect(_on_tint_color_changed)
	color_bar.add_child(_color_picker)
	_color_hex = LineEdit.new()
	_color_hex.placeholder_text = "#RRGGBB"
	_color_hex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_color_hex.text_submitted.connect(_on_tint_hex_submitted)
	_color_hex.focus_exited.connect(func() -> void:
		_on_tint_hex_submitted(_color_hex.text)
	)
	color_bar.add_child(_color_hex)

	_text_row = VBoxContainer.new()
	_text_row.visible = false
	_text_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_text_row)
	_text_row.add_child(_section("World text"))
	_text_edit = TextEdit.new()
	_text_edit.custom_minimum_size = Vector2(280, 64)
	_text_edit.placeholder_text = "Label text"
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text_edit.text_changed.connect(_on_label_text_changed)
	_text_row.add_child(_text_edit)
	_font_size_spin = _spin_row(_text_row, "Font size", 8, 72, 1, 14)
	_font_size_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_text or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.font_size = int(v)
		_selected._rebuild()
		_selected.set_selected(true)
	)

	_backdrop_style_row = VBoxContainer.new()
	_backdrop_style_row.visible = false
	_backdrop_style_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_backdrop_style_row)
	_backdrop_style_row.add_child(_section("Backdrop style"))
	_backdrop_style_option = OptionButton.new()
	for pair in [["Brick & copper", 0], ["Teal foundry", 1], ["Riveted bulkhead", 2]]:
		_backdrop_style_option.add_item(str(pair[0]), int(pair[1]))
	_backdrop_style_option.item_selected.connect(func(i: int) -> void:
		if _syncing_backdrop_style or _history_restoring or _selected == null:
			return
		_push_undo()
		_selected.art_style = _backdrop_style_option.get_item_id(i)
		_selected._rebuild()
		_selected.set_selected(true)
	)
	_backdrop_style_row.add_child(_backdrop_style_option)

	_link_zone_row = VBoxContainer.new()
	_link_zone_row.visible = false
	_link_zone_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_link_zone_row)
	_link_zone_row.add_child(_section("Zone link"))
	var zl_hint := Label.new()
	zl_hint.text = "Door / house destination zone and spawn point (build off existing exits)."
	zl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zl_hint.add_theme_font_size_override("font_size", 11)
	zl_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_link_zone_row.add_child(zl_hint)
	_link_zone_row.add_child(_lbl("Target zone"))
	_target_zone_option = OptionButton.new()
	_rebuild_target_zone_option()
	_target_zone_option.item_selected.connect(func(i: int) -> void:
		if _syncing_zone_link or _history_restoring or _selected == null:
			return
		_push_undo()
		var prev := _selected.target_zone
		var next := _target_zone_option.get_item_text(i)
		_selected.target_zone = next
		if _selected.catalog_kind == "prop_house":
			_on_house_target_changed(_selected, prev, next)
		_status.text = "Links to %s." % _selected.target_zone
	)
	_link_zone_row.add_child(_target_zone_option)
	_spawn_x_spin = _spin_row(_link_zone_row, "Spawn X", -500, 5000, 1, 520)
	_spawn_x_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_zone_link or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.spawn_x = v
	)
	_spawn_y_spin = _spin_row(_link_zone_row, "Spawn Y", -500, 5000, 1, 460)
	_spawn_y_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_zone_link or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.spawn_y = v
	)
	_link_zone_row.add_child(_lbl("Fade caption"))
	_caption_edit = LineEdit.new()
	_caption_edit.placeholder_text = "Traveling…"
	_caption_edit.text_changed.connect(func(t: String) -> void:
		if _syncing_zone_link or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.travel_caption = t
	)
	_link_zone_row.add_child(_caption_edit)

	_link_row = VBoxContainer.new()
	_link_row.visible = false
	_link_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_link_row)
	_link_row.add_child(_section("Lever"))
	_starts_on_check = CheckButton.new()
	_starts_on_check.text = "Starts on"
	_starts_on_check.tooltip_text = "On: the lever begins powered. Off: it begins unpowered."
	_starts_on_check.toggled.connect(func(on: bool) -> void:
		if _syncing_switch or _history_restoring or _selected == null:
			return
		_push_undo()
		_selected.starts_on = on
		_status.text = "Lever starts %s" % ("on" if on else "off")
	)
	_link_row.add_child(_starts_on_check)
	_link_row.add_child(_section("Lever links"))
	var link_hint := Label.new()
	link_hint.text = "Select lanterns / doors this lever powers (multi-select)."
	link_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	link_hint.add_theme_font_size_override("font_size", 11)
	link_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_link_row.add_child(link_hint)
	_link_list = ItemList.new()
	_link_list.select_mode = ItemList.SELECT_MULTI
	_link_list.custom_minimum_size = Vector2(280, 120)
	_link_list.multi_selected.connect(func(_idx: int, _selected_now: bool) -> void:
		_on_links_changed()
	)
	_link_list.item_clicked.connect(func(_idx: int, _pos: Vector2, _mouse: int) -> void:
		## ItemList multi_selected fires on keyboard; also sync after click.
		call_deferred("_on_links_changed")
	)
	_link_row.add_child(_link_list)

	_creature_row = VBoxContainer.new()
	_creature_row.visible = false
	_creature_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_creature_row)
	_creature_row.add_child(_section("Creature"))
	_creature_option = OptionButton.new()
	for row in PieceSpecs.CREATURES:
		_creature_option.add_item(str(row.get("label", "Creature")))
		_creature_option.set_item_metadata(_creature_option.item_count - 1, str(row.get("id", "wander")))
	_creature_option.item_selected.connect(func(idx: int) -> void:
		if _syncing_creature or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		var kind := str(_creature_option.get_item_metadata(idx))
		_selected.enemy_kind = kind
		_selected.attack_damage = EditorDefaults.damage_for(kind)
		_selected.damage_custom = true
		_selected.max_hp = EditorDefaults.hp_for(kind)
		_selected.hp_custom = true
		_syncing_creature = true
		_damage_spin.value = _selected.attack_damage
		_hp_spin.value = _selected.max_hp
		_syncing_creature = false
		_status.text = "%s deals %d and has %d HP" % [_creature_option.get_item_text(idx), _selected.attack_damage, _selected.max_hp]
	)
	_creature_row.add_child(_creature_option)
	_damage_spin = _spin_row(_creature_row, "Damage", 0, 200, 1, 10)
	_damage_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_creature or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.attack_damage = int(v)
		_selected.damage_custom = true
	)
	var make_default := Button.new()
	make_default.text = "Make default"
	make_default.tooltip_text = "Creatures you add after this use this damage. Ones already placed stay as they are."
	make_default.pressed.connect(_on_make_damage_default)
	_creature_row.add_child(make_default)
	_hp_spin = _spin_row(_creature_row, "HP", 1, 9999, 1, 24)
	_hp_spin.value_changed.connect(func(v: float) -> void:
		if _syncing_creature or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.max_hp = int(v)
		_selected.hp_custom = true
	)
	var make_hp := Button.new()
	make_hp.text = "Make default"
	make_hp.tooltip_text = "Creatures you add after this use this HP. Ones already placed stay as they are."
	make_hp.pressed.connect(_on_make_hp_default)
	_creature_row.add_child(make_hp)
	var creature_hint := Label.new()
	creature_hint.text = "Each Make default applies only to creatures added afterward. Already placed creatures keep their own damage and HP."
	creature_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	creature_hint.add_theme_font_size_override("font_size", 11)
	creature_hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	_creature_row.add_child(creature_hint)

	_platform_row = VBoxContainer.new()
	_platform_row.visible = false
	_platform_row.add_theme_constant_override("separation", 4)
	_pieces_block.add_child(_platform_row)
	_platform_row.add_child(_section("Moving platform path"))
	var plat_hint := Label.new()
	plat_hint.text = "Select a moving platform to edit travel distance, path, and spin."
	plat_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plat_hint.add_theme_font_size_override("font_size", 12)
	plat_hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.58))
	_platform_row.add_child(plat_hint)
	_plat_amp = _spin_row(_platform_row, "Path distance", 10, 400, 5, 90)
	_plat_amp.value_changed.connect(func(v: float) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.move_amplitude = v
		_selected.queue_redraw()
	)
	_plat_speed = _spin_row(_platform_row, "Move speed", 0.05, 4.0, 0.05, 0.65)
	_plat_speed.value_changed.connect(func(v: float) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.move_speed = v
	)
	_plat_path_y = _spin_row(_platform_row, "Side path (wobble)", 0, 200, 5, 0)
	_plat_path_y.value_changed.connect(func(v: float) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.path_y_amplitude = v
		_selected.queue_redraw()
	)
	_plat_rot_speed = _spin_row(_platform_row, "Rotate speed", 0, 4.0, 0.05, 1.0)
	_plat_rot_speed.value_changed.connect(func(v: float) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo_inspector()
		_selected.rotate_speed = v
	)
	_plat_vertical = CheckButton.new()
	_plat_vertical.text = "Vertical path (else horizontal)"
	_plat_vertical.toggled.connect(func(on: bool) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo()
		_selected.move_vertical = on
		_selected.queue_redraw()
	)
	_platform_row.add_child(_plat_vertical)
	_plat_rotate = CheckButton.new()
	_plat_rotate.text = "Rotate gear while moving"
	_plat_rotate.toggled.connect(func(on: bool) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo()
		_selected.rotate_while_moving = on
	)
	_platform_row.add_child(_plat_rotate)
	_plat_rotate_body = CheckButton.new()
	_plat_rotate_body.text = "Rotate platform body"
	_plat_rotate_body.toggled.connect(func(on: bool) -> void:
		if _syncing_platform or _history_restoring or _selected == null:
			return
		_push_undo()
		_selected.rotate_platform = on
	)
	_platform_row.add_child(_plat_rotate_body)

	_pieces_block.add_child(_section("Light & layer"))
	_blocks_light_btn = CheckButton.new()
	_blocks_light_btn.text = "Blocks light"
	_blocks_light_btn.tooltip_text = "Occludes lantern washes without solid player collision (layer 128)"
	_blocks_light_btn.disabled = true
	_blocks_light_btn.toggled.connect(func(on: bool) -> void:
		if _history_restoring or _selection.is_empty():
			return
		_push_undo()
		for p in _selection:
			if p and is_instance_valid(p):
				p.blocks_light = on
		_status.text = "Blocks light: %s%s" % [
			"ON" if on else "OFF",
			" (%d)" % _selection.size() if _selection.size() > 1 else "",
		]
	)
	_pieces_block.add_child(_blocks_light_btn)

	var layer_row := HBoxContainer.new()
	layer_row.add_theme_constant_override("separation", 6)
	_pieces_block.add_child(layer_row)
	var layer_down := Button.new()
	layer_down.text = "Layer −"
	layer_down.tooltip_text = "Move selected piece(s) one draw layer down (behind)"
	layer_down.pressed.connect(func() -> void:
		if _selection.is_empty():
			return
		_push_undo()
		for p in _selection:
			if p and is_instance_valid(p):
				p.set_draw_layer(p.draw_layer - 1)
		_update_inspector()
	)
	layer_row.add_child(layer_down)
	var layer_up := Button.new()
	layer_up.text = "Layer +"
	layer_up.tooltip_text = "Move selected piece(s) one draw layer up (in front)"
	layer_up.pressed.connect(func() -> void:
		if _selection.is_empty():
			return
		_push_undo()
		for p in _selection:
			if p and is_instance_valid(p):
				p.set_draw_layer(p.draw_layer + 1)
		_update_inspector()
	)
	layer_row.add_child(layer_up)
	_layer_label = Label.new()
	_layer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_layer_label.text = "Piece: —  |  Player: %d" % PieceSpecs.PLAYER_DRAW_LAYER
	_pieces_block.add_child(_layer_label)

	col.add_child(_section("Tools"))
	var tools := HBoxContainer.new()
	col.add_child(tools)
	for pair in [
		["Select", Tool.SELECT], ["Move", Tool.MOVE], ["Resize", Tool.RESIZE],
		["Rotate", Tool.ROTATE], ["Delete", Tool.DELETE]
	]:
		var b := Button.new()
		b.text = pair[0]
		var t: Tool = pair[1]
		b.pressed.connect(func() -> void:
			tool = t
			_tool_label.text = "Tool: %s" % pair[0]
			_sync_move_arrows()
			_sync_resize_edges()
		)
		tools.add_child(b)
	_tool_label = Label.new()
	_tool_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tool_label.text = "Tool: Select — Ctrl/Cmd+click multi-select · top layer wins · Resize shows N/E/S/W edges"
	col.add_child(_tool_label)

	var hist := HBoxContainer.new()
	hist.add_theme_constant_override("separation", 8)
	col.add_child(hist)
	_undo_btn = Button.new()
	_undo_btn.text = "Undo"
	_undo_btn.tooltip_text = "Undo (Ctrl+Z)"
	_undo_btn.disabled = true
	_undo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_undo_btn.pressed.connect(_undo)
	hist.add_child(_undo_btn)
	_redo_btn = Button.new()
	_redo_btn.text = "Redo"
	_redo_btn.tooltip_text = "Redo (Ctrl+Y / Ctrl+Shift+Z)"
	_redo_btn.disabled = true
	_redo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_redo_btn.pressed.connect(_redo)
	hist.add_child(_redo_btn)

	var snap_btn := CheckButton.new()
	snap_btn.text = "Snap to edges"
	snap_btn.button_pressed = snap_enabled
	snap_btn.tooltip_text = "While moving, snap this piece's edges to nearby pieces"
	snap_btn.toggled.connect(func(on: bool) -> void:
		snap_enabled = on
		_status.text = "Snap %s." % ("ON" if on else "OFF")
	)
	col.add_child(snap_btn)

	_pieces_block.add_child(_section("Add"))
	_pieces_block.add_child(_build_add_palette())
	var add_btn := Button.new()
	add_btn.text = "Add selected piece"
	add_btn.pressed.connect(_add_piece)
	_pieces_block.add_child(add_btn)

	var save_btn := Button.new()
	save_btn.text = "Save (this session)"
	save_btn.tooltip_text = "Keeps edits for playtest in this tab only. Refreshing the page discards them — use Copy Save Code to keep work."
	save_btn.pressed.connect(_save)
	col.add_child(save_btn)

	var export_btn := Button.new()
	export_btn.text = "Copy Save Code"
	export_btn.tooltip_text = "Opens JSON you can paste to an AI or commit into data/levels/"
	export_btn.pressed.connect(_show_export_dialog)
	col.add_child(export_btn)

	var import_btn := Button.new()
	import_btn.text = "Import Save Code"
	import_btn.tooltip_text = "Paste level JSON to load it into this editor"
	import_btn.pressed.connect(_show_import_dialog)
	col.add_child(import_btn)

	var play_btn := Button.new()
	play_btn.text = "Playtest Zone"
	play_btn.pressed.connect(_playtest)
	col.add_child(play_btn)
	var back := Button.new()
	back.text = "Back to Title"
	back.pressed.connect(func() -> void:
		GameState.editor_playtesting = false
		get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
	)
	col.add_child(back)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(280, 90)
	_status.text = "Use Copy Save Code to share levels. Docs: docs/LEVEL_EDITOR.md"
	col.add_child(_status)


func _light_kind_label(kind: int) -> String:
	match kind:
		GameState.LightKind.CANDLE:
			return "candle"
		GameState.LightKind.MOON:
			return "moon"
		GameState.LightKind.CRIMSON:
			return "crimson"
		GameState.LightKind.SUNSHAFT:
			return "sun"
		_:
			return "hearth"


func _lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _bg_spin_row(parent: Control, label: String, mn: float, mx: float, step: float, val: float, on_change: Callable) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(_lbl(label))
	var spin := SpinBox.new()
	spin.min_value = mn
	spin.max_value = mx
	spin.step = step
	spin.value = val
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commit_spin_on_enter(spin)
	spin.value_changed.connect(func(v: float) -> void:
		if _syncing_backdrop or _history_restoring:
			return
		_push_undo_inspector()
		on_change.call(v)
		_save()
	)
	row.add_child(spin)
	return spin


func _bg_color_spin(parent: Control, label: String, on_change: Callable) -> SpinBox:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	box.add_child(_lbl(label))
	var spin := SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = 1.0
	spin.step = 0.01
	spin.value = 0.1
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commit_spin_on_enter(spin)
	spin.value_changed.connect(func(v: float) -> void:
		if _syncing_backdrop or _history_restoring:
			return
		_push_undo_inspector()
		on_change.call(v)
		_refresh_sky_preview()
		_save()
	)
	box.add_child(spin)
	return spin


func _set_void_channel(idx: int, v: float) -> void:
	var raw: Variant = _backdrop.get("void_color", LevelData.VOID_PURPLE)
	var arr: Array = []
	if raw is Array:
		arr = (raw as Array).duplicate()
	else:
		arr = LevelData.VOID_PURPLE.duplicate()
	while arr.size() < 4:
		arr.append(1.0 if arr.size() == 3 else 0.0)
	arr[idx] = v
	_backdrop["void_color"] = arr


func _set_edit_mode(mode: EditMode) -> void:
	edit_mode = mode
	if _mode_pieces_btn:
		_mode_pieces_btn.button_pressed = mode == EditMode.PIECES
	if _mode_bg_btn:
		_mode_bg_btn.button_pressed = mode == EditMode.BACKGROUND
	if _pieces_block:
		_pieces_block.visible = mode == EditMode.PIECES
	if _backdrop_block:
		_backdrop_block.visible = mode == EditMode.BACKGROUND
	if mode == EditMode.BACKGROUND:
		_select(null)
		_sync_backdrop_inspector()
		_refresh_sky_preview()
		## Frame the top fire band.
		var roof := _zone_roof_top()
		var offset := float(_backdrop.get("flame_band_offset", 18.0))
		_cam.position = Vector2(_cam.position.x, roof + offset + 40.0)
		_clamp_camera()
		_status.text = "Background mode — edit purple fill + top fire fringe."
	else:
		_status.text = "Pieces mode."
	for p in _pieces:
		if is_instance_valid(p):
			p.modulate.a = 0.35 if mode == EditMode.BACKGROUND else 1.0


func _zone_roof_top() -> float:
	match zone_id:
		"lantern_village":
			return 160.0
		"clockwork_tower":
			return 20.0
		"house_keep", "house_gear", "house_inn":
			return 160.0
		_:
			return 180.0


func _zone_map_width() -> float:
	match zone_id:
		"lantern_village":
			return 3200.0
		"clockwork_tower":
			return 1100.0
		"house_keep", "house_gear", "house_inn":
			return 720.0
		_:
			return 4000.0


func _sync_backdrop_inspector() -> void:
	if _bg_enabled == null:
		return
	_syncing_backdrop = true
	var enabled := bool(_backdrop.get("enabled", _backdrop.get("kind", "") == "black_fire"))
	_bg_enabled.button_pressed = enabled
	_bg_offset_spin.value = float(_backdrop.get("flame_band_offset", 18.0))
	_bg_count_spin.value = float(_backdrop.get("flame_count", 48))
	var raw: Variant = _backdrop.get("void_color", LevelData.VOID_PURPLE)
	var arr: Array = raw if raw is Array else LevelData.VOID_PURPLE.duplicate()
	_bg_r.value = float(arr[0]) if arr.size() > 0 else float(LevelData.VOID_PURPLE[0])
	_bg_g.value = float(arr[1]) if arr.size() > 1 else float(LevelData.VOID_PURPLE[1])
	_bg_b.value = float(arr[2]) if arr.size() > 2 else float(LevelData.VOID_PURPLE[2])
	_syncing_backdrop = false


func _refresh_sky_preview() -> void:
	if _world == null:
		return
	var enabled := bool(_backdrop.get("enabled", false)) and str(_backdrop.get("kind", "none")) != "none"
	if not enabled:
		if _sky and is_instance_valid(_sky):
			_sky.queue_free()
			_sky = null
		if _bg:
			_bg.color = Color(0.05, 0.045, 0.06)
		return
	var floor_top := PieceSpecs.floor_top_for_zone(zone_id)
	var roof := _zone_roof_top()
	var width := maxf(_zone_map_width(), _world_right + 200.0)
	if _sky == null or not is_instance_valid(_sky):
		_sky = BlackFireSky.new()
		_sky.name = "EditorBlackFireSky"
		_world.add_child(_sky)
		_world.move_child(_sky, 0 if _bg == null else 1)
	_sky.setup(width, floor_top, roof, _backdrop)
	if _bg:
		var vc := BlackFireSky._color_from(_backdrop.get("void_color", null), BlackFireSky.DEFAULT_VOID)
		_bg.color = vc


## Add palette: [tab title, [[kind, label], ...]]. Every kind LevelData can spawn.
const ADD_CATEGORIES := [
	["Terrain", [
		["floor", "Steel floor"],
		["block", "Block"],
		["wall", "Wall"],
		["prop_platform", "Moving platform"],
		["prop_ladder", "Ladder"],
		["prop_pipe", "Pipe / rail"],
	]],
	["Lights", [
		["light", "Lantern"],
		["prop_switch", "Lever"],
	]],
	["Doors", [
		["prop_door", "Door (switchable)"],
		["prop_exit", "Zone door"],
		["prop_hatch", "Hatch"],
		["prop_house", "House facade"],
		["prop_tower", "Clockwork tower"],
	]],
	["Props", [
		["crate", "Pushable crate"],
		["prop_crate", "Decor crate"],
		["prop_bench", "Bench"],
		["prop_vent", "Steam vent"],
		["prop_desk", "Desk"],
		["prop_valve", "Valve"],
		["prop_breakable", "Glowing jar"],
		["prop_checkpoint", "Rest hearth"],
	]],
	["Scenery", [
		["background", "Brick wall mural"],
		["prop_backdrop", "Brick & copper"],
		["prop_backdrop_1", "Teal foundry"],
		["prop_backdrop_2", "Riveted bulkhead"],
		["prop_bg_gear", "Background gear"],
		["prop_window", "Window"],
		["prop_text", "Text label"],
	]],
	["Actors", [
		["prop_npc", "NPC / Shopkeeper"],
		["prop_enemy", "Enemy"],
		["prop_pickup", "Shadow crystal"],
	]],
]


## Category tabs of picture buttons; picking one sets the kind "Add selected piece" creates.
func _build_add_palette() -> Control:
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Compact labels so Terrain/Lights/Doors/Props/Scenery/Actors fit.
	tabs.add_theme_font_size_override("font_size", 11)
	for sb_name in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var sb := tabs.get_theme_stylebox(sb_name).duplicate() as StyleBox
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		tabs.add_theme_stylebox_override(sb_name, sb)
	var group := ButtonGroup.new()
	for cat in ADD_CATEGORIES:
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 2)
		tabs.add_child(list)
		tabs.set_tab_title(tabs.get_tab_count() - 1, str(cat[0]))
		for item in cat[1]:
			var kind: String = item[0]
			var b := Button.new()
			b.toggle_mode = true
			b.button_group = group
			b.text = str(item[1])
			b.icon = _palette_preview(kind)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(0, 46)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.button_pressed = kind == _palette_id
			b.toggled.connect(func(on: bool) -> void:
				if on:
					_set_palette(kind)
			)
			list.add_child(b)
	return tabs


func _set_palette(kind: String) -> void:
	_palette_id = kind
	_palette_style = 0
	if kind.begins_with("prop_backdrop"):
		_palette_id = "prop_backdrop"
		if kind == "prop_backdrop_1":
			_palette_style = 1
		elif kind == "prop_backdrop_2":
			_palette_style = 2
		else:
			_palette_style = 0


## Small live render of a piece's in-game art for the Add palette.
func _palette_preview(kind: String) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(48, 40)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var holder := Node2D.new()
	holder.position = Vector2(24, 20)
	vp.add_child(holder)
	var art := WorldArt.new()
	var scale := 1.0
	var offset := Vector2.ZERO
	match kind:
		"floor", "block", "prop_platform":
			art.kind = WorldArt.Kind.PLATFORM
			art.style = LevelCommon.platform_style
			art.size = Vector2(100, 18)
			scale = 0.42
		"wall":
			art.kind = WorldArt.Kind.BACKDROP
			art.size = Vector2(26, 36)
			offset = Vector2(0, 18)
		"prop_door":
			art = null
			holder.add_child(_preview_poly([Vector2(-10, 17), Vector2(10, 17), Vector2(10, -17), Vector2(-10, -17)], Color(0.14, 0.13, 0.12)))
			holder.add_child(_preview_poly([Vector2(-7, 17), Vector2(7, 17), Vector2(7, -14), Vector2(-7, -14)], Color(0.24, 0.16, 0.09)))
		"light":
			art.kind = WorldArt.Kind.LANTERN
			scale = 0.85
			offset = Vector2(0, 2)
		"prop_switch":
			art.kind = WorldArt.Kind.LEVER
			art.style = 1
			scale = 1.2
			offset = Vector2(0, 8)
		"crate":
			art.kind = WorldArt.Kind.CRATE
			art.style = 7
			art.size = Vector2(58, 58)
			scale = 0.55
		"prop_crate":
			art.kind = WorldArt.Kind.CRATE
			art.style = 9
			art.size = Vector2(40, 30)
			scale = 0.8
		"prop_bench":
			art.kind = WorldArt.Kind.BENCH
			art.style = 5
			scale = 0.65
			offset = Vector2(0, 12)
		"prop_vent":
			art.kind = WorldArt.Kind.VENT
			art.style = 1
			art.steam_preview = true
			scale = 0.9
			offset = Vector2(0, 14)
		"prop_ladder":
			art = null
			for rx in [-8.0, 8.0]:
				holder.add_child(_preview_poly([Vector2(rx - 1.5, 18), Vector2(rx + 1.5, 18), Vector2(rx + 1.5, -18), Vector2(rx - 1.5, -18)], Color(0.48, 0.34, 0.2)))
			for k in 5:
				var ry := -14.0 + k * 7.0
				holder.add_child(_preview_poly([Vector2(-8, ry - 1), Vector2(8, ry - 1), Vector2(8, ry + 1), Vector2(-8, ry + 1)], Color(0.6, 0.44, 0.27)))
		"prop_desk":
			art = null
			holder.add_child(_preview_poly([Vector2(-20, 4), Vector2(20, 4), Vector2(20, -4), Vector2(-20, -4)], Color(0.36, 0.25, 0.15)))
			holder.add_child(_preview_poly([Vector2(-18, 14), Vector2(18, 14), Vector2(18, 4), Vector2(-18, 4)], Color(0.22, 0.16, 0.12)))
		"prop_window":
			art.kind = WorldArt.Kind.WINDOW
			art.style = 10
			art.size = Vector2(44, 60)
			scale = 0.5
		"background":
			art = null
			holder.add_child(_preview_poly([Vector2(-20, -14), Vector2(20, -14), Vector2(20, 14), Vector2(-20, 14)], Color(0.28, 0.18, 0.14)))
			holder.add_child(_preview_poly([Vector2(-18, -6), Vector2(-2, -6), Vector2(-2, 0), Vector2(-18, 0)], Color(0.35, 0.22, 0.18)))
			holder.add_child(_preview_poly([Vector2(-1, -6), Vector2(18, -6), Vector2(18, 0), Vector2(-1, 0)], Color(0.32, 0.2, 0.16)))
		"prop_backdrop", "prop_backdrop_1", "prop_backdrop_2":
			art.kind = WorldArt.Kind.BACKDROP
			art.style = 1 if kind == "prop_backdrop_1" else (2 if kind == "prop_backdrop_2" else 0)
			art.size = Vector2(90, 50)
			scale = 0.42
			offset = Vector2(0, 18)
		"prop_valve":
			art.kind = WorldArt.Kind.VALVE
			art.style = 5
			scale = 0.9
		"prop_bg_gear":
			art = null
			var pts: Array = []
			for i in 24:
				var a := TAU * float(i) / 24.0
				pts.append(Vector2(cos(a), sin(a)) * (14.0 if i % 2 == 0 else 17.0))
			holder.add_child(_preview_poly(pts, Color(0.23, 0.18, 0.13)))
		"prop_checkpoint":
			art.kind = WorldArt.Kind.CHECKPOINT
			art.style = 6
			art.on = true
			scale = 0.45
			offset = Vector2(0, 16)
		"prop_npc":
			art.kind = WorldArt.Kind.NPC
			art.style = 0
			scale = 0.55
			offset = Vector2(0, 18)
		"prop_pickup":
			art = null
			holder.add_child(_preview_poly([Vector2(0, -15), Vector2(9, 0), Vector2(0, 15), Vector2(-9, 0)], Color(0.55, 0.4, 0.85)))
		"prop_text":
			art = null
			holder.add_child(_preview_poly([Vector2(-18, -8), Vector2(18, -8), Vector2(18, 8), Vector2(-18, 8)], Color(0.18, 0.15, 0.12, 0.7)))
	if art:
		art.position = offset
		art.scale = Vector2.ONE * scale
		holder.add_child(art)
	return vp.get_texture()


func _preview_poly(pts: Array, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array(pts)
	poly.color = col
	return poly


func _section(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	return l


## Typed numbers stay draft text until Enter. Clicking away restores the spin
## so a focus loss cannot write the previous field onto the next piece.
func _commit_spin_on_enter(spin: SpinBox) -> void:
	var le := spin.get_line_edit()
	for conn in le.focus_exited.get_connections():
		le.focus_exited.disconnect(conn["callable"])
	le.focus_exited.connect(func() -> void:
		_revert_spin_text(spin)
	, CONNECT_DEFERRED)


func _revert_spin_text(spin: SpinBox) -> void:
	if spin == null or not is_instance_valid(spin):
		return
	var le := spin.get_line_edit()
	if le == null:
		return
	var decimals := 0
	var step_text := String.num(spin.step)
	var dot := step_text.find(".")
	if dot >= 0:
		decimals = step_text.length() - dot - 1
	le.text = String.num(spin.value, decimals)
	le.caret_column = le.text.length()


func _flush_focused_spin_for_playtest() -> void:
	## Playtest is an intentional commit — apply draft LineEdit text on the focused spin.
	var focus := get_viewport().gui_get_focus_owner() if get_viewport() else null
	if focus == null or not (focus is LineEdit):
		return
	var le := focus as LineEdit
	var spin := le.get_parent()
	if spin == null or not (spin is SpinBox):
		return
	var sb := spin as SpinBox
	var raw := le.text.strip_edges()
	if raw.is_valid_float():
		sb.value = clampf(raw.to_float(), sb.min_value, sb.max_value)


func _spin_row(parent: Control, label: String, mn: float, mx: float, step: float, val: float) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(_lbl(label))
	var spin := SpinBox.new()
	spin.min_value = mn
	spin.max_value = mx
	spin.step = step
	spin.value = val
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_commit_spin_on_enter(spin)
	row.add_child(spin)
	return spin


func _piece_right_edge(p: EditorPiece) -> float:
	if p == null or not is_instance_valid(p):
		return 0.0
	match p.kind:
		EditorPiece.Kind.LIGHT:
			return p.position.x + maxf(p.light_radius, 40.0)
		_:
			return p.position.x + maxf(p.size.x, 8.0) * 0.5


func _piece_y_extent(p: EditorPiece) -> Vector2:
	## Returns (top, bottom) world Y for a piece.
	if p == null or not is_instance_valid(p):
		return Vector2(0, 0)
	match p.kind:
		EditorPiece.Kind.LIGHT:
			var r := maxf(p.light_radius, 40.0)
			return Vector2(p.position.y - r, p.position.y + r)
		_:
			var half := maxf(p.size.y, 8.0) * 0.5
			return Vector2(p.position.y - half, p.position.y + half)


func _compute_world_right() -> float:
	var right := MIN_WORLD_RIGHT
	for p in _pieces:
		if is_instance_valid(p):
			right = maxf(right, _piece_right_edge(p))
	return right


func _compute_world_y_bounds() -> void:
	_world_top = -80.0
	_world_bottom = MIN_WORLD_BOTTOM
	for p in _pieces:
		if not is_instance_valid(p):
			continue
		var ext := _piece_y_extent(p)
		_world_top = mini(_world_top, ext.x - 80.0)
		_world_bottom = maxf(_world_bottom, ext.y + 80.0)


func _refresh_world_extent() -> void:
	_world_right = _compute_world_right()
	_compute_world_y_bounds()
	_rebuild_bg()
	_sync_scrub_from_camera(true)


func _rebuild_bg() -> void:
	if _bg == null:
		return
	var right := _world_right + OVERSCROLL + 400.0
	_bg.polygon = PackedVector2Array([
		Vector2(-400, _world_top - 200.0), Vector2(right, _world_top - 200.0),
		Vector2(right, _world_bottom + 200.0), Vector2(-400, _world_bottom + 200.0)
	])


func _view_page_width() -> float:
	## Approximate visible world width behind the camera at current zoom.
	var cont_w := maxf(_vp_container.size.x, 1.0)
	return cont_w / maxf(_cam.zoom.x, 0.05)


func _view_page_height() -> float:
	var cont_h := maxf(_vp_container.size.y, 1.0)
	return cont_h / maxf(_cam.zoom.y, 0.05)


func _default_cam_y() -> float:
	## Tall vertical zones start near the lobby / bottom; short zones use CAM_Y.
	if zone_id == "clockwork_tower":
		return clampf(2400.0, _world_top + 80.0, _world_bottom - 80.0)
	return CAM_Y


func _sync_scrub_from_camera(_force_range: bool = false) -> void:
	if _scrub == null or _cam == null:
		return
	_syncing_scrub = true
	var page := _view_page_width()
	var max_scroll := maxf(_world_right + OVERSCROLL, page + 1.0)
	_scrub.min_value = 0.0
	_scrub.max_value = max_scroll
	_scrub.page = clampf(page, 64.0, max_scroll)
	# Camera X is the center of the view; scrub value is left edge.
	var left := _cam.position.x - page * 0.5
	_scrub.set_value_no_signal(clampf(left, 0.0, maxf(0.0, max_scroll - _scrub.page)))
	if _extent_label:
		_extent_label.text = "%.0f×%.0f" % [_world_right, _world_bottom]
	_scrub_label.text = "x %.0f  y %.0f" % [_cam.position.x, _cam.position.y]
	_syncing_scrub = false


func _on_scrub_changed(value: float) -> void:
	if _syncing_scrub or _cam == null:
		return
	var page := _view_page_width()
	_cam.position.x = value + page * 0.5
	_clamp_camera()
	_scrub_label.text = "x %.0f  y %.0f" % [_cam.position.x, _cam.position.y]


func _clamp_camera() -> void:
	if _cam == null:
		return
	var page_w := _view_page_width()
	var max_left := maxf(0.0, _world_right + OVERSCROLL - page_w)
	var left := clampf(_cam.position.x - page_w * 0.5, 0.0, max_left)
	_cam.position.x = left + page_w * 0.5
	var page_h := _view_page_height()
	var min_cy := _world_top + page_h * 0.5
	var max_cy := maxf(min_cy, _world_bottom - page_h * 0.5)
	_cam.position.y = clampf(_cam.position.y, min_cy, max_cy)
	_sync_scrub_from_camera()


func _clear_pieces() -> void:
	for p in _pieces:
		if is_instance_valid(p):
			p.queue_free()
	_pieces.clear()
	_selected = null
	_selection.clear()
	_group_drag_starts.clear()


func _load_zone() -> void:
	_clear_pieces()
	if _sky and is_instance_valid(_sky):
		_sky.queue_free()
		_sky = null
	var data := LevelData.load_raw(zone_id)
	_removed_ids = data.get("removed_ids", []).duplicate()
	_backdrop = LevelData.backdrop_for(zone_id)
	var overrides := {}
	for raw in data.get("pieces", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var oid := str(raw.get("id", ""))
		if oid != "":
			overrides[oid] = raw
	for cat in ZoneCatalog.pieces_for(zone_id):
		var id := str(cat.get("id", ""))
		if id != "" and _removed_ids.has(id):
			continue
		var merged: Dictionary = cat.duplicate(true)
		if overrides.has(id):
			var ov: Dictionary = overrides[id]
			for key in [
				"x", "y", "w", "h", "name", "radius", "intensity", "light_kind", "pushable", "lines", "anchor",
				"blocks_light", "layer", "target_ids", "starts_on", "starts_open", "rotation",
				"damage", "enemy_kind", "hp",
				"move_amplitude", "move_speed", "vertical", "path_y_amplitude",
				"rotate_while_moving", "rotate_speed", "rotate_platform", "with_gear",
				"is_shopkeeper", "shop_items", "color", "text", "font_size",
				"target_zone", "spawn_x", "spawn_y", "caption", "house_id", "style",
			]:
				if ov.has(key):
					merged[key] = ov[key]
			overrides.erase(id)
		_spawn_piece_dict(merged)
	for id in overrides.keys():
		var raw: Dictionary = overrides[id]
		if bool(raw.get("builtin", false)):
			continue
		_spawn_piece_dict(raw)
	_sync_houses_from_pieces()
	_rebuild_zone_dropdowns()
	_refresh_list()
	_refresh_world_extent()
	_sync_backdrop_inspector()
	_refresh_sky_preview()
	_set_edit_mode(EditMode.PIECES)
	_cam.position = Vector2(700 if zone_id != "clockwork_tower" else 430, _default_cam_y())
	_cam.zoom = Vector2.ONE
	_clamp_camera()
	_clear_history()
	_status.text = "Loaded %s — %d pieces." % [zone_id, _pieces.size()]


func _spawn_piece_dict(d: Dictionary) -> void:
	var piece := EditorPiece.new()
	_world.add_child(piece)
	piece.apply_dict(d)
	if str(d.get("kind", "")) == "light":
		if d.has("radius"):
			piece.light_radius = float(d.get("radius", 280))
		if d.has("intensity"):
			piece.light_intensity = float(d.get("intensity", 1.0))
		piece._rebuild()
	_pieces.append(piece)


func _refresh_list() -> void:
	_syncing_list = true
	_piece_list.clear()
	for i in _pieces.size():
		var p := _pieces[i]
		var extra := ""
		if p.kind == EditorPiece.Kind.LIGHT:
			extra = "  r=%.0f i=%.2f %s" % [p.light_radius, p.light_intensity, _light_kind_label(p.light_kind)]
		_piece_list.add_item("%s [%s]%s" % [p.display_name, p.piece_id, extra])
		if p in _selection:
			_piece_list.select(i, false)
	_syncing_list = false
	_update_inspector()


func _update_inspector() -> void:
	_name_edit.text = _selected.display_name if _selected else ""
	var is_light := _selected != null and _selected.kind == EditorPiece.Kind.LIGHT
	_radius_row.visible = is_light
	_intensity_row.visible = is_light
	_kind_row.visible = is_light
	if is_light:
		_syncing_light = true
		_radius_spin.value = _selected.light_radius
		_intensity_spin.value = _selected.light_intensity
		var lk := clampi(_selected.light_kind, 0, 4)
		var found_kind := false
		for i in _kind_option.item_count:
			if _kind_option.get_item_id(i) == lk:
				_kind_option.select(i)
				found_kind = true
				break
		if not found_kind:
			_kind_option.select(0)
		_syncing_light = false
	var is_npc := _selected != null and _selected.is_npc()
	_shop_row.visible = is_npc
	_syncing_shop = true
	if is_npc:
		_shopkeeper_check.set_pressed_no_signal(_selected.is_shopkeeper)
		_rebuild_shop_list()
	else:
		_shopkeeper_check.set_pressed_no_signal(false)
		for c in _shop_list.get_children():
			c.queue_free()
	_syncing_shop = false
	_dialogue_row.visible = is_npc and not (_selected != null and _selected.is_shopkeeper)
	_syncing_dialogue = true
	if is_npc:
		_dialogue_edit.text = _selected.get_dialogue_text()
	else:
		_dialogue_edit.text = ""
	_syncing_dialogue = false
	var is_switch := _selected != null and PieceSpecs.is_switch_kind(_selected.catalog_kind)
	_link_row.visible = is_switch
	if is_switch:
		_syncing_switch = true
		_starts_on_check.set_pressed_no_signal(_selected.starts_on)
		_syncing_switch = false
		_refresh_link_list()
	var is_enemy := _selected != null and _selected.catalog_kind == "prop_enemy"
	_creature_row.visible = is_enemy
	if is_enemy:
		_syncing_creature = true
		var kind := _selected.enemy_kind if _selected.enemy_kind != "" else "wander"
		for i in _creature_option.item_count:
			if str(_creature_option.get_item_metadata(i)) == kind:
				_creature_option.select(i)
				break
		var shown := _selected.attack_damage if _selected.damage_custom else PieceSpecs.creature_damage(kind)
		_damage_spin.value = shown
		var shown_hp := _selected.max_hp if _selected.hp_custom else PieceSpecs.creature_hp(kind)
		_hp_spin.value = shown_hp
		_syncing_creature = false
	var is_plat := _selected != null and PieceSpecs.is_platform_kind(_selected.catalog_kind)
	_platform_row.visible = is_plat
	if is_plat:
		_syncing_platform = true
		_plat_amp.value = _selected.move_amplitude
		_plat_speed.value = _selected.move_speed
		_plat_path_y.value = _selected.path_y_amplitude
		_plat_rot_speed.value = _selected.rotate_speed
		_plat_vertical.set_pressed_no_signal(_selected.move_vertical)
		_plat_rotate.set_pressed_no_signal(_selected.rotate_while_moving)
		_plat_rotate_body.set_pressed_no_signal(_selected.rotate_platform)
		_syncing_platform = false
	var tintable := _selected != null and PieceSpecs.supports_tint(_selected.catalog_kind)
	_color_row.visible = tintable
	_syncing_color = true
	if tintable:
		_color_picker.color = _selected.tint_color
		_color_hex.text = "#" + _selected.tint_color.to_html(false)
	_syncing_color = false
	var is_text := _selected != null and _selected.catalog_kind == "prop_text"
	_text_row.visible = is_text
	_syncing_text = true
	if is_text:
		_text_edit.text = _selected.label_text
		_font_size_spin.value = _selected.font_size
	else:
		_text_edit.text = ""
	_syncing_text = false
	var is_backdrop := _selected != null and _selected.catalog_kind == "prop_backdrop"
	_backdrop_style_row.visible = is_backdrop
	_syncing_backdrop_style = true
	if is_backdrop:
		var st := clampi(_selected.art_style, 0, 2)
		for i in _backdrop_style_option.item_count:
			if _backdrop_style_option.get_item_id(i) == st:
				_backdrop_style_option.select(i)
				break
	_syncing_backdrop_style = false
	var is_zone_link := _selected != null and _selected.catalog_kind in ["prop_exit", "prop_house", "prop_hatch"]
	_link_zone_row.visible = is_zone_link
	_syncing_zone_link = true
	if is_zone_link:
		var tz := _selected.target_zone
		if tz == "" and _selected.catalog_kind == "prop_house":
			tz = _selected.piece_id
		var found := false
		for i in _target_zone_option.item_count:
			if _target_zone_option.get_item_text(i) == tz:
				_target_zone_option.select(i)
				found = true
				break
		if not found and _target_zone_option.item_count > 0:
			_target_zone_option.select(0)
			tz = _target_zone_option.get_item_text(0)
			_selected.target_zone = tz
		_spawn_x_spin.value = _selected.spawn_x
		_spawn_y_spin.value = _selected.spawn_y
		_caption_edit.text = _selected.travel_caption
	_syncing_zone_link = false
	_blocks_light_btn.disabled = _selected == null
	if _selected:
		_blocks_light_btn.set_pressed_no_signal(_selected.blocks_light)
		var rel := _selected.draw_layer - PieceSpecs.PLAYER_DRAW_LAYER
		var rel_s := ("+%d" % rel) if rel > 0 else str(rel)
		_layer_label.text = "Piece layer: %d (%s vs player)  |  rot %.0f°  |  Player: %d" % [
			_selected.draw_layer, rel_s, _selected.rotation_deg, PieceSpecs.PLAYER_DRAW_LAYER
		]
	else:
		_blocks_light_btn.set_pressed_no_signal(false)
		_layer_label.text = "Piece: —  |  Player layer: %d" % PieceSpecs.PLAYER_DRAW_LAYER


func _refresh_link_list() -> void:
	if _link_list == null or _selected == null:
		return
	_syncing_links = true
	_link_list.clear()
	var linked: Dictionary = {}
	for t in _selected.target_ids:
		linked[str(t)] = true
	for p in _pieces:
		if p == null or not is_instance_valid(p) or p == _selected:
			continue
		if not PieceSpecs.is_linkable_target(p.catalog_kind) and p.kind != EditorPiece.Kind.LIGHT:
			continue
		var label := "%s [%s]" % [p.display_name, p.piece_id]
		_link_list.add_item(label)
		var idx := _link_list.item_count - 1
		_link_list.set_item_metadata(idx, p.piece_id)
		if linked.has(p.piece_id):
			_link_list.select(idx, false)
	_syncing_links = false


func _on_links_changed() -> void:
	if _syncing_links or _history_restoring or _selected == null or not PieceSpecs.is_switch_kind(_selected.catalog_kind):
		return
	_push_undo_inspector()
	var ids := PackedStringArray()
	for idx in _link_list.get_selected_items():
		ids.append(str(_link_list.get_item_metadata(idx)))
	_selected.target_ids = ids
	_status.text = "Lever linked to %d target(s)." % ids.size()


func _on_make_damage_default() -> void:
	if _selected == null or _selected.catalog_kind != "prop_enemy":
		return
	var kind := _selected.enemy_kind if _selected.enemy_kind != "" else "wander"
	var dmg := int(_damage_spin.value)
	EditorDefaults.set_damage(kind, dmg)
	var label := kind
	for i in _creature_option.item_count:
		if str(_creature_option.get_item_metadata(i)) == kind:
			label = _creature_option.get_item_text(i)
			break
	_status.text = "New %s creatures will deal %d. Already placed creatures are unchanged." % [label, dmg]


func _on_make_hp_default() -> void:
	if _selected == null or _selected.catalog_kind != "prop_enemy":
		return
	var kind := _selected.enemy_kind if _selected.enemy_kind != "" else "wander"
	var hp := int(_hp_spin.value)
	EditorDefaults.set_hp(kind, hp)
	var label := kind
	for i in _creature_option.item_count:
		if str(_creature_option.get_item_metadata(i)) == kind:
			label = _creature_option.get_item_text(i)
			break
	_status.text = "New %s creatures will have %d HP. Already placed creatures are unchanged." % [label, hp]


func _on_dialogue_changed() -> void:
	if _syncing_dialogue or _history_restoring or _selected == null or not _selected.is_npc():
		return
	_push_undo_inspector()
	_selected.set_dialogue_text(_dialogue_edit.text)


func _on_shopkeeper_toggled(on: bool) -> void:
	if _syncing_shop or _history_restoring or _selected == null or not _selected.is_npc():
		return
	_push_undo()
	_selected.is_shopkeeper = on
	## Leave shop_items as-is (empty = nothing for sale).
	_dialogue_row.visible = not on
	_rebuild_shop_list()
	_status.text = "Shopkeeper %s." % ("on" if on else "off")


func _on_tint_color_changed(c: Color) -> void:
	if _syncing_color or _history_restoring or _selected == null:
		return
	if not PieceSpecs.supports_tint(_selected.catalog_kind):
		return
	_push_undo_inspector()
	_selected.tint_color = Color(c.r, c.g, c.b, 1.0)
	_syncing_color = true
	_color_hex.text = "#" + _selected.tint_color.to_html(false)
	_syncing_color = false
	_selected._rebuild()
	_selected.set_selected(true)


func _on_tint_hex_submitted(raw: String) -> void:
	if _syncing_color or _history_restoring or _selected == null:
		return
	if not PieceSpecs.supports_tint(_selected.catalog_kind):
		return
	var s := raw.strip_edges()
	if not s.begins_with("#"):
		s = "#" + s
	if not s.is_valid_html_color():
		_status.text = "Invalid hex color."
		_syncing_color = true
		_color_hex.text = "#" + _selected.tint_color.to_html(false)
		_syncing_color = false
		return
	_push_undo_inspector()
	_selected.tint_color = Color.html(s)
	_syncing_color = true
	_color_picker.color = _selected.tint_color
	_color_hex.text = "#" + _selected.tint_color.to_html(false)
	_syncing_color = false
	_selected._rebuild()
	_selected.set_selected(true)


func _on_label_text_changed() -> void:
	if _syncing_text or _history_restoring or _selected == null or _selected.catalog_kind != "prop_text":
		return
	_push_undo_inspector()
	_selected.label_text = _text_edit.text
	_selected._rebuild()
	_selected.set_selected(true)


func _rebuild_shop_list() -> void:
	if _shop_list == null:
		return
	for c in _shop_list.get_children():
		c.queue_free()
	if _selected == null or not _selected.is_npc() or not _selected.is_shopkeeper:
		return
	for item_id in ShopCatalog.all_ids():
		var it := ShopCatalog.get_item(item_id)
		var stock := _selected.get_shop_item_stock(item_id)
		var enabled := stock != -2
		var item_price := _selected.get_shop_item_price(item_id)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 6)
		row.add_child(top)
		var sell := CheckButton.new()
		sell.text = str(it.get("name", item_id))
		sell.button_pressed = enabled
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(sell)
		var bottom := HBoxContainer.new()
		bottom.add_theme_constant_override("separation", 6)
		row.add_child(bottom)
		var inf := CheckButton.new()
		inf.text = "Inf"
		inf.disabled = not enabled
		inf.button_pressed = enabled and stock < 0
		bottom.add_child(inf)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 999
		spin.step = 1
		spin.value = 1 if (not enabled or stock < 0) else float(stock)
		spin.editable = enabled and not inf.button_pressed
		spin.custom_minimum_size.x = 72
		_commit_spin_on_enter(spin)
		bottom.add_child(spin)
		var stock_l := Label.new()
		stock_l.text = "stock"
		stock_l.add_theme_font_size_override("font_size", 11)
		stock_l.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
		bottom.add_child(stock_l)
		var price_row := HBoxContainer.new()
		price_row.add_theme_constant_override("separation", 6)
		row.add_child(price_row)
		var price_l := Label.new()
		price_l.text = "Price"
		price_l.add_theme_font_size_override("font_size", 11)
		price_l.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
		price_row.add_child(price_l)
		var price_spin := SpinBox.new()
		price_spin.min_value = 0
		price_spin.max_value = 9999
		price_spin.step = 1
		price_spin.value = float(item_price)
		price_spin.editable = enabled
		price_spin.custom_minimum_size.x = 90
		_commit_spin_on_enter(price_spin)
		price_row.add_child(price_spin)
		var gears_l := Label.new()
		gears_l.text = "gears"
		gears_l.add_theme_font_size_override("font_size", 11)
		gears_l.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		price_row.add_child(gears_l)
		sell.toggled.connect(func(on: bool) -> void:
			if _syncing_shop or _history_restoring or _selected == null:
				return
			_push_undo()
			inf.disabled = not on
			spin.editable = on and not inf.button_pressed
			price_spin.editable = on
			var s := -1 if inf.button_pressed else int(spin.value)
			_selected.set_shop_item_stock(item_id, s, on, int(price_spin.value))
		)
		inf.toggled.connect(func(on: bool) -> void:
			if _syncing_shop or _history_restoring or _selected == null or not sell.button_pressed:
				return
			_push_undo()
			spin.editable = not on
			var s := -1 if on else int(spin.value)
			_selected.set_shop_item_stock(item_id, s, true, int(price_spin.value))
		)
		spin.value_changed.connect(func(v: float) -> void:
			if _syncing_shop or _history_restoring or _selected == null or not sell.button_pressed or inf.button_pressed:
				return
			_push_undo_inspector()
			_selected.set_shop_item_stock(item_id, int(v), true, int(price_spin.value))
		)
		price_spin.value_changed.connect(func(v: float) -> void:
			if _syncing_shop or _history_restoring or _selected == null or not sell.button_pressed:
				return
			_push_undo_inspector()
			var s := -1 if inf.button_pressed else int(spin.value)
			_selected.set_shop_item_stock(item_id, s, true, int(v))
		)
		_shop_list.add_child(row)


func _on_list_selected(index: int) -> void:
	if _syncing_list or index < 0 or index >= _pieces.size():
		return
	_select(_pieces[index])
	_cam.position = Vector2(_selected.position.x, _selected.position.y)
	_clamp_camera()


func _select(piece, additive: bool = false) -> void:
	var next: EditorPiece = piece as EditorPiece if piece != null else null
	if not additive:
		if next != _selected or _selection.size() != (1 if next else 0):
			_break_undo_coalesce()
		for p in _selection:
			if p and is_instance_valid(p) and p != next:
				p.set_selected(false)
				p.show_move_arrows = false
				p.show_resize_edges = false
				p.queue_redraw()
		_selection.clear()
		_selected = next
		if _selected and is_instance_valid(_selected):
			_selection.append(_selected)
			_selected.set_selected(true)
	else:
		## Ctrl/Cmd+click: toggle membership; keep primary for inspector.
		if next == null:
			_sync_move_arrows()
			_sync_resize_edges()
			_refresh_list()
			return
		_break_undo_coalesce()
		if next in _selection:
			_selection.erase(next)
			next.set_selected(false)
			next.show_move_arrows = false
			next.show_resize_edges = false
			next.queue_redraw()
			if _selected == next:
				_selected = _selection.back() if not _selection.is_empty() else null
				if _selected and is_instance_valid(_selected):
					_selected.set_selected(true)
		else:
			_selection.append(next)
			next.set_selected(true)
			_selected = next
	_sync_move_arrows()
	_sync_resize_edges()
	_refresh_list()
	if _selection.size() > 1:
		_status.text = "Selected %d pieces (Ctrl/Cmd+click)." % _selection.size()


func _delete_selected() -> void:
	if _selection.is_empty():
		return
	_push_undo()
	var ids: Array = []
	var doomed: Array[EditorPiece] = []
	for p in _selection:
		if p and is_instance_valid(p):
			doomed.append(p)
	_selected = null
	_selection.clear()
	_group_drag_starts.clear()
	var house_zones_to_check: Array = []
	for piece in doomed:
		var id := piece.piece_id
		ids.append(id)
		if piece.catalog_kind == "prop_house":
			var hz := piece.target_zone.strip_edges()
			if hz == "":
				hz = piece.piece_id
			house_zones_to_check.append(hz)
		_pieces.erase(piece)
		if piece.builtin and id != "" and not _removed_ids.has(id):
			_removed_ids.append(id)
		if is_instance_valid(piece):
			piece.queue_free()
	for hz in house_zones_to_check:
		_maybe_unregister_house_zone(str(hz))
	_rebuild_zone_dropdowns()
	_refresh_list()
	_refresh_world_extent()
	if ids.size() == 1:
		_status.text = "Deleted '%s'." % ids[0]
	else:
		_status.text = "Deleted %d pieces." % ids.size()
	_save()


func _existing_piece_ids() -> Array:
	var ids: Array = []
	for p in _pieces:
		if p and is_instance_valid(p):
			ids.append(p.piece_id)
	for rid in _removed_ids:
		ids.append(str(rid))
	return ids


func _rebuild_zone_option() -> void:
	if _zone_option == null:
		return
	var keep := zone_id
	_zone_option.clear()
	var ids := ZoneCatalog.zone_ids()
	for i in ids.size():
		_zone_option.add_item(ids[i], i)
	var found := false
	for i in _zone_option.item_count:
		if _zone_option.get_item_text(i) == keep:
			_zone_option.select(i)
			found = true
			break
	if not found and _zone_option.item_count > 0:
		_zone_option.select(0)
		zone_id = _zone_option.get_item_text(0)


func _rebuild_target_zone_option() -> void:
	if _target_zone_option == null:
		return
	var keep := ""
	if _target_zone_option.item_count > 0 and _target_zone_option.selected >= 0:
		keep = _target_zone_option.get_item_text(_target_zone_option.selected)
	_target_zone_option.clear()
	for zid in ZoneCatalog.zone_ids():
		_target_zone_option.add_item(zid)
	if keep != "":
		for i in _target_zone_option.item_count:
			if _target_zone_option.get_item_text(i) == keep:
				_target_zone_option.select(i)
				return
	if _target_zone_option.item_count > 0:
		_target_zone_option.select(0)


func _rebuild_zone_dropdowns() -> void:
	_rebuild_zone_option()
	_rebuild_target_zone_option()


func _house_zone_still_referenced(zone_id_check: String, ignore: EditorPiece = null) -> bool:
	for p in _pieces:
		if p == null or not is_instance_valid(p) or p == ignore:
			continue
		if p.catalog_kind != "prop_house":
			continue
		var tz := p.target_zone.strip_edges()
		if tz == "":
			tz = p.piece_id
		if tz == zone_id_check:
			return true
	return false


func _maybe_unregister_house_zone(hz: String) -> void:
	if hz == "" or LevelData.is_builtin_house_zone(hz):
		return
	if not LevelData.is_editor_house_zone(hz) and not hz.begins_with("house_"):
		return
	if _house_zone_still_referenced(hz):
		return
	var was_editing := zone_id == hz
	LevelData.unregister_editor_house_zone(hz)
	if was_editing:
		zone_id = "lantern_village"
		_load_zone()


func _on_house_target_changed(piece: EditorPiece, prev: String, next: String) -> void:
	if piece == null:
		return
	## Leaving a custom house zone with no remaining facade → drop that zone.
	if prev != next:
		_maybe_unregister_house_zone(prev)
	## Pointing at a fresh house_* id creates / ensures the interior zone.
	if LevelData.is_editor_house_zone(next) or (next.begins_with("house_") and not LevelData.is_builtin_house_zone(next)):
		LevelData.register_editor_house_zone(next, piece.display_name)
	_rebuild_zone_dropdowns()


func _register_new_house_for_piece(piece: EditorPiece) -> void:
	if piece == null or piece.catalog_kind != "prop_house":
		return
	var hz := piece.target_zone.strip_edges()
	if hz == "" or LevelData.is_builtin_house_zone(hz):
		hz = LevelData.alloc_editor_house_zone_id()
		piece.target_zone = hz
	LevelData.register_editor_house_zone(hz, piece.display_name)
	_rebuild_zone_dropdowns()


## Re-attach custom house zones referenced by facades after a zone load / import.
func _sync_houses_from_pieces() -> void:
	for p in _pieces:
		if p == null or not is_instance_valid(p) or p.catalog_kind != "prop_house":
			continue
		var hz := p.target_zone.strip_edges()
		if hz == "":
			continue
		if LevelData.is_builtin_house_zone(hz):
			continue
		if hz.begins_with("house_"):
			LevelData.register_editor_house_zone(hz, p.display_name)


func _id_base_for_palette(palette: String) -> String:
	match palette:
		"light":
			return "lantern"
		"crate":
			return "crate"
		"floor":
			return "floor"
		"wall":
			return "wall"
		"block":
			return "block"
		"background":
			return "background"
		_:
			return palette.replace("prop_", "")


func _pretty_palette_name(palette: String) -> String:
	match palette:
		"light":
			return "Lantern"
		"crate":
			return "Pushable Crate"
		"prop_platform":
			return "Moving Platform"
		"prop_npc":
			return "Shopkeeper"
		"prop_checkpoint":
			return "Rest Hearth"
		"prop_switch":
			return "Lever"
		"prop_vent":
			return "Steam Vent"
		"prop_ladder":
			return "Ladder"
		"prop_breakable":
			return "Glowing Jar"
		"prop_text":
			return "Text"
		"background":
			return "Brick Wall"
		"prop_backdrop":
			match _palette_style:
				1:
					return "Teal Foundry"
				2:
					return "Riveted Bulkhead"
				_:
					return "Brick & Copper"
		"prop_valve":
			return "Valve"
		"prop_exit":
			return "Zone Door"
		"prop_house":
			return "House"
		"prop_tower":
			return "Clockwork Tower"
		"prop_hatch":
			return "Hatch"
		"prop_enemy":
			return "Enemy"
		"prop_pipe":
			return "Pipe"
		"block":
			return "Block"
		_:
			return palette.replace("prop_", "").replace("_", " ").capitalize()


func _duplicate_selected() -> void:
	if _selection.is_empty():
		return
	_push_undo()
	var sources: Array[EditorPiece] = []
	for p in _selection:
		if p and is_instance_valid(p):
			sources.append(p)
	var new_ids: Array = []
	var created: Array[EditorPiece] = []
	for src in sources:
		var d: Dictionary = src.to_dict().duplicate(true)
		d["builtin"] = false
		var base := PieceSpecs.id_base(str(d.get("id", src.catalog_kind)))
		var new_id := PieceSpecs.alloc_numbered_id(base, _existing_piece_ids())
		var num := int(new_id.get_slice("_", new_id.get_slice_count("_") - 1))
		d["id"] = new_id
		d["name"] = PieceSpecs.number_display_name(str(d.get("name", base)), num)
		d["x"] = float(d.get("x", src.position.x)) + 28.0
		d["y"] = float(d.get("y", src.position.y)) - 28.0
		if src.catalog_kind == "prop_house":
			## Duplicate gets a fresh interior — don't share the source house zone.
			var hz := LevelData.alloc_editor_house_zone_id()
			d["target_zone"] = hz
			d["house_id"] = hz
		_spawn_piece_dict(d)
		var neo: EditorPiece = _pieces.back()
		if src.catalog_kind == "prop_house":
			_register_new_house_for_piece(neo)
		created.append(neo)
		new_ids.append(new_id)
	## Replace selection with the duplicates.
	for p in _selection:
		if p and is_instance_valid(p):
			p.set_selected(false)
			p.show_move_arrows = false
			p.show_resize_edges = false
			p.queue_redraw()
	_selection.clear()
	for p in created:
		_selection.append(p)
		p.set_selected(true)
	_selected = created.back() if not created.is_empty() else null
	tool = Tool.MOVE
	_tool_label.text = "Tool: Move"
	_sync_move_arrows()
	_sync_resize_edges()
	_refresh_list()
	_refresh_world_extent()
	if new_ids.size() == 1:
		_status.text = "Duplicated → %s" % new_ids[0]
	else:
		_status.text = "Duplicated %d pieces." % new_ids.size()
	_save()


func _sync_move_arrows() -> void:
	for p in _pieces:
		if p and is_instance_valid(p):
			var on := tool == Tool.MOVE and p in _selection
			if p.show_move_arrows != on:
				p.show_move_arrows = on
				p.queue_redraw()


func _sync_resize_edges() -> void:
	for p in _pieces:
		if p and is_instance_valid(p):
			## Edge grips on the primary only — avoids overlapping handle chaos.
			var on := tool == Tool.RESIZE and p == _selected and p.kind != EditorPiece.Kind.LIGHT
			if p.show_resize_edges != on:
				p.show_resize_edges = on
				p.queue_redraw()


func _pick_at(world: Vector2) -> EditorPiece:
	## Highest draw_layer under the cursor wins; tie → later spawn (fronter in list).
	var best: EditorPiece = null
	var best_layer := -999999
	var best_idx := -1
	for i in _pieces.size():
		var p := _pieces[i]
		if p == null or not is_instance_valid(p):
			continue
		if not p.contains_point(p.to_local(world)):
			continue
		if p.draw_layer > best_layer or (p.draw_layer == best_layer and i > best_idx):
			best = p
			best_layer = p.draw_layer
			best_idx = i
	return best


func _begin_group_drag(anchor: EditorPiece, world: Vector2) -> void:
	_group_drag_starts.clear()
	for p in _selection:
		if p and is_instance_valid(p):
			_group_drag_starts[p] = p.position
	if anchor and is_instance_valid(anchor):
		anchor.begin_drag(world)


func _drag_selection_to(world: Vector2) -> void:
	if _selected == null or not is_instance_valid(_selected):
		return
	_selected.drag_to(world)
	if _group_drag_starts.is_empty() or _selection.size() <= 1:
		return
	if not _group_drag_starts.has(_selected):
		return
	## Axis lock / free drag: apply the same delta to every other selected piece.
	var delta: Vector2 = _selected.position - _group_drag_starts[_selected]
	for p in _selection:
		if p == null or not is_instance_valid(p) or p == _selected:
			continue
		if _group_drag_starts.has(p):
			p.position = _group_drag_starts[p] + delta


func _add_piece() -> void:
	_push_undo()
	var sz := PieceSpecs.default_size(_palette_id)
	var floor_top := PieceSpecs.floor_top_for_zone(zone_id)
	var y := _cam.position.y + 20.0
	## Snap floor-sitting kinds onto the zone floor so crates aren't buried.
	if _palette_id in ["crate", "prop_crate", "prop_bench", "prop_vent", "prop_ladder", "prop_checkpoint", "prop_house", "prop_hatch", "prop_npc", "prop_switch", "prop_door", "prop_exit", "prop_tower", "prop_enemy", "prop_breakable"]:
		y = PieceSpecs.sit_on_floor_y(_palette_id, floor_top, sz)
	elif _palette_id == "prop_platform":
		y = floor_top - 90.0
	var base := _id_base_for_palette(_palette_id)
	var new_id := PieceSpecs.alloc_numbered_id(base, _existing_piece_ids())
	var num := int(new_id.get_slice("_", new_id.get_slice_count("_") - 1))
	var pretty := _pretty_palette_name(_palette_id)
	var d := {
		"id": new_id,
		"name": PieceSpecs.number_display_name(pretty, num),
		"kind": _palette_id,
		"x": _cam.position.x + 40.0,
		"y": y,
		"w": sz.x,
		"h": sz.y,
		"anchor": PieceSpecs.anchor(_palette_id),
		"builtin": false,
	}
	if _palette_id == "light":
		d["radius"] = 280
		d["intensity"] = 1.0
		d["light_kind"] = GameState.LightKind.HEARTH
		d["pushable"] = false
	if _palette_id == "prop_npc":
		d["is_shopkeeper"] = true
		d["shop_items"] = [] ## All sales off until the designer enables items.
		d["lines"] = []
	if _palette_id == "prop_text":
		d["text"] = "Text"
		d["font_size"] = 14
		d["color"] = "c4b07a"
	if _palette_id == "background":
		d["w"] = maxf(float(d.get("w", 320)), 160.0)
		d["h"] = maxf(float(d.get("h", 180)), 80.0)
	if _palette_id == "prop_backdrop":
		d["style"] = _palette_style
		d["w"] = maxf(float(d.get("w", 360)), 200.0)
		d["h"] = maxf(float(d.get("h", 200)), 100.0)
	if _palette_id == "prop_exit":
		d["target_zone"] = "lantern_village"
		d["spawn_x"] = 520
		d["spawn_y"] = 460
		d["caption"] = "Traveling…"
	if _palette_id == "prop_house":
		## Each new facade gets its own editable interior zone.
		var hz := LevelData.alloc_editor_house_zone_id()
		d["target_zone"] = hz
		d["house_id"] = hz
		d["spawn_x"] = 160
		d["spawn_y"] = 460
		d["caption"] = "Entering…"
	if _palette_id == "prop_hatch":
		d["target_zone"] = "lantern_village"
		d["spawn_x"] = 140
		d["spawn_y"] = 460
	if _palette_id == "prop_switch":
		d["starts_on"] = true
		d["target_ids"] = []
	if _palette_id == "prop_enemy":
		d["enemy_kind"] = "wander"
		d["damage"] = EditorDefaults.damage_for("wander")
		d["hp"] = EditorDefaults.hp_for("wander")
	if _palette_id == "prop_door":
		d["starts_open"] = false
	if _palette_id == "prop_platform":
		d["move_amplitude"] = 90
		d["move_speed"] = 0.65
		d["vertical"] = false
		d["path_y_amplitude"] = 0
		d["rotate_while_moving"] = true
		d["rotate_speed"] = 1.0
		d["rotate_platform"] = false
		d["with_gear"] = true
	d["blocks_light"] = PieceSpecs.default_blocks_light(_palette_id)
	d["layer"] = PieceSpecs.default_draw_layer(_palette_id)
	d["rotation"] = 0
	_spawn_piece_dict(d)
	var created: EditorPiece = _pieces.back()
	if _palette_id == "prop_house":
		_register_new_house_for_piece(created)
		_status.text = "Added house → zone '%s' (open it from the Zone list)." % created.target_zone
	_select(created)
	tool = Tool.MOVE
	_tool_label.text = "Tool: Move"
	_sync_move_arrows()
	_sync_resize_edges()
	_refresh_world_extent()
	_save()


func _build_data() -> Dictionary:
	var pieces: Array = []
	for p in _pieces:
		pieces.append(p.to_dict())
	return {
		"schema": PieceSpecs.SCHEMA_VERSION,
		"zone": zone_id,
		"pieces": pieces,
		"removed_ids": _removed_ids.duplicate(),
		"backdrop": _backdrop.duplicate(true),
	}


func _capture_snapshot() -> Dictionary:
	return {
		"data": _build_data().duplicate(true),
		"selected_id": _selected.piece_id if _selected and is_instance_valid(_selected) else "",
	}


func _snapshot_equal(a: Dictionary, b: Dictionary) -> bool:
	if str(a.get("selected_id", "")) != str(b.get("selected_id", "")):
		return false
	return JSON.stringify(a.get("data", {})) == JSON.stringify(b.get("data", {}))


func _clear_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_gesture_active = false
	_gesture_snap = {}
	_coalesce_inspector = false
	_update_history_buttons()


func _break_undo_coalesce() -> void:
	_coalesce_inspector = false


func _update_history_buttons() -> void:
	if _undo_btn:
		_undo_btn.disabled = _undo_stack.is_empty()
	if _redo_btn:
		_redo_btn.disabled = _redo_stack.is_empty()


func _push_undo() -> void:
	## Capture current state before a mutation.
	if _history_restoring:
		return
	_break_undo_coalesce()
	var snap := _capture_snapshot()
	if not _undo_stack.is_empty() and _snapshot_equal(_undo_stack.back(), snap):
		_update_history_buttons()
		return
	_undo_stack.append(snap)
	while _undo_stack.size() > HISTORY_MAX:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_update_history_buttons()


func _push_undo_inspector() -> void:
	## Coalesce rapid spinbox/inspector tweaks into one undo step.
	if _history_restoring:
		return
	if _coalesce_inspector:
		return
	_push_undo()
	_coalesce_inspector = true


func _begin_gesture() -> void:
	## Start of move / resize / rotate drag — remember pre-gesture state.
	if _history_restoring or _gesture_active:
		return
	_break_undo_coalesce()
	_gesture_snap = _capture_snapshot()
	_gesture_active = true


func _end_gesture() -> void:
	if not _gesture_active:
		return
	_gesture_active = false
	var after := _capture_snapshot()
	if _snapshot_equal(_gesture_snap, after):
		_gesture_snap = {}
		return
	_undo_stack.append(_gesture_snap)
	while _undo_stack.size() > HISTORY_MAX:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_gesture_snap = {}
	_update_history_buttons()
	_save()


func _apply_snapshot(snap: Dictionary) -> void:
	_history_restoring = true
	_gesture_active = false
	_gesture_snap = {}
	_coalesce_inspector = false
	var data: Dictionary = snap.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		data = {}
	var z := str(data.get("zone", zone_id))
	if z != "" and z != zone_id:
		zone_id = z
		for i in _zone_option.item_count:
			if _zone_option.get_item_text(i) == zone_id:
				_zone_option.select(i)
				break
	_clear_pieces()
	_removed_ids = data.get("removed_ids", []).duplicate()
	if typeof(_removed_ids) != TYPE_ARRAY:
		_removed_ids = []
	var pieces: Array = data.get("pieces", [])
	for raw_p in pieces:
		if typeof(raw_p) == TYPE_DICTIONARY:
			_spawn_piece_dict(raw_p)
	_sync_houses_from_pieces()
	_rebuild_zone_dropdowns()
	_refresh_list()
	_refresh_world_extent()
	var want := str(snap.get("selected_id", ""))
	var found: EditorPiece = null
	if want != "":
		for p in _pieces:
			if p.piece_id == want:
				found = p
				break
	_select(found)
	_history_restoring = false
	_save()
	_update_history_buttons()


func _undo() -> void:
	if _undo_stack.is_empty() or _history_restoring:
		return
	_redo_stack.append(_capture_snapshot())
	while _redo_stack.size() > HISTORY_MAX:
		_redo_stack.pop_front()
	var snap: Dictionary = _undo_stack.pop_back()
	_apply_snapshot(snap)
	_status.text = "Undo (%d left)" % _undo_stack.size()


func _redo() -> void:
	if _redo_stack.is_empty() or _history_restoring:
		return
	_undo_stack.append(_capture_snapshot())
	while _undo_stack.size() > HISTORY_MAX:
		_undo_stack.pop_front()
	var snap: Dictionary = _redo_stack.pop_back()
	_apply_snapshot(snap)
	_status.text = "Redo (%d left)" % _redo_stack.size()


func _export_text() -> String:
	return JSON.stringify(_build_data(), "\t")


func _show_export_dialog() -> void:
	_save()
	var text := _export_text()
	DisplayServer.clipboard_set(text)
	_show_code_dialog(
		"Save Code — copied to clipboard",
		text,
		false,
		func(_t: String) -> void: pass
	)
	_status.text = "Save code copied. Paste it to an AI or into data/levels/%s.json" % zone_id


func _show_import_dialog() -> void:
	_show_code_dialog(
		"Import Save Code — paste JSON, then Apply",
		"",
		true,
		func(t: String) -> void:
			_import_text(t)
	)


func _show_code_dialog(title: String, initial: String, editable: bool, on_apply: Callable) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 40
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -260
	panel.offset_bottom = 260
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 12)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var title_l := Label.new()
	title_l.text = title
	title_l.add_theme_font_size_override("font_size", 16)
	col.add_child(title_l)

	var edit := TextEdit.new()
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(780, 360)
	edit.text = initial
	edit.editable = editable
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	col.add_child(edit)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)

	if not editable:
		var copy := Button.new()
		copy.text = "Copy again"
		copy.pressed.connect(func() -> void:
			DisplayServer.clipboard_set(edit.text)
			_status.text = "Copied again."
		)
		row.add_child(copy)

	if editable:
		var apply := Button.new()
		apply.text = "Apply"
		apply.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		apply.pressed.connect(func() -> void:
			on_apply.call(edit.text)
			layer.queue_free()
		)
		row.add_child(apply)

	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void:
		layer.queue_free()
	)
	row.add_child(close)
	add_child(layer)


func _import_text(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		_status.text = "Import failed: not a JSON object."
		return
	_push_undo()
	var data: Dictionary = parsed
	var z := str(data.get("zone", zone_id))
	if z != "":
		zone_id = z
		for i in _zone_option.item_count:
			if _zone_option.get_item_text(i) == zone_id:
				_zone_option.select(i)
				break
	_clear_pieces()
	_removed_ids = data.get("removed_ids", []).duplicate()
	var pieces: Array = data.get("pieces", [])
	if pieces.is_empty():
		## Empty overlay — fall back to catalog seed so the zone isn't blank.
		for cat in ZoneCatalog.pieces_for(zone_id):
			var id := str(cat.get("id", ""))
			if id != "" and _removed_ids.has(id):
				continue
			_spawn_piece_dict(cat)
	else:
		for raw_p in pieces:
			if typeof(raw_p) == TYPE_DICTIONARY:
				_spawn_piece_dict(raw_p)
	_refresh_list()
	_refresh_world_extent()
	_save()
	_status.text = "Imported %s — %d pieces." % [zone_id, _pieces.size()]


func _save() -> void:
	var err := LevelData.save_raw(zone_id, _build_data(), false)
	_status.text = "Session save %s (%d pieces)%s — refresh discards; Copy Save Code to keep." % [
		zone_id, _pieces.size(), "" if err == OK else (" · " + str(err))
	]


func _playtest() -> void:
	## Flush any focused spin so playtest sees the last typed number without requiring Enter.
	_flush_focused_spin_for_playtest()
	_save()
	GameState.editor_playtesting = true
	GameState.editor_playtest_zone = zone_id
	GameState.needs_intro_cutscene = false
	GameState.current_zone_id = zone_id
	GameState.clear_transient_zone_state()
	if HouseProfiles.is_house(zone_id):
		GameState.set_meta("pending_house_id", zone_id)
		GameState.pending_spawn = Vector2(120, 460)
		GameState.set_checkpoint(GameState.pending_spawn, "playtest", zone_id)
		get_tree().change_scene_to_file("res://scenes/rooms/HouseInterior.tscn")
		return
	match zone_id:
		"clockwork_tower":
			## ClockworkTowerZone.ENTRY_SPAWN — lobby bottom-left.
			GameState.pending_spawn = Vector2(140, 2622)
		"cursed_cottage":
			GameState.pending_spawn = Vector2(120, 440)
		_:
			GameState.pending_spawn = Vector2(160, 460)
	GameState.set_checkpoint(GameState.pending_spawn, "playtest", zone_id)
	match zone_id:
		"lantern_village":
			get_tree().change_scene_to_file("res://scenes/rooms/LanternVillage.tscn")
		"clockwork_tower":
			get_tree().change_scene_to_file("res://scenes/rooms/ClockworkTower.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/rooms/CursedCottage.tscn")

func _on_vp_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_pan_last = mb.position
			_vp_container.accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam.zoom = (_cam.zoom * 1.1).clamp(Vector2(0.2, 0.2), Vector2(4, 4))
			_clamp_camera()
			_vp_container.accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam.zoom = (_cam.zoom * 0.9).clamp(Vector2(0.2, 0.2), Vector2(4, 4))
			_clamp_camera()
			_vp_container.accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if edit_mode == EditMode.BACKGROUND:
				_vp_container.accept_event()
				return
			var world := _vp_to_world(mb.position)
			if mb.pressed:
				var additive := mb.ctrl_pressed or mb.meta_pressed
				_on_click(world, additive)
			else:
				_rotating = false
				_group_drag_starts.clear()
				if _selected and tool != Tool.DELETE:
					_selected.end_interact()
					_refresh_world_extent()
				_end_gesture()
			_vp_container.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			_cam.position -= (mm.position - _pan_last) / _cam.zoom
			_pan_last = mm.position
			_clamp_camera()
			_vp_container.accept_event()
			return
		if edit_mode == EditMode.BACKGROUND:
			return
		if _selected == null or tool == Tool.DELETE:
			return
		var world := _vp_to_world(mm.position)
		if tool == Tool.ROTATE and _rotating:
			var ang := (world - _selected.position).angle()
			var delta_deg := rad_to_deg(ang - _rotate_start_angle)
			_selected.set_rotation_deg(_rotate_piece_start + delta_deg)
			_update_inspector()
		elif tool == Tool.MOVE or _selected._dragging or _selected._axis_drag != "":
			_drag_selection_to(world)
			## Axis arrows stay precise — skip edge snap while locking one axis.
			if snap_enabled and _selected._axis_drag == "" and _selection.size() <= 1:
				_snap_selected_to_edges()
			_refresh_world_extent()
		elif tool == Tool.RESIZE or _selected._resizing:
			_selected.resize_to(world)
			if snap_enabled:
				_snap_selected_to_edges()
			_refresh_world_extent()
		_vp_container.accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			if not _selection.is_empty():
				_delete_selected()
				_vp_container.accept_event()
		elif event.keycode == KEY_D and (event.ctrl_pressed or event.meta_pressed):
			if not _selection.is_empty():
				_duplicate_selected()
				_vp_container.accept_event()
		elif event.keycode == KEY_Z and event.ctrl_pressed and event.shift_pressed:
			_redo()
			_vp_container.accept_event()
		elif event.keycode == KEY_Z and event.ctrl_pressed:
			_undo()
			_vp_container.accept_event()
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			_redo()
			_vp_container.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	## Shortcuts when focus is on the sidebar (viewport gui_input won't see them).
	if not (event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed):
		return
	if event.keycode == KEY_Z and event.shift_pressed:
		_redo()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_Z:
		_undo()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_Y:
		_redo()
		get_viewport().set_input_as_handled()


func _snap_selected_to_edges() -> void:
	## Align selected AABB edges to nearby piece edges (and floor top).
	if _selected == null or not is_instance_valid(_selected):
		return
	var mine := _selected.get_aabb()
	var best_dx := 0.0
	var best_dy := 0.0
	var abs_dx := SNAP_DIST + 1.0
	var abs_dy := SNAP_DIST + 1.0

	var my_edges_x := [mine.position.x, mine.position.x + mine.size.x, mine.get_center().x]
	var my_edges_y := [mine.position.y, mine.position.y + mine.size.y, mine.get_center().y]

	## Floor top is a common snap line.
	var floor_top := PieceSpecs.floor_top_for_zone(zone_id)
	for my_y in [mine.position.y, mine.position.y + mine.size.y]:
		var d_floor: float = floor_top - float(my_y)
		if absf(d_floor) < abs_dy:
			abs_dy = absf(d_floor)
			best_dy = d_floor

	for other in _pieces:
		if other == _selected or not is_instance_valid(other):
			continue
		## Skip absurdly huge floors/walls for X spam; still allow Y from them.
		var o := other.get_aabb()
		var ox := [o.position.x, o.position.x + o.size.x, o.get_center().x]
		var oy := [o.position.y, o.position.y + o.size.y, o.get_center().y]
		if o.size.x < 800.0:
			for a in my_edges_x:
				for b in ox:
					var dx: float = float(b) - float(a)
					if absf(dx) < abs_dx:
						abs_dx = absf(dx)
						best_dx = dx
		if o.size.y < 400.0:
			for a in my_edges_y:
				for b in oy:
					var dy: float = float(b) - float(a)
					if absf(dy) < abs_dy:
						abs_dy = absf(dy)
						best_dy = dy

	if abs_dx <= SNAP_DIST or abs_dy <= SNAP_DIST:
		var moved := mine
		if abs_dx <= SNAP_DIST:
			moved.position.x += best_dx
		if abs_dy <= SNAP_DIST:
			moved.position.y += best_dy
		_selected.set_aabb_position(moved)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_clamp_camera")


func _vp_to_world(local_pos: Vector2) -> Vector2:
	var vp_size := Vector2(_viewport.size)
	var cont_size := _vp_container.size
	if cont_size.x < 1.0 or cont_size.y < 1.0:
		return _cam.position
	var scale := vp_size / cont_size
	var vp_pixel := local_pos * scale
	var canvas := _viewport.get_canvas_transform()
	return canvas.affine_inverse() * vp_pixel


func _on_click(world: Vector2, additive: bool = false) -> void:
	## Axis tips sit outside the piece AABB — hit-test the selection first.
	if not additive and _selected and is_instance_valid(_selected) and tool == Tool.MOVE:
		var axis_sel := _selected.axis_handle_at(_selected.to_local(world))
		if axis_sel != "":
			_begin_gesture()
			_group_drag_starts.clear()
			for sp in _selection:
				if sp and is_instance_valid(sp):
					_group_drag_starts[sp] = sp.position
			_selected.begin_axis_drag(axis_sel, world)
			return
	if not additive and _selected and tool == Tool.RESIZE:
		var corner := _selected.handle_at(_selected.to_local(world))
		if corner >= 0:
			_begin_gesture()
			_selected.begin_resize(corner)
			return
	var p := _pick_at(world)
	if p != null:
		if tool == Tool.DELETE:
			_select(p, false)
			_delete_selected()
			return
		_select(p, additive)
		if additive:
			## Multi-select toggle only — don't start a drag.
			return
		if tool == Tool.SELECT or tool == Tool.MOVE:
			tool = Tool.MOVE
			_tool_label.text = "Tool: Move"
			_sync_move_arrows()
			_sync_resize_edges()
			var axis := p.axis_handle_at(p.to_local(world))
			_begin_gesture()
			if axis != "":
				_group_drag_starts.clear()
				for sp in _selection:
					if sp and is_instance_valid(sp):
						_group_drag_starts[sp] = sp.position
				p.begin_axis_drag(axis, world)
			else:
				_begin_group_drag(p, world)
		elif tool == Tool.RESIZE:
			_sync_resize_edges()
			var c := p.handle_at(p.to_local(world))
			if c >= 0:
				_begin_gesture()
				p.begin_resize(c)
		elif tool == Tool.ROTATE:
			_begin_gesture()
			_rotating = true
			_rotate_start_angle = (world - p.position).angle()
			_rotate_piece_start = p.rotation_deg
		return
	if not additive:
		_select(null)
