extends Node
## Hold J + K + L + ; together to show real hurtboxes (green), hitboxes (red), body (blue).


var _on: bool = false
var _draw: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# World-space drawer so shapes line up with the actual CollisionShape2Ds.
	_draw = Node2D.new()
	_draw.name = "HitboxDebugDraw"
	_draw.set_script(preload("res://scripts/ui/HitboxDebugDraw.gd"))
	_draw.z_index = 100
	_draw.visible = false
	call_deferred("_attach_draw")


func _attach_draw() -> void:
	var host := get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_draw)


func _process(_delta: float) -> void:
	_on = (
		Input.is_physical_key_pressed(KEY_J)
		and Input.is_physical_key_pressed(KEY_K)
		and Input.is_physical_key_pressed(KEY_L)
		and Input.is_physical_key_pressed(KEY_SEMICOLON)
	)
	if _draw == null or not is_instance_valid(_draw):
		return
	# Re-parent if scene changed (zone transition).
	if _draw.get_parent() != get_tree().current_scene and get_tree().current_scene:
		_draw.reparent(get_tree().current_scene)
	_draw.set("_debug_on", _on)
	_draw.visible = _on
	if _on:
		_draw.queue_redraw()
