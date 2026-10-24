extends CanvasLayer

@onready var label: Label = $Root/Label

var _timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("tutorial_hint")
	label.visible = false


func show_hint(text: String, duration: float = 3.0) -> void:
	label.text = text
	label.visible = true
	_timer = duration


func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			label.visible = false
