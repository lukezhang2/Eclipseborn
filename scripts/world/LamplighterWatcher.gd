extends Node
## Watches for the Lamplighter node to leave the tree, then unlocks double jump.


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	var boss := get_parent().get_node_or_null("Lamplighter")
	if boss == null and not GameState.has_double_jump:
		GameState.unlock_ability("double_jump")
		var ui := get_tree().get_first_node_in_group("tutorial_hint")
		if ui and ui.has_method("show_hint"):
			ui.show_hint("Double Jump unlocked — press Jump again in the air")
		queue_free()
