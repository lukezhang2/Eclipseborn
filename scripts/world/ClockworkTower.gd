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

	var body := Polygon2D.new()
	body.color = Color(0.22, 0.2, 0.24)
	body.polygon = PackedVector2Array([
		Vector2(-hx * 0.7, 0), Vector2(hx * 0.7, 0),
		Vector2(hx * 0.55, -tower_height), Vector2(-hx * 0.55, -tower_height)
	])
	add_child(body)
	var peak := Polygon2D.new()
	peak.color = Color(0.35, 0.28, 0.2)
	peak.polygon = PackedVector2Array([
		Vector2(-hx * 0.6, -tower_height), Vector2(hx * 0.6, -tower_height),
		Vector2(0, -tower_height - 48)
	])
	add_child(peak)
	var face := Polygon2D.new()
	face.position = Vector2(0, -tower_height * 0.55)
	face.color = Color(0.55, 0.5, 0.4)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 28.0)
	face.polygon = pts
	add_child(face)
	var hand := Line2D.new()
	hand.width = 3.0
	hand.default_color = Color(0.15, 0.12, 0.1)
	hand.add_point(Vector2(0, -tower_height * 0.55))
	hand.add_point(Vector2(10, -tower_height * 0.55 - 18))
	add_child(hand)
	var door := Polygon2D.new()
	door.color = Color(0.08, 0.07, 0.09)
	door.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(14, -40), Vector2(-14, -40)
	])
	add_child(door)
	var glow := Polygon2D.new()
	glow.color = Color(0.7, 0.55, 0.25, 0.35)
	glow.polygon = PackedVector2Array([
		Vector2(-12, -4), Vector2(12, -4), Vector2(10, -36), Vector2(-10, -36)
	])
	add_child(glow)

	var sense := CollisionShape2D.new()
	var sense_r := RectangleShape2D.new()
	sense_r.size = Vector2(80, 60)
	sense.shape = sense_r
	sense.position = Vector2(0, -20)
	add_child(sense)

	_prompt = Label.new()
	_prompt.text = "F — Ascend"
	_prompt.position = Vector2(-48, -56)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.85, 0.65))
	_prompt.visible = false
	add_child(_prompt)


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
