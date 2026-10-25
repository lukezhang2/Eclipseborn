extends Node

const EditorScript := preload("res://scripts/editor/LevelEditor.gd")


func _ready() -> void:
	var ed: Control = EditorScript.new()
	add_child(ed)
	await get_tree().process_frame
	var spin: SpinBox = ed._intensity_spin
	print("focus conns ", spin.get_line_edit().focus_exited.get_connections().size())
	ed._syncing_light = true
	spin.value = 2.0
	ed._syncing_light = false
	spin.get_line_edit().grab_focus()
	await get_tree().process_frame
	spin.get_line_edit().text = "0.75"
	spin.get_line_edit().release_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	print("after blur value ", spin.value, " text ", spin.get_line_edit().text)
	spin.get_line_edit().text = "1.25"
	spin.apply()
	print("after enter value ", spin.value, " text ", spin.get_line_edit().text)
	## Selecting another light must not copy the draft text.
	var a := EditorPiece.new()
	var b := EditorPiece.new()
	ed._world.add_child(a)
	ed._world.add_child(b)
	a.apply_dict({"id": "lantern_a", "name": "A", "kind": "light", "x": 0, "y": 0, "w": 28, "h": 36, "radius": 280, "intensity": 2.0})
	b.apply_dict({"id": "lantern_b", "name": "B", "kind": "light", "x": 80, "y": 0, "w": 28, "h": 36, "radius": 100, "intensity": 0.5})
	ed._pieces.append(a)
	ed._pieces.append(b)
	ed._select(a)
	spin.get_line_edit().grab_focus()
	await get_tree().process_frame
	spin.get_line_edit().text = "2.75"
	ed._select(b)
	spin.get_line_edit().release_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	print("A ", a.light_intensity, " B ", b.light_intensity, " spin ", spin.value, " text ", spin.get_line_edit().text)
	get_tree().quit()
