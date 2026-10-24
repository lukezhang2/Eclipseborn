extends Area2D
## Door back to Lantern Village from a house interior.


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 48.0
	var prompt: Label = get_meta("prompt") if has_meta("prompt") else null
	if prompt:
		prompt.visible = near
	if near and Input.is_action_just_pressed("attack"):
		_leave()


func _leave() -> void:
	var parent := get_parent()
	var spawn := Vector2(520, 460)
	if parent and "return_spawn" in parent:
		spawn = parent.return_spawn
	GameState.pending_spawn = spawn
	GameState.current_zone_id = "lantern_village"
	GameState.last_position = spawn
	get_tree().change_scene_to_file("res://scenes/rooms/LanternVillage.tscn")
