extends Area2D
class_name ClockworkTower
## Village exterior — enter the Clockwork Tower climb zone.


@export var tower_width: float = 160.0
@export var tower_height: float = 280.0

var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_build()
	body_entered.connect(_on_body)
	add_to_group("clockwork_tower")


func _build() -> void:
	var hx := tower_width * 0.5
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = Vector2(0, -tower_height * 0.5)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tower_width * 0.55, tower_height)
	cs.shape = rect
	wall.add_child(cs)
	add_child(wall)

	# The visible complex is much bigger than the collision column; it runs off the top of the screen.
	# Mirrored so the entrance is on the LEFT and the factory wing on the right.
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.TOWER
	art.scale = Vector2(-1, 1)
	art.z_index = -7
	add_child(art)

	var sense := CollisionShape2D.new()
	var sense_r := RectangleShape2D.new()
	sense_r.size = Vector2(80, 60)
	sense.shape = sense_r
	sense.position = Vector2(0, -20)
	add_child(sense)

	_prompt = Label.new()
	_prompt.position = Vector2(0, -130)
	_prompt.visible = false
	add_child(_prompt)
	UITheme.style_prompt(_prompt)
	UITheme.set_prompt_text(_prompt, "F — Ascend")


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 70.0
	_prompt.visible = near
	if near and Input.is_action_just_pressed("attack") and GameState.can_interact():
		_ascend()


func _on_body(_body: Node) -> void:
	pass


func _ascend() -> void:
	AudioManager.play_break()
	GameState.current_zone_id = "clockwork_tower"
	## Bottom-left lobby spawn (door side), not center.
	GameState.change_zone(
		"res://scenes/rooms/ClockworkTower.tscn",
		"Ascending the Clockwork Tower…",
		Vector2(140, 2620)
	)
