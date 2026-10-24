extends "res://scripts/enemies/BasicEnemy.gd"
## First boss stub. Beating him unlocks double jump.


func _ready() -> void:
	max_hp = 120
	move_speed = 40.0
	attack_damage = 15
	attack_cooldown = 1.6
	super._ready()
	if visual:
		visual.color = Color(0.25, 0.18, 0.05)
		visual.scale = Vector2(1.6, 1.6)


func _die() -> void:
	GameState.unlock_ability("double_jump")
	var ui := get_tree().get_first_node_in_group("tutorial_hint")
	if ui and ui.has_method("show_hint"):
		ui.show_hint("Double Jump unlocked — press Jump again in the air")
	await super._die()
