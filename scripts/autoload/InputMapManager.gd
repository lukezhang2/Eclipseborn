extends Node
## Rebindable controls with two slots per action. Keys cannot be shared across actions.

const MAX_SLOTS := 2

const ACTIONS := [
	"move_left",
	"move_right",
	"look_up",
	"look_down",
	"crouch",
	"pull",
	"interact",
	"run",
	"jump",
	"attack",
	"zone_map",
	"menu",
]

const DISPLAY_NAMES := {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"look_up": "Look Up",
	"look_down": "Look Down",
	"crouch": "Crouch",
	"pull": "Pull Box",
	"interact": "Interact",
	"run": "Run",
	"jump": "Jump",
	"attack": "Attack",
	"zone_map": "Zone Map",
	"menu": "Menu",
}

const SAVE_PATH := "user://controls.cfg"

signal bindings_changed

var _listening_action: String = ""
var _listening_slot: int = 0


func _ready() -> void:
	_ensure_defaults()
	load_bindings()
	_ensure_extra_actions()
	_cap_all_to_slots()


func _ensure_defaults() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _ensure_extra_actions() -> void:
	# S is crouch only — never look_down.
	_remove_key_from_action("look_down", KEY_S)
	if InputMap.action_get_events("look_up").is_empty():
		_set_slots("look_up", [KEY_W, KEY_UP])
	if InputMap.action_get_events("look_down").is_empty():
		_set_slots("look_down", [KEY_DOWN, KEY_NONE])
	if InputMap.action_get_events("crouch").is_empty():
		_set_slots("crouch", [KEY_S, KEY_NONE])
	if InputMap.action_get_events("pull").is_empty():
		_set_slots("pull", [KEY_V, KEY_NONE])
	# Saved controls from before Interact existed: give it E unless the player rebound E elsewhere.
	if InputMap.action_get_events("interact").is_empty() and not _key_in_use(KEY_E):
		_set_slots("interact", [KEY_E, KEY_NONE])
	# Ensure movement always has WASD + arrows when missing a slot.
	_ensure_slot_key("move_left", 0, KEY_A)
	_ensure_slot_key("move_left", 1, KEY_LEFT)
	_ensure_slot_key("move_right", 0, KEY_D)
	_ensure_slot_key("move_right", 1, KEY_RIGHT)
	_ensure_slot_key("look_up", 0, KEY_W)
	_ensure_slot_key("look_up", 1, KEY_UP)


func _ensure_slot_key(action: String, slot: int, keycode: Key) -> void:
	var events := InputMap.action_get_events(action)
	while events.size() < slot:
		events = InputMap.action_get_events(action)
		break
	if events.size() <= slot:
		_add_key(action, keycode)


func _cap_all_to_slots() -> void:
	for action in ACTIONS:
		var events := InputMap.action_get_events(action)
		if events.size() <= MAX_SLOTS:
			continue
		InputMap.action_erase_events(action)
		for i in MAX_SLOTS:
			InputMap.action_add_event(action, events[i])


func _key_in_use(keycode: Key) -> bool:
	for action in ACTIONS:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
				return true
	return false


func _remove_key_from_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	var kept: Array[InputEvent] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			continue
		kept.append(ev)
	InputMap.action_erase_events(action)
	for ev in kept:
		InputMap.action_add_event(action, ev)


func get_action_display(action: String) -> String:
	return DISPLAY_NAMES.get(action, action)


func get_binding_text(action: String) -> String:
	var parts: PackedStringArray = []
	for slot in MAX_SLOTS:
		parts.append(get_slot_text(action, slot))
	return " / ".join(parts)


func get_slot_text(action: String, slot: int) -> String:
	var events := InputMap.action_get_events(action)
	if slot < 0 or slot >= events.size():
		return "—"
	return _event_to_text(events[slot])


func begin_rebind(action: String, slot: int = 0) -> void:
	_listening_action = action
	_listening_slot = clampi(slot, 0, MAX_SLOTS - 1)


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
		_apply_rebind(_listening_action, _listening_slot, key_event)
		_listening_action = ""
		get_viewport().set_input_as_handled()


func _apply_rebind(action: String, slot: int, key_event: InputEventKey) -> void:
	# Strip this key from every other action.
	for other in ACTIONS:
		if other == action:
			continue
		_remove_key_from_action(other, key_event.physical_keycode)

	var events := InputMap.action_get_events(action)
	var codes: Array[int] = []
	for ev in events:
		if ev is InputEventKey:
			codes.append((ev as InputEventKey).physical_keycode)

	while codes.size() < MAX_SLOTS:
		codes.append(KEY_NONE)

	# Clear duplicate of this key in the same action's other slot.
	for i in codes.size():
		if i != slot and codes[i] == key_event.physical_keycode:
			codes[i] = KEY_NONE

	codes[slot] = key_event.physical_keycode
	_set_slots(action, codes)
	save_bindings()
	bindings_changed.emit()


func reset_defaults() -> void:
	_set_slots("move_left", [KEY_A, KEY_LEFT])
	_set_slots("move_right", [KEY_D, KEY_RIGHT])
	_set_slots("look_up", [KEY_W, KEY_UP])
	_set_slots("look_down", [KEY_DOWN, KEY_NONE])
	_set_slots("crouch", [KEY_S, KEY_NONE])
	_set_slots("pull", [KEY_V, KEY_NONE])
	_set_slots("interact", [KEY_E, KEY_NONE])
	_set_slots("run", [KEY_SHIFT, KEY_NONE])
	_set_slots("jump", [KEY_SPACE, KEY_NONE])
	_set_slots("attack", [KEY_F, KEY_NONE])
	_set_slots("zone_map", [KEY_TAB, KEY_NONE])
	_set_slots("menu", [KEY_ESCAPE, KEY_NONE])
	save_bindings()
	bindings_changed.emit()


func _set_slots(action: String, keycodes: Array) -> void:
	InputMap.action_erase_events(action)
	for code in keycodes:
		if int(code) == KEY_NONE or int(code) == 0:
			continue
		_add_key(action, code as Key)


func _set_key(action: String, keycode: Key) -> void:
	InputMap.action_erase_events(action)
	_add_key(action, keycode)


func _add_key(action: String, keycode: Key) -> void:
	if keycode == KEY_NONE:
		return
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
		while codes.size() < MAX_SLOTS:
			codes.append(KEY_NONE)
		if codes.size() > MAX_SLOTS:
			codes.resize(MAX_SLOTS)
		cfg.set_value("bindings", action, codes)
	cfg.save(SAVE_PATH)


func load_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		reset_defaults()
		return
	for action in ACTIONS:
		if not cfg.has_section_key("bindings", action):
			continue
		var codes: PackedInt32Array = cfg.get_value("bindings", action)
		InputMap.action_erase_events(action)
		var added := 0
		for code in codes:
			if added >= MAX_SLOTS:
				break
			if int(code) == KEY_NONE or int(code) == 0:
				continue
			var ev := InputEventKey.new()
			ev.physical_keycode = code as Key
			InputMap.action_add_event(action, ev)
			added += 1
	_ensure_extra_actions()
	bindings_changed.emit()


func _event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var code := (event as InputEventKey).physical_keycode
		if code == KEY_NONE or code == 0:
			return "—"
		return OS.get_keycode_string(code)
	return str(event)
