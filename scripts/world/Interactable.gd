extends Node2D
class_name Interactable
## Base for things the player uses with Interact (E by default): levers, switches, buttons.
## Subclasses set `verb` and override `interact()`. Call super() if you override _ready/_process.

@export var verb: String = "Use"
@export var interact_range: float = 48.0
@export var prompt_offset: Vector2 = Vector2(-28, -46)

var _prompt: Label


func _ready() -> void:
	_prompt = Label.new()
	_prompt.position = prompt_offset
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < interact_range
	_prompt.visible = near
	if not near:
		return
	# Read the binding each frame so a rebind in the pause menu shows up right away.
	_prompt.text = "%s — %s" % [InputMapManager.get_slot_text("interact", 0), verb]
	if Input.is_action_just_pressed("interact"):
		interact()


## Override in subclasses.
func interact() -> void:
	pass
