extends Node
## Watches for the Lamplighter node to leave the tree (legacy hook — DJ moved to tower).


func _ready() -> void:
	var boss := get_parent().get_node_or_null("Lamplighter")
	if boss == null:
		return
	boss.tree_exiting.connect(_on_gone)


func _on_gone() -> void:
	## Ability unlock is no longer here; keep a quiet toast if somehow still used.
	pass
