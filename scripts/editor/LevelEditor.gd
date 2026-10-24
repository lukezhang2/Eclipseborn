extends Control
## Password-gated level designer: palette, move/resize/delete, zone preview, playtest loop.


enum Tool { SELECT, MOVE, RESIZE, DELETE }
enum Tab { BACKGROUND, BLOCKS, LIGHTS }

const PALETTE := {
	Tab.BACKGROUND: [
		{"id": "background", "label": "Brick backdrop"},
	],
	Tab.BLOCKS: [
		{"id": "floor", "label": "Steel floor"},
		{"id": "wall", "label": "Wall"},
		{"id": "crate", "label": "Pushable crate"},
		{"id": "prop_bench", "label": "Bench"},
		{"id": "prop_vent", "label": "Steam vent"},
		{"id": "prop_crate", "label": "Decor crate"},
	],
	Tab.LIGHTS: [
		{"id": "light", "label": "Hearth lamp"},
	],
}

var zone_id: String = "cursed_cottage"
var tool: Tool = Tool.SELECT
var tab: Tab = Tab.BLOCKS
var _palette_id: String = "floor"
var _pieces: Array[EditorPiece] = []
var _selected: EditorPiece = null
var _world: Node2D
var _shell: Node2D
var _cam: Camera2D
var _hud: VBoxContainer
var _status: Label
var _delete_btn: Button
var _selection_bar: HBoxContainer
var _palette_box: VBoxContainer
var _tool_label: Label
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	_shell = Node2D.new()
	_shell.name = "ZoneShell"
	_shell.z_index = -20
	_world.add_child(_shell)
	_cam = Camera2D.new()
	_cam.position = Vector2(640, 360)
	_world.add_child(_cam)
	_cam.make_current()
	_rebuild_shell()
	_load_zone()
	_refresh_palette()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size.x = 280
	panel.offset_right = 280
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	_hud = VBoxContainer.new()
	_hud.add_theme_constant_override("separation", 8)
	_hud.custom_minimum_size.x = 260
	scroll.add_child(_hud)

	var title := Label.new()
	title.text = "Level Editor"
	title.add_theme_font_size_override("font_size", 20)
	_hud.add_child(title)

	var zone_row := HBoxContainer.new()
	_hud.add_child(zone_row)
	var zlabel := Label.new()
	zlabel.text = "Zone:"
	zone_row.add_child(zlabel)
	var zopt := OptionButton.new()
	zopt.add_item("cursed_cottage", 0)
	zopt.add_item("lantern_village", 1)
	zopt.item_selected.connect(func(idx: int) -> void:
		zone_id = zopt.get_item_text(idx)
		_rebuild_shell()
		_load_zone()
	)
	zone_row.add_child(zopt)

	_hud.add_child(_make_section("Tabs"))
	var tabs := HBoxContainer.new()
	_hud.add_child(tabs)
	_add_toggle(tabs, "Background", func() -> void:
		tab = Tab.BACKGROUND
		_refresh_palette()
	)
	_add_toggle(tabs, "Blocks", func() -> void:
		tab = Tab.BLOCKS
		_refresh_palette()
	)
	_add_toggle(tabs, "Lights", func() -> void:
		tab = Tab.LIGHTS
		_refresh_palette()
	)

	_hud.add_child(_make_section("Palette"))
	_palette_box = VBoxContainer.new()
	_palette_box.add_theme_constant_override("separation", 4)
	_hud.add_child(_palette_box)

	_hud.add_child(_make_section("Tools"))
	var tools := HBoxContainer.new()
	_hud.add_child(tools)
	_add_toggle(tools, "Select", func() -> void: _set_tool(Tool.SELECT))
	_add_toggle(tools, "Move", func() -> void: _set_tool(Tool.MOVE))
	_add_toggle(tools, "Resize", func() -> void: _set_tool(Tool.RESIZE))
	_add_toggle(tools, "Delete", func() -> void: _set_tool(Tool.DELETE))
	_tool_label = Label.new()
	_tool_label.text = "Tool: Select"
	_hud.add_child(_tool_label)

	var add_btn := Button.new()
	add_btn.text = "Add Selected Palette Piece"
	add_btn.pressed.connect(_add_piece_for_tab)
	_hud.add_child(add_btn)

	_selection_bar = HBoxContainer.new()
	_selection_bar.visible = false
	_hud.add_child(_selection_bar)
	var sel_label := Label.new()
	sel_label.text = "Selected:"
	_selection_bar.add_child(sel_label)
	_delete_btn = Button.new()
	_delete_btn.text = "Delete"
	_delete_btn.pressed.connect(_delete_selected)
	_selection_bar.add_child(_delete_btn)

	var save_btn := Button.new()
	save_btn.text = "Save (this browser only)"
	save_btn.pressed.connect(_save)
	_hud.add_child(save_btn)
	var copy_btn := Button.new()
	copy_btn.text = "Copy Level JSON"
	copy_btn.pressed.connect(_copy_json)
	_hud.add_child(copy_btn)
	var paste_btn := Button.new()
	paste_btn.text = "Paste Level JSON"
	paste_btn.pressed.connect(_paste_json)
	_hud.add_child(paste_btn)
	var play_btn := Button.new()
	play_btn.text = "Playtest Zone"
	play_btn.pressed.connect(_playtest)
	_hud.add_child(play_btn)
	var back_btn := Button.new()
	back_btn.text = "Back to Title"
	back_btn.pressed.connect(func() -> void:
		GameState.editor_playtesting = false
		get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
	)
	_hud.add_child(back_btn)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 250
	_status.text = "Pick a palette item, Add, then Move. MMB pan, wheel zoom. Playtest loads this zone from the left with Exit Playtest."
	_hud.add_child(_status)


