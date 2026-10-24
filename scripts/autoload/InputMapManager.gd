extends Node
## Rebindable controls. Defaults match the plan. Two actions cannot share a key.

const ACTIONS := [
	"move_left",
	"move_right",
	"run",
	"jump",
	"attack",
	"zone_map",
	"menu",
]

const DISPLAY_NAMES := {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"run": "Run",
	"jump": "Jump",
	"attack": "Attack",
	"zone_map": "Zone Map",
	"menu": "Menu",
}

const SAVE_PATH := "user://controls.cfg"

signal bindings_changed

var _listening_action: String = ""


func _ready() -> void:
	_ensure_defaults()
	load_bindings()


func _ensure_defaults() -> void:
	# project.godot already defines defaults; this is a safety net.
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func get_action_display(action: String) -> String:
	return DISPLAY_NAMES.get(action, action)


func get_binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "(unbound)"
	return _event_to_text(events[0])


func begin_rebind(action: String) -> void:
	_listening_action = action


func cancel_rebind() -> void:
	_listening_action = ""


func is_listening() -> bool:
	return _listening_action != ""


func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_ESCAPE and _listening_action != "menu":
			cancel_rebind()
			get_viewport().set_input_as_handled()
			return
		_apply_rebind(_listening_action, key_event)
		_listening_action = ""
		get_viewport().set_input_as_handled()


func _apply_rebind(action: String, key_event: InputEventKey) -> void:
	# Remove this key from any other action (no shared keys).
	for other in ACTIONS:
		if other == action:
			continue
		var cleaned: Array[InputEvent] = []
		for ev in InputMap.action_get_events(other):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == key_event.physical_keycode:
				continue
			cleaned.append(ev)
		InputMap.action_erase_events(other)
		for ev in cleaned:
			InputMap.action_add_event(other, ev)

	InputMap.action_erase_events(action)
	var stored := InputEventKey.new()
	stored.physical_keycode = key_event.physical_keycode
	InputMap.action_add_event(action, stored)
	save_bindings()
	bindings_changed.emit()


func reset_defaults() -> void:
	_set_key("move_left", KEY_A)
	_set_key("move_right", KEY_D)
	_set_key("run", KEY_SHIFT)
	_set_key("jump", KEY_SPACE)
	_set_key("attack", KEY_F)
	_set_key("zone_map", KEY_TAB)
	_set_key("menu", KEY_ESCAPE)
	# Also keep arrows for move.
	var left_arrow := InputEventKey.new()
	left_arrow.physical_keycode = KEY_LEFT
	InputMap.action_add_event("move_left", left_arrow)
	var right_arrow := InputEventKey.new()
	right_arrow.physical_keycode = KEY_RIGHT
	InputMap.action_add_event("move_right", right_arrow)
	save_bindings()
	bindings_changed.emit()


func _set_key(action: String, keycode: Key) -> void:
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in ACTIONS:
		var codes: PackedInt32Array = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				codes.append((ev as InputEventKey).physical_keycode)
		cfg.set_value("bindings", action, codes)
	cfg.save(SAVE_PATH)


func load_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in ACTIONS:
		if not cfg.has_section_key("bindings", action):
			continue
		var codes: PackedInt32Array = cfg.get_value("bindings", action)
		InputMap.action_erase_events(action)
		for code in codes:
			var ev := InputEventKey.new()
			ev.physical_keycode = code as Key
			InputMap.action_add_event(action, ev)
	bindings_changed.emit()


func _event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		return OS.get_keycode_string(k.physical_keycode)
	return str(event)
