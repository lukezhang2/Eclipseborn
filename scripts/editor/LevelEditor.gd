extends Control
## Level editor: loads the real zone catalog (named props), list + delete + move.


enum Tool { SELECT, MOVE, RESIZE, DELETE }

var zone_id: String = "cursed_cottage"
var tool: Tool = Tool.SELECT
var _palette_id: String = "floor"
var _pieces: Array[EditorPiece] = []
var _removed_ids: Array = []
var _selected: EditorPiece = null
var _world: Node2D
var _cam: Camera2D
var _piece_list: ItemList
var _name_edit: LineEdit
var _status: Label
var _tool_label: Label
var _zone_option: OptionButton
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO
var _syncing_list: bool = false

const PANEL_W := 300.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_world()
	_build_ui()
	_load_zone()


func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	var bg := Polygon2D.new()
	bg.z_index = -100
	bg.color = Color(0.05, 0.045, 0.06)
	bg.polygon = PackedVector2Array([
		Vector2(-400, -400), Vector2(4500, -400), Vector2(4500, 1100), Vector2(-400, 1100)
	])
	_world.add_child(bg)
	_cam = Camera2D.new()
	_cam.position = Vector2(700, 360)
	_world.add_child(_cam)
	_cam.make_current()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "SidePanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right = PANEL_W
	panel.offset_left = 0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	var title := Label.new()
	title.text = "Level Editor"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	var zone_row := HBoxContainer.new()
	col.add_child(zone_row)
	var zl := Label.new()
	zl.text = "Zone"
	zone_row.add_child(zl)
	_zone_option = OptionButton.new()
	_zone_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zone_option.add_item("cursed_cottage", 0)
	_zone_option.add_item("lantern_village", 1)
	_zone_option.item_selected.connect(_on_zone_selected)
	zone_row.add_child(_zone_option)

	col.add_child(_section("Pieces in zone"))
	_piece_list = ItemList.new()
	_piece_list.custom_minimum_size = Vector2(260, 220)
	_piece_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_piece_list.item_selected.connect(_on_list_selected)
	col.add_child(_piece_list)

	var sel_row := HBoxContainer.new()
	col.add_child(sel_row)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Selected name"
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

	col.add_child(_section("Tools"))
	var tools := HBoxContainer.new()
	col.add_child(tools)
	_tool_btn(tools, "Select", Tool.SELECT)
	_tool_btn(tools, "Move", Tool.MOVE)
	_tool_btn(tools, "Resize", Tool.RESIZE)
	_tool_btn(tools, "Delete", Tool.DELETE)
	_tool_label = Label.new()
	_tool_label.text = "Tool: Select — click a piece or pick from the list"
	_tool_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_tool_label)

	col.add_child(_section("Add piece"))
	var add_row := HBoxContainer.new()
	col.add_child(add_row)
	var add_opt := OptionButton.new()
	add_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in [
		["floor", "Steel floor"], ["wall", "Wall"], ["crate", "Pushable crate"],
		["light", "Lamp"], ["prop_bench", "Bench"], ["prop_vent", "Steam vent"],
		["prop_crate", "Decor crate"], ["prop_checkpoint", "Checkpoint"],
	]:
		add_opt.add_item(item[1])
		add_opt.set_item_metadata(add_opt.item_count - 1, item[0])
	add_opt.item_selected.connect(func(i: int) -> void:
		_palette_id = str(add_opt.get_item_metadata(i))
	)
	_palette_id = "floor"
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
	_status.custom_minimum_size = Vector2(260, 80)
	_status.text = "MMB pan · wheel zoom · list shows every named prop in the zone."
	col.add_child(_status)


func _section(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	return l


func _tool_btn(parent: HBoxContainer, text: String, t: Tool) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func() -> void:
		tool = t
		_tool_label.text = "Tool: %s" % text
	)
	parent.add_child(b)