func _make_section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	return l


func _add_toggle(parent: HBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)


func _set_tool(t: Tool) -> void:
	tool = t
	var names := {Tool.SELECT: "Select", Tool.MOVE: "Move", Tool.RESIZE: "Resize", Tool.DELETE: "Delete"}
	_tool_label.text = "Tool: %s" % names.get(t, "?")


func _refresh_palette() -> void:
	for c in _palette_box.get_children():
		c.queue_free()
	var items: Array = PALETTE.get(tab, [])
	if items.is_empty():
		return
	_palette_id = str(items[0]["id"])
	for item in items:
		var id: String = str(item["id"])
		var b := Button.new()
		b.text = str(item["label"])
		b.toggle_mode = true
		b.button_pressed = id == _palette_id
		b.pressed.connect(func() -> void:
			_palette_id = id
			for sib in _palette_box.get_children():
				if sib is Button:
					(sib as Button).button_pressed = (sib as Button).text == b.text
			_status.text = "Palette: %s" % item["label"]
		)
		_palette_box.add_child(b)
	_status.text = "Tab ready — choose a palette piece, then Add."


func _rebuild_shell() -> void:
	for c in _shell.get_children():
		c.queue_free()
	# Non-colliding preview of the real zone so the map isn't an empty void.
	match zone_id:
		"lantern_village":
			_draw_shell_rect(0, 160, 3200, 40, Color(0.12, 0.1, 0.12)) # roof band
			_draw_shell_rect(0, 500, 3200, 40, Color(0.32, 0.28, 0.24)) # floor
			_draw_shell_rect(24, 330, 48, 360, Color(0.28, 0.24, 0.2))
			_draw_shell_rect(3176, 330, 48, 360, Color(0.28, 0.24, 0.2))
			_draw_shell_line(40, 90, 3120, 90, Color(0.38, 0.36, 0.33), 10)
			_cam.position = Vector2(500, 360)
		_:
			_draw_shell_rect(0, 182, 4000, 36, Color(0.17, 0.15, 0.14)) # roof
			_draw_shell_rect(0, 482, 4000, 36, Color(0.3, 0.3, 0.33)) # floor
			_draw_shell_rect(24, 340, 48, 360, Color(0.28, 0.24, 0.2))
			_draw_shell_rect(3976, 340, 48, 360, Color(0.28, 0.24, 0.2))
			_draw_shell_line(40, 238, 3900, 238, Color(0.38, 0.36, 0.33), 10)
			_cam.position = Vector2(500, 360)
	var floor_line := Line2D.new()
	floor_line.width = 1.0
	floor_line.default_color = Color(0.5, 0.45, 0.35, 0.5)
	var fy := 520.0 if zone_id == "lantern_village" else 500.0
	floor_line.add_point(Vector2(0, fy))
	floor_line.add_point(Vector2(4000, fy))
	_shell.add_child(floor_line)


func _draw_shell_rect(x: float, y: float, w: float, h: float, col: Color) -> void:
	var p := Polygon2D.new()
	p.color = col
	p.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)
	])
	_shell.add_child(p)


func _draw_shell_line(x0: float, y0: float, x1: float, y1: float, col: Color, width: float) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = col
	line.add_point(Vector2(x0, y0))
	line.add_point(Vector2(x1, y1))
	_shell.add_child(line)


func _clear_pieces() -> void:
	for p in _pieces:
		if is_instance_valid(p):
			p.queue_free()
	_pieces.clear()
	_selected = null
	_update_selection_ui()


