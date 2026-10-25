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
	_prompt.visible = false
	add_child(_prompt)
	UITheme.style_prompt(_prompt)


func _process(_delta: float) -> void:
	var p = GameState.player
	## Prefer horizontal reach — floor props sit ~40px below the player origin.
	var near := false
	if p and is_instance_valid(p):
		var d: Vector2 = global_position - p.global_position
		near = absf(d.x) < interact_range and absf(d.y) < interact_range + 36.0
	_prompt.visible = near and GameState.can_interact()
	if not near:
		return
	# Read the binding each frame so a rebind in the pause menu shows up right away.
	UITheme.set_prompt_text(_prompt, "%s — %s" % [InputMapManager.get_slot_text("interact", 0), verb])
	if GameState.can_interact() and Input.is_action_just_pressed("interact"):
		interact()


## Override in subclasses.
func interact() -> void:
	pass
