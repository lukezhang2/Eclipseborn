extends Control
## Level editor: fixed left toolbar, world SubViewport, bottom scrub for long levels.


enum Tool { SELECT, MOVE, RESIZE, DELETE }

const PANEL_W := 320.0
const BOTTOM_H := 44.0
const OVERSCROLL := 960.0 ## How far past the rightmost piece you can pan to keep building.
const MIN_WORLD_RIGHT := 1600.0
const CAM_Y := 360.0


var zone_id: String = "cursed_cottage"
var tool: Tool = Tool.SELECT
var _palette_id: String = "floor"
var _pieces: Array[EditorPiece] = []
var _removed_ids: Array = []
var _selected: EditorPiece = null
var _world: Node2D
var _cam: Camera2D
var _bg: Polygon2D
var _viewport: SubViewport
var _vp_container: SubViewportContainer
var _piece_list: ItemList
var _name_edit: LineEdit
var _radius_spin: SpinBox
var _radius_row: HBoxContainer
var _status: Label
var _tool_label: Label
var _zone_option: OptionButton
var _scrub: HScrollBar
var _scrub_label: Label
var _extent_label: Label
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO
var _syncing_list: bool = false
var _syncing_scrub: bool = false
var _world_right: float = MIN_WORLD_RIGHT


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
	_zone_option.add_item("cursed_cottage", 0)
	_zone_option.add_item("lantern_village", 1)
	_zone_option.item_selected.connect(func(i: int) -> void:
		zone_id = _zone_option.get_item_text(i)
		_load_zone()
	)
	zone_row.add_child(_zone_option)

	col.add_child(_section("Pieces"))
	_piece_list = ItemList.new()
	_piece_list.custom_minimum_size = Vector2(280, 200)
	_piece_list.item_selected.connect(_on_list_selected)
	col.add_child(_piece_list)

	var sel_row := HBoxContainer.new()
	col.add_child(sel_row)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_submitted.connect(func(t: String) -> void:
		if _selected:
			_selected.display_name = t
			_selected._rebuild()
			_selected.set_selected(true)
			_refresh_list()
	)
	sel_row.add_child(_name_edit)
	var del := Button.new()
	del.text = "Delete"
	del.pressed.connect(_delete_selected)
	sel_row.add_child(del)

	_radius_row = HBoxContainer.new()
	_radius_row.visible = false
	col.add_child(_radius_row)
	_radius_row.add_child(_lbl("Lantern radius"))
	_radius_spin = SpinBox.new()
	_radius_spin.min_value = 40
	_radius_spin.max_value = 900
	_radius_spin.step = 10
	_radius_spin.value = 280
	_radius_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radius_spin.value_changed.connect(func(v: float) -> void:
		if _selected and _selected.kind == EditorPiece.Kind.LIGHT:
			_selected.light_radius = v
			_selected._rebuild()
			_selected.set_selected(true)
			_refresh_world_extent()
	)
	_radius_row.add_child(_radius_spin)

	col.add_child(_section("Tools"))
	var tools := HBoxContainer.new()
	col.add_child(tools)
	for pair in [["Select", Tool.SELECT], ["Move", Tool.MOVE], ["Resize", Tool.RESIZE], ["Delete", Tool.DELETE]]:
		var b := Button.new()
		b.text = pair[0]
		var t: Tool = pair[1]
		b.pressed.connect(func() -> void:
			tool = t
			_tool_label.text = "Tool: %s" % pair[0]
		)
		tools.add_child(b)
	_tool_label = Label.new()
	_tool_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tool_label.text = "Tool: Select — click world or list"
	col.add_child(_tool_label)

	col.add_child(_section("Add"))
	var add_row := HBoxContainer.new()
	col.add_child(add_row)
	var add_opt := OptionButton.new()
	add_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in [
		["floor", "Steel floor"], ["wall", "Wall"], ["crate", "Crate"],
		["light", "Lantern"], ["prop_bench", "Bench"], ["prop_checkpoint", "Checkpoint"],
	]:
		add_opt.add_item(item[1])
		add_opt.set_item_metadata(add_opt.item_count - 1, item[0])
	add_opt.item_selected.connect(func(i: int) -> void:
		_palette_id = str(add_opt.get_item_metadata(i))
	)
	add_row.add_child(add_opt)
	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.pressed.connect(_add_piece)
	add_row.add_child(add_btn)

	var save_btn := Button.new()
	save_btn.text = "Save (this browser)"
	save_btn.pressed.connect(_save)
	col.add_child(save_btn)
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
	_status.custom_minimum_size = Vector2(280, 70)
	_status.text = "Left panel is fixed. Bottom bar scrolls the level. Build past the end to grow it."
	col.add_child(_status)


