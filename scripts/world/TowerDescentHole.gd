extends Area2D
class_name TowerDescentHole
## Opens in the village after the Wickwright falls — descend into the tower shaft.


var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_build()


func _build() -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 50)
	cs.shape = rect
	cs.position = Vector2(0, -10)
	add_child(cs)

	var pit := Polygon2D.new()
	pit.color = Color(0.04, 0.03, 0.05)
	pit.polygon = PackedVector2Array([
		Vector2(-40, 8), Vector2(40, 8), Vector2(28, -18), Vector2(-28, -18)
	])
	add_child(pit)
	var rim := Polygon2D.new()
	rim.color = Color(0.35, 0.28, 0.2)
	rim.polygon = PackedVector2Array([
		Vector2(-44, 10), Vector2(44, 10), Vector2(40, 4), Vector2(-40, 4)
	])
	add_child(rim)
	var rubble := Polygon2D.new()
	rubble.color = Color(0.28, 0.24, 0.2)
	rubble.polygon = PackedVector2Array([
		Vector2(-50, 6), Vector2(-30, -4), Vector2(-22, 10)
	])
	add_child(rubble)

	_prompt = Label.new()
	_prompt.text = "F — Descend"
	_prompt.position = Vector2(-48, -48)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55))
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 70.0
	_prompt.visible = near
	if near and Input.is_action_just_pressed("attack") and GameState.can_interact():
		GameState.lock_interact()
		## Drop into the shaft mid-climb.
		GameState.pending_spawn = Vector2(390, 2100)
		GameState.current_zone_id = "clockwork_tower"
		get_tree().change_scene_to_file("res://scenes/rooms/ClockworkTower.tscn")
