extends Area2D
class_name TowerVillageDoor
## Lobby door back to Lantern Village.


var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 90)
	cs.shape = rect
	cs.position = Vector2(0, -30)
	add_child(cs)
	var door := Polygon2D.new()
	door.color = Color(0.12, 0.1, 0.08)
	door.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0), Vector2(16, -48), Vector2(-16, -48)
	])
	add_child(door)
	_prompt = Label.new()
	_prompt.text = "F — Village"
	_prompt.position = Vector2(-40, -70)
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55))
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 70.0
	_prompt.visible = near
	if near and Input.is_action_just_pressed("attack") and GameState.can_interact():
		GameState.current_zone_id = "lantern_village"
		GameState.change_zone(
			"res://scenes/rooms/LanternVillage.tscn",
			"Back to Lantern Village…",
			Vector2(3000, 460)
		)