func _lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _section(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	return l


func _piece_right_edge(p: EditorPiece) -> float:
	if p == null or not is_instance_valid(p):
		return 0.0
	match p.kind:
		EditorPiece.Kind.LIGHT:
			return p.position.x + maxf(p.light_radius, 40.0)
		_:
			return p.position.x + maxf(p.size.x, 8.0) * 0.5


func _compute_world_right() -> float:
	var right := MIN_WORLD_RIGHT
	for p in _pieces:
		if is_instance_valid(p):
			right = maxf(right, _piece_right_edge(p))
	return right


func _refresh_world_extent() -> void:
	_world_right = _compute_world_right()
	_rebuild_bg()
	_sync_scrub_from_camera(true)


func _rebuild_bg() -> void:
	if _bg == null:
		return
	var right := _world_right + OVERSCROLL + 400.0
	_bg.polygon = PackedVector2Array([
		Vector2(-400, -400), Vector2(right, -400), Vector2(right, 1100), Vector2(-400, 1100)
	])


func _view_page_width() -> float:
	## Approximate visible world width behind the camera at current zoom.
	var cont_w := maxf(_vp_container.size.x, 1.0)
	return cont_w / maxf(_cam.zoom.x, 0.05)


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
		_extent_label.text = "%.0f" % _world_right
	_scrub_label.text = "x %.0f" % _cam.position.x
	_syncing_scrub = false


func _on_scrub_changed(value: float) -> void:
	if _syncing_scrub or _cam == null:
		return
	var page := _view_page_width()
	_cam.position.x = value + page * 0.5
	_cam.position.y = CAM_Y
	_scrub_label.text = "x %.0f" % _cam.position.x


func _clamp_camera() -> void:
	if _cam == null:
		return
	var page := _view_page_width()
	var max_left := maxf(0.0, _world_right + OVERSCROLL - page)
	var left := clampf(_cam.position.x - page * 0.5, 0.0, max_left)
	_cam.position.x = left + page * 0.5
	_cam.position.y = CAM_Y
	_sync_scrub_from_camera()


func _clear_pieces() -> void:
	for p in _pieces:
		if is_instance_valid(p):
			p.queue_free()
	_pieces.clear()
	_selected = null


func _load_zone() -> void:
	_clear_pieces()
	var data := LevelData.load_raw(zone_id)
	_removed_ids = data.get("removed_ids", []).duplicate()
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
			for key in ["x", "y", "w", "h", "name", "radius", "light_kind", "pushable"]:
				if ov.has(key):
					merged[key] = ov[key]
			overrides.erase(id)
		_spawn_piece_dict(merged)
	for id in overrides.keys():
		var raw: Dictionary = overrides[id]
		if bool(raw.get("builtin", false)):
			continue
		_spawn_piece_dict(raw)
	_cam.position = Vector2(700, CAM_Y)
	_cam.zoom = Vector2.ONE
	_refresh_list()
	_refresh_world_extent()
	_status.text = "Loaded %s — %d pieces." % [zone_id, _pieces.size()]


func _spawn_piece_dict(d: Dictionary) -> void:
	var piece := EditorPiece.new()
	_world.add_child(piece)
	piece.apply_dict(d)
	if str(d.get("kind", "")) == "light" and d.has("radius"):
		piece.light_radius = float(d.get("radius", 280))
		piece._rebuild()
	_pieces.append(piece)


func _refresh_list() -> void:
	_syncing_list = true
	_piece_list.clear()
	for i in _pieces.size():
		var p := _pieces[i]
		var extra := ""
		if p.kind == EditorPiece.Kind.LIGHT:
			extra = "  r=%.0f" % p.light_radius
		_piece_list.add_item("%s [%s]%s" % [p.display_name, p.piece_id, extra])
		if p == _selected:
			_piece_list.select(i)
	_syncing_list = false
	_update_inspector()


func _update_inspector() -> void:
	_name_edit.text = _selected.display_name if _selected else ""
	var is_light := _selected != null and _selected.kind == EditorPiece.Kind.LIGHT
	_radius_row.visible = is_light
	if is_light:
		_radius_spin.value = _selected.light_radius


func _on_list_selected(index: int) -> void:
	if _syncing_list or index < 0 or index >= _pieces.size():
		return
	_select(_pieces[index])
	_cam.position = Vector2(_selected.position.x, CAM_Y)
	_clamp_camera()


func _select(piece: EditorPiece) -> void:
	if _selected and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = piece
	if _selected:
		_selected.set_selected(true)
	_refresh_list()


func _delete_selected() -> void:
	if _selected == null:
		return
	var doomed := _selected
	var id := doomed.piece_id
	_selected = null
	_pieces.erase(doomed)
	if doomed.builtin and id != "" and not _removed_ids.has(id):
		_removed_ids.append(id)
	if is_instance_valid(doomed):
		doomed.queue_free()
	_refresh_list()
	_refresh_world_extent()
	_status.text = "Deleted '%s'." % id
	_save()


func _add_piece() -> void:
	var d := {
		"id": "%s_%d" % [_palette_id, Time.get_ticks_msec()],
		"name": _palette_id.replace("prop_", "").capitalize(),
		"kind": _palette_id,
		"x": _cam.position.x + 40,
		"y": _cam.position.y + 20,
		"w": 96 if _palette_id == "floor" else 48,
		"h": 32 if _palette_id == "floor" else 48,
		"builtin": false,
	}
	if _palette_id == "light":
		d["name"] = "Lantern"
		d["radius"] = 280
		d["pushable"] = true
	_spawn_piece_dict(d)
	_select(_pieces.back())
	tool = Tool.MOVE
	_tool_label.text = "Tool: Move"
	_refresh_world_extent()


func _build_data() -> Dictionary:
	var pieces: Array = []
	for p in _pieces:
		pieces.append(p.to_dict())
	return {"zone": zone_id, "pieces": pieces, "removed_ids": _removed_ids}


func _save() -> void:
	var err := LevelData.save_raw(zone_id, _build_data(), false)
	_status.text = "Saved %s (%d pieces). %s" % [zone_id, _pieces.size(), "ok" if err == OK else str(err)]


func _playtest() -> void:
	_save()
	GameState.editor_playtesting = true
	GameState.editor_playtest_zone = zone_id
	GameState.needs_intro_cutscene = false
	GameState.pending_spawn = Vector2(120, 440) if zone_id == "cursed_cottage" else Vector2(160, 460)
	GameState.last_position = GameState.pending_spawn
	GameState.checkpoint_position = GameState.pending_spawn
	GameState.current_zone_id = zone_id
	match zone_id:
		"lantern_village":
			get_tree().change_scene_to_file("res://scenes/rooms/LanternVillage.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/rooms/CursedCottage.tscn")


func _on_vp_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
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
			var world := _vp_to_world(mb.position)
			if mb.pressed:
				_on_click(world)
			elif _selected and tool != Tool.DELETE:
				_selected.end_interact()
				_refresh_world_extent()
			_vp_container.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			_cam.position -= (mm.position - _pan_last) / _cam.zoom
			_pan_last = mm.position
			_clamp_camera()
			_vp_container.accept_event()
			return
		if _selected == null or tool == Tool.DELETE:
			return
		var world := _vp_to_world(mm.position)
		if tool == Tool.MOVE or _selected._dragging:
			_selected.drag_to(world)
			_refresh_world_extent()
		elif tool == Tool.RESIZE or _selected._resizing:
			_selected.resize_to(world)
			_refresh_world_extent()
		_vp_container.accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			if _selected:
				_delete_selected()
				_vp_container.accept_event()


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


func _on_click(world: Vector2) -> void:
	if _selected and tool == Tool.RESIZE:
		var corner := _selected.handle_at(_selected.to_local(world))
		if corner >= 0:
			_selected.begin_resize(corner)
			return
	for i in range(_pieces.size() - 1, -1, -1):
		var p := _pieces[i]
		if p.contains_point(p.to_local(world)):
			if tool == Tool.DELETE:
				_select(p)
				_delete_selected()
				return
			_select(p)
			if tool == Tool.SELECT or tool == Tool.MOVE:
				tool = Tool.MOVE
				_tool_label.text = "Tool: Move"
				p.begin_drag(world)
			elif tool == Tool.RESIZE:
				var c := p.handle_at(p.to_local(world))
				if c >= 0:
					p.begin_resize(c)
			return
	_select(null)
