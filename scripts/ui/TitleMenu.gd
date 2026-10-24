extends Control

@onready var main_panel: VBoxContainer = $Center/Main
@onready var play_panel: VBoxContainer = $Center/PlaySlots
@onready var controls_panel: VBoxContainer = $Center/Controls
@onready var slots_box: VBoxContainer = $Center/PlaySlots/Slots
@onready var controls_list: VBoxContainer = $Center/Controls/List


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.set_paused(false)
	_show_main()
	_build_slots()
	_build_controls()
	InputMapManager.bindings_changed.connect(_build_controls)


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
		slots_box.add_child(row)


func _on_slot_pressed(slot: int) -> void:
	if SaveManager.has_save(slot):
		SaveManager.load_game(slot)
	else:
		SaveManager.new_game(slot)
	get_tree().change_scene_to_file("res://scenes/rooms/CursedCottage.tscn")


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
