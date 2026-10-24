extends CanvasLayer
## Hold J + K + L + ; together to show hurtboxes (green), hitboxes (red), body (blue).


var _on: bool = false
var _draw: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_draw = Node2D.new()
	_draw.set_script(preload("res://scripts/ui/HitboxDebugDraw.gd"))
	_draw.z_index = 100
	_draw.top_level = true
	add_child(_draw)


func _process(_delta: float) -> void:
	_on = (
		Input.is_physical_key_pressed(KEY_J)
		and Input.is_physical_key_pressed(KEY_K)
		and Input.is_physical_key_pressed(KEY_L)
		and Input.is_physical_key_pressed(KEY_SEMICOLON)
	)
	_draw.visible = _on
	if _on:
		_draw.queue_redraw()
