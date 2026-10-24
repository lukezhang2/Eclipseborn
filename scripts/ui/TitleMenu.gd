extends Control

@onready var main_panel: VBoxContainer = $Center/Main
@onready var play_panel: VBoxContainer = $Center/PlaySlots
@onready var controls_panel: VBoxContainer = $Center/Controls
@onready var slots_box: VBoxContainer = $Center/PlaySlots/Slots
@onready var controls_list: VBoxContainer = $Center/Controls/List

var _confirm_layer: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.set_paused(false)
	_hide_tagline()
	_show_main()
	_build_slots()
	_build_controls()
	InputMapManager.bindings_changed.connect(_build_controls)


func _hide_tagline() -> void:
	var tag := main_panel.get_node_or_null("Tag")
	if tag:
		tag.visible = false
		tag.queue_free()


func _show_main() -> void:
	main_panel.visible = true
	play_panel.visible = false
	controls_panel.visible = false


func _show_play() -> void:
	main_panel.visible = false
	play_panel.visible = true
	controls_panel.visible = false
	_build_slots()


func _show_controls() -> void:
	main_panel.visible = false
	play_panel.visible = false
	controls_panel.visible = true
	_build_controls()


func _build_slots() -> void:
	for c in slots_box.get_children():
		c.queue_free()
	for i in SaveManager.SLOT_COUNT:
		var row := HBoxContainer.new()
		var info := Label.new()
		info.text = "Slot %d: %s" % [i + 1, SaveManager.slot_summary(i)]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var play_btn := Button.new()
		play_btn.text = "Continue" if SaveManager.has_save(i) else "New Game"
		play_btn.pressed.connect(_on_slot_pressed.bind(i))
		row.add_child(play_btn)
		if SaveManager.has_save(i):
			var del_btn := Button.new()
			del_btn.text = "Delete"
			del_btn.pressed.connect(_start_delete.bind(i))
			row.add_child(del_btn)
		slots_box.add_child(row)


func _on_slot_pressed(slot: int) -> void:
	if SaveManager.has_save(slot):
		SaveManager.load_game(slot)
	else:
		SaveManager.new_game(slot)
	get_tree().change_scene_to_file("res://scenes/rooms/CursedCottage.tscn")


func _start_delete(slot: int) -> void:
	_show_confirm(
		"Are you sure you want to delete Slot %d?" % (slot + 1),
		true,
		_confirm_delete_again.bind(slot)
	)


func _confirm_delete_again(slot: int) -> void:
	_show_confirm("Are you really sure?", false, _do_delete.bind(slot))


func _do_delete(slot: int) -> void:
	SaveManager.delete_save(slot)
	_build_slots()


func _show_confirm(message: String, yes_first: bool, on_yes: Callable) -> void:
	if _confirm_layer:
		_confirm_layer.queue_free()
	_confirm_layer = Control.new()
	_confirm_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var yes := Button.new()
	yes.text = "Yes"
	yes.add_theme_color_override("font_color", Color(0.15, 0.85, 0.35))
	yes.add_theme_color_override("font_hover_color", Color(0.3, 1.0, 0.45))
	var no := Button.new()
	no.text = "No"
	no.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	no.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.4))

	# First dialog: Yes then No. Second ("really sure"): buttons reversed.
	if yes_first:
		row.add_child(yes)
		row.add_child(no)
	else:
		row.add_child(no)
		row.add_child(yes)

	yes.pressed.connect(func() -> void:
		_confirm_layer.queue_free()
		_confirm_layer = null
		on_yes.call()
	)
	no.pressed.connect(func() -> void:
		_confirm_layer.queue_free()
		_confirm_layer = null
	)
	add_child(_confirm_layer)


func _build_controls() -> void:
	for c in controls_list.get_children():
		c.queue_free()
	for action in InputMapManager.ACTIONS:
		var row := HBoxContainer.new()
		var name_l := Label.new()
		name_l.text = InputMapManager.get_action_display(action)
		name_l.custom_minimum_size.x = 160
		row.add_child(name_l)
		var key_btn := Button.new()
		key_btn.text = InputMapManager.get_binding_text(action)
		key_btn.pressed.connect(_on_rebind.bind(action, key_btn))
		row.add_child(key_btn)
		controls_list.add_child(row)


func _on_rebind(action: String, btn: Button) -> void:
	btn.text = "Press a key…"
	InputMapManager.begin_rebind(action)
	await InputMapManager.bindings_changed
	btn.text = InputMapManager.get_binding_text(action)


func _on_play_pressed() -> void:
	_show_play()


func _on_controls_pressed() -> void:
	_show_controls()


func _on_back_pressed() -> void:
	_show_main()


func _on_reset_controls() -> void:
	InputMapManager.reset_defaults()
