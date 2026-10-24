extends Control
## Password-gated level designer: Background / Blocks / Lights, move + resize.


enum Tool { SELECT, MOVE, RESIZE }
enum Tab { BACKGROUND, BLOCKS, LIGHTS }

var zone_id: String = "cursed_cottage"
var tool: Tool = Tool.SELECT
var tab: Tab = Tab.BLOCKS
var _pieces: Array[EditorPiece] = []
var _selected: EditorPiece = null
var _world: Node2D
var _cam: Camera2D
var _hud: VBoxContainer
var _status: Label
var _panning: bool = false
var _pan_last: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	_cam = Camera2D.new()
	_cam.position = Vector2(640, 360)
	_world.add_child(_cam)
	_cam.make_current()
	_draw_grid()
	_load_zone()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size.x = 260
	panel.offset_right = 260
	add_child(panel)
	_hud = VBoxContainer.new()
	_hud.add_theme_constant_override("separation", 8)
	panel.add_child(_hud)

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
		_load_zone()
	)
	zone_row.add_child(zopt)

	_hud.add_child(_make_section("Tabs"))
	var tabs := HBoxContainer.new()
	_hud.add_child(tabs)
	_add_toggle(tabs, "Background", func() -> void: tab = Tab.BACKGROUND)
	_add_toggle(tabs, "Blocks", func() -> void: tab = Tab.BLOCKS)
	_add_toggle(tabs, "Lights", func() -> void: tab = Tab.LIGHTS)

	_hud.add_child(_make_section("Tools"))
	var tools := HBoxContainer.new()
	_hud.add_child(tools)
	_add_toggle(tools, "Select", func() -> void: tool = Tool.SELECT)
	_add_toggle(tools, "Move", func() -> void: tool = Tool.MOVE)
	_add_toggle(tools, "Resize", func() -> void: tool = Tool.RESIZE)

	_hud.add_child(_make_section("Palette"))
	var add_btn := Button.new()
	add_btn.text = "Add Piece"
	add_btn.pressed.connect(_add_piece_for_tab)
	_hud.add_child(add_btn)
	var del_btn := Button.new()
	del_btn.text = "Delete Selected"
	del_btn.pressed.connect(_delete_selected)
	_hud.add_child(del_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Overlay"
	save_btn.pressed.connect(_save)
	_hud.add_child(save_btn)
	var play_btn := Button.new()
	play_btn.text = "Playtest Zone"
	play_btn.pressed.connect(_playtest)
	_hud.add_child(play_btn)
	var back_btn := Button.new()
	back_btn.text = "Back to Title"
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
	)
	_hud.add_child(back_btn)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Click bottom-right on title with password to reopen. Drag middle-mouse to pan."
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


func _draw_grid() -> void:
	var g := Node2D.new()
	g.z_index = -50
	g.name = "Grid"
	_world.add_child(g)
	var floor_line := Line2D.new()
	floor_line.width = 2.0
	floor_line.default_color = Color(0.4, 0.35, 0.3, 0.8)
	floor_line.add_point(Vector2(0, 520))
	floor_line.add_point(Vector2(4000, 520))
	g.add_child(floor_line)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2(-200, -200), Vector2(4200, -200), Vector2(4200, 900), Vector2(-200, 900)])
	bg.color = Color(0.06, 0.05, 0.07)
	bg.z_index = -100
	_world.add_child(bg)


func _clear_pieces() -> void:
	for p in _pieces:
		if is_instance_valid(p):
			p.queue_free()
	_pieces.clear()
	_selected = null


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
	_status.text = "Loaded %s (%d pieces)" % [zone_id, _pieces.size()]


func _add_piece_for_tab() -> void:
	var piece := EditorPiece.new()
	_world.add_child(piece)
	match tab:
		Tab.BACKGROUND:
			piece.setup(EditorPiece.Kind.BACKGROUND, _cam.position + Vector2(0, -40), Vector2(200, 160))
		Tab.LIGHTS:
			piece.setup(EditorPiece.Kind.LIGHT, _cam.position, Vector2(48, 48))
		_:
			piece.setup(EditorPiece.Kind.BLOCK, _cam.position + Vector2(0, 80), Vector2(96, 32))
	_pieces.append(piece)
	_select(piece)


func _delete_selected() -> void:
	if _selected == null:
		return
	_pieces.erase(_selected)
	_selected.queue_free()
	_selected = null


func _select(piece: EditorPiece) -> void:
	if _selected:
		_selected.set_selected(false)
	_selected = piece
	if _selected:
		_selected.set_selected(true)


func _save() -> void:
	var pieces: Array = []
	for p in _pieces:
		pieces.append(p.to_dict())
	var data := {"zone": zone_id, "pieces": pieces}
	var err := LevelData.save_raw(zone_id, data, false)
	# Also try writing into res for repo commits when running in editor/export writable.
	LevelData.save_raw(zone_id, data, true)
	_status.text = "Saved %s (%d) — %s" % [zone_id, pieces.size(), "ok" if err == OK else str(err)]


func _playtest() -> void:
	_save()
	match zone_id:
		"lantern_village":
			get_tree().change_scene_to_file("res://scenes/rooms/LanternVillage.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/rooms/CursedCottage.tscn")


func _gui_input(event: InputEvent) -> void:
	# Left panel eats UI; world clicks come through when not on panel.
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			_pan_last = mb.position
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam.zoom *= 1.1
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam.zoom *= 0.9
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world := _screen_to_world(mb.position)
			if mb.pressed:
				_on_click(world)
			else:
				if _selected:
					_selected.end_interact()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			var delta := mm.position - _pan_last
			_pan_last = mm.position
			_cam.position -= delta / _cam.zoom
			return
		if _selected == null:
			return
		var world := _screen_to_world(mm.position)
		if tool == Tool.MOVE or (_selected._dragging):
			_selected.drag_to(world)
		elif tool == Tool.RESIZE or _selected._resizing:
			_selected.resize_to(world)


func _screen_to_world(screen: Vector2) -> Vector2:
	var vp := get_viewport().get_canvas_transform().affine_inverse()
	return vp * screen


func _on_click(world: Vector2) -> void:
	# Prefer handle hit on selected for resize.
	if _selected and tool == Tool.RESIZE:
		var local := _selected.to_local(world)
		var corner := _selected.handle_at(local)
		if corner >= 0:
			_selected.begin_resize(corner)
			return
	# Hit-test pieces front-to-back.
	for i in range(_pieces.size() - 1, -1, -1):
		var p := _pieces[i]
		if p.contains_point(p.to_local(world)):
			_select(p)
			if tool == Tool.MOVE or tool == Tool.SELECT:
				p.begin_drag(world)
			elif tool == Tool.RESIZE:
				var c := p.handle_at(p.to_local(world))
				if c >= 0:
					p.begin_resize(c)
			return
	_select(null)