func _on_zone_selected(idx: int) -> void:
	zone_id = _zone_option.get_item_text(idx)
	_load_zone()


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
	# Prefer saved piece layout; otherwise load the live zone catalog.
	var raw_pieces: Array = data.get("pieces", [])
	var source: Array = raw_pieces if raw_pieces.size() > 0 else ZoneCatalog.pieces_for(zone_id)
	for raw in source:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id := str(raw.get("id", ""))
		if id != "" and _removed_ids.has(id):
			continue
		var piece := EditorPiece.new()
		_world.add_child(piece)
		piece.apply_dict(raw)
		_pieces.append(piece)
	_cam.position = Vector2(700, 360)
	_refresh_list()
	_status.text = "Loaded %s — %d pieces (%d removed hidden)." % [zone_id, _pieces.size(), _removed_ids.size()]


func _refresh_list() -> void:
	_syncing_list = true
	_piece_list.clear()
	for i in _pieces.size():
		var p := _pieces[i]
		var label := "%s  [%s]" % [p.display_name, p.piece_id]
		_piece_list.add_item(label)
		if p == _selected:
			_piece_list.select(i)
	_syncing_list = false
	_name_edit.text = _selected.display_name if _selected else ""


func _on_list_selected(index: int) -> void:
	if _syncing_list or index < 0 or index >= _pieces.size():
		return
	_select(_pieces[index])
	_cam.position = _selected.position


func _select(piece: EditorPiece) -> void:
	if _selected and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = piece
	if _selected:
		_selected.set_selected(true)
		_name_edit.text = _selected.display_name
	else:
		_name_edit.text = ""
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
	_status.text = "Deleted '%s'. Save to keep it removed from the zone." % id
	_save()


func _add_piece() -> void:
	var piece := EditorPiece.new()
	_world.add_child(piece)
	var pos := _cam.position + Vector2(40, 20)
	var d := {
		"id": "%s_%d" % [_palette_id, Time.get_ticks_msec()],
		"name": _palette_id.replace("prop_", "").capitalize(),
		"kind": _palette_id,
		"x": pos.x,
		"y": pos.y,
		"w": 96 if _palette_id == "floor" else 48,
		"h": 32 if _palette_id == "floor" else 48,
		"builtin": false,
	}
	if _palette_id == "prop_checkpoint":
		d["name"] = "Checkpoint"
		d["w"] = 56
		d["h"] = 24
	piece.apply_dict(d)
	_pieces.append(piece)
	_select(piece)
	tool = Tool.MOVE
	_tool_label.text = "Tool: Move"
	_status.text = "Added %s — drag to place." % piece.display_name


func _build_data() -> Dictionary:
	var pieces: Array = []
	for p in _pieces:
		pieces.append(p.to_dict())
	return {"zone": zone_id, "pieces": pieces, "removed_ids": _removed_ids}


func _save() -> void:
	var err := LevelData.save_raw(zone_id, _build_data(), false)
	_status.text = "Saved %s locally (%d pieces, %d removed). %s" % [
		zone_id, _pieces.size(), _removed_ids.size(), "ok" if err == OK else str(err)
	]


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


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			if _selected and not _over_panel():
				_delete_selected()
				get_viewport().set_input_as_handled()
				return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if _over_panel() and mb.button_index == MOUSE_BUTTON_LEFT:
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			_pan_last = mb.position
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam.zoom = (_cam.zoom * 1.1).clamp(Vector2(0.25, 0.25), Vector2(4, 4))
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam.zoom = (_cam.zoom * 0.9).clamp(Vector2(0.25, 0.25), Vector2(4, 4))
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world := _screen_to_world(mb.position)
			if mb.pressed:
				_on_click(world)
			elif _selected and tool != Tool.DELETE:
				_selected.end_interact()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			_cam.position -= (mm.position - _pan_last) / _cam.zoom
			_pan_last = mm.position
			get_viewport().set_input_as_handled()
			return
		if _selected == null or tool == Tool.DELETE or _over_panel():
			return
		var world := _screen_to_world(mm.position)
		if tool == Tool.MOVE or _selected._dragging:
			_selected.drag_to(world)
		elif tool == Tool.RESIZE or _selected._resizing:
			_selected.resize_to(world)


func _over_panel() -> bool:
	return get_viewport().get_mouse_position().x < PANEL_W


func _screen_to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen


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
