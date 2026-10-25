extends CanvasLayer
## Esc menu during play. Pauses in single player. Includes Controls rebind and Settings.

@onready var root: Control = $Root
@onready var main_box: VBoxContainer = $Root/Center/Main
@onready var controls_box: VBoxContainer = $Root/Center/Controls
@onready var controls_list: VBoxContainer = $Root/Center/Controls/List

var settings_box: SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	controls_box.visible = false
	settings_box = SettingsPanel.new("Back to Game")
	$Root/Center.add_child(settings_box)
	settings_box.closed.connect(close)
	InputMapManager.bindings_changed.connect(_build_controls)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if root.visible and controls_box.visible:
			_show_main()
			get_viewport().set_input_as_handled()
			return
		if root.visible and settings_box.visible:
			settings_box.cancel()  # Esc backs out to the pause menu, not the game.
			_show_main()
			get_viewport().set_input_as_handled()
			return
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if root.visible:
		close()
	else:
		open()


func open() -> void:
	root.visible = true
	_show_main()
	GameState.set_paused(true)


func close() -> void:
	root.visible = false
	InputMapManager.cancel_rebind()
	GameState.set_paused(false)


func _show_main() -> void:
	main_box.visible = true
	controls_box.visible = false
	settings_box.visible = false


func _show_controls() -> void:
	main_box.visible = false
	controls_box.visible = true
	_build_controls()


func _show_settings() -> void:
	main_box.visible = false
	settings_box.open()


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
		key_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		key_btn.pressed.connect(_on_rebind.bind(action, key_btn))
		row.add_child(key_btn)
		controls_list.add_child(row)


func _on_rebind(action: String, btn: Button) -> void:
	btn.text = "Press a key…"
	InputMapManager.begin_rebind(action)
	await InputMapManager.bindings_changed
	btn.text = InputMapManager.get_binding_text(action)


func _on_resume() -> void:
	close()


func _on_controls() -> void:
	_show_controls()


func _on_settings() -> void:
	_show_settings()


func _on_back() -> void:
	_show_main()


func _on_title() -> void:
	SaveManager.autosave()
	close()
	get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