func _load_zone() -> void:
	_clear_pieces()
	var data := LevelData.load_raw(zone_id)
	for raw in data.get("pieces", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var piece := EditorPiece.new()
		_world.add_child(piece)
		piece.apply_dict(raw)
		_pieces.append(piece)
	_status.text = "Loaded %s — %d overlay pieces (shell shows base zone)." % [zone_id, _pieces.size()]


func _add_piece_for_tab() -> void:
	var piece := EditorPiece.new()
	_world.add_child(piece)
	var pos := _cam.position + Vector2(40, 40)
	match _palette_id:
		"background":
			piece.setup(EditorPiece.Kind.BACKGROUND, pos, Vector2(200, 160))
		"light":
			piece.setup(EditorPiece.Kind.LIGHT, pos, Vector2(48, 48))
		"wall":
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(48, 96))
			piece.set_meta("piece_kind", "wall")
		"crate":
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(48, 48))
			piece.set_meta("piece_kind", "crate")
		"prop_bench":
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(60, 20))
			piece.set_meta("piece_kind", "prop_bench")
		"prop_vent":
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(36, 16))
			piece.set_meta("piece_kind", "prop_vent")
		"prop_crate":
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(36, 28))
			piece.set_meta("piece_kind", "prop_crate")
		_:
			piece.setup(EditorPiece.Kind.BLOCK, pos, Vector2(96, 32))
			piece.set_meta("piece_kind", "floor")
	_pieces.append(piece)
	_select(piece)
	_set_tool(Tool.MOVE)
	_status.text = "Added %s — drag to place." % _palette_id


func _delete_selected() -> void:
	if _selected == null:
		return
	var doomed := _selected
	_selected = null
	_pieces.erase(doomed)
	if is_instance_valid(doomed):
		doomed.queue_free()
	_update_selection_ui()
	_status.text = "Deleted. %d remaining." % _pieces.size()


func _select(piece: EditorPiece) -> void:
	if _selected:
		_selected.set_selected(false)
	_selected = piece
	if _selected:
		_selected.set_selected(true)
	_update_selection_ui()


func _update_selection_ui() -> void:
	if _selection_bar:
		_selection_bar.visible = _selected != null
	if _delete_btn:
		_delete_btn.disabled = _selected == null


func _build_data() -> Dictionary:
	var pieces: Array = []
	for p in _pieces:
		var d: Dictionary = p.to_dict()
		if p.has_meta("piece_kind"):
			d["kind"] = str(p.get_meta("piece_kind"))
		pieces.append(d)
	return {"zone": zone_id, "pieces": pieces}


func _save() -> void:
	var data := _build_data()
	var err := LevelData.save_raw(zone_id, data, false)
	_status.text = "Saved locally (%d pieces). %s" % [data["pieces"].size(), "ok" if err == OK else str(err)]


func _copy_json() -> void:
	var text := JSON.stringify(_build_data(), "\t")
	DisplayServer.clipboard_set(text)
	_status.text = "Copied %d pieces." % _pieces.size()


func _paste_json() -> void:
	var text := DisplayServer.clipboard_get()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_status.text = "Clipboard is not valid level JSON."
		return
	var data: Dictionary = parsed
	_clear_pieces()
	zone_id = str(data.get("zone", zone_id))
	_rebuild_shell()
	for raw in data.get("pieces", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var piece := EditorPiece.new()
		_world.add_child(piece)
		piece.apply_dict(raw)
		if str(raw.get("kind", "")) not in ["background", "light", "floor", "block"]:
			piece.set_meta("piece_kind", str(raw.get("kind")))
		_pieces.append(piece)
	LevelData.save_raw(zone_id, data, false)
	_status.text = "Imported %d pieces into %s." % [_pieces.size(), zone_id]


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
	# Use _input so world clicks work even though we are a full-rect Control.
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
			if _selected and not _pointer_over_panel():
				_delete_selected()
				get_viewport().set_input_as_handled()
				return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if _pointer_over_panel() and mb.button_index == MOUSE_BUTTON_LEFT:
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			_pan_last = mb.position
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam.zoom *= 1.1
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam.zoom *= 0.9
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world := _screen_to_world(mb.position)
			if mb.pressed:
				_on_click(world)
			else:
				if _selected and tool != Tool.DELETE:
					_selected.end_interact()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			var delta := mm.position - _pan_last
			_pan_last = mm.position
			_cam.position -= delta / _cam.zoom
			get_viewport().set_input_as_handled()
			return
		if _selected == null or tool == Tool.DELETE:
			return
		if _pointer_over_panel():
			return
		var world := _screen_to_world(mm.position)
		if tool == Tool.MOVE or _selected._dragging:
			_selected.drag_to(world)
		elif tool == Tool.RESIZE or _selected._resizing:
			_selected.resize_to(world)


func _pointer_over_panel() -> bool:
	return get_viewport().get_mouse_position().x < 280.0


func _screen_to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen


func _on_click(world: Vector2) -> void:
	if _selected and tool == Tool.RESIZE:
		var local := _selected.to_local(world)
		var corner := _selected.handle_at(local)
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
			if tool == Tool.MOVE or tool == Tool.SELECT:
				_set_tool(Tool.MOVE)
				p.begin_drag(world)
			elif tool == Tool.RESIZE:
				var c := p.handle_at(p.to_local(world))
				if c >= 0:
					p.begin_resize(c)
			return
	_select(null)
