extends Area2D
class_name NPC
## Interactable villager — press attack (F) nearby to talk.


@export var npc_name: String = "Villager"
@export var lines: PackedStringArray = PackedStringArray(["…"])

var _prompt: Label
var _bubble: Label
var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_build()
	add_to_group("npcs")


func _build() -> void:
	var body := Polygon2D.new()
	body.color = Color(0.25, 0.22, 0.28)
	body.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(10, 0), Vector2(8, -28), Vector2(0, -36), Vector2(-8, -28)
	])
	add_child(body)
	var head := Polygon2D.new()
	head.color = Color(0.55, 0.5, 0.48)
	head.polygon = PackedVector2Array([
		Vector2(-7, -36), Vector2(7, -36), Vector2(7, -48), Vector2(-7, -48)
	])
	add_child(head)
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	cs.shape = circle
	cs.position = Vector2(0, -20)
	add_child(cs)
	_prompt = Label.new()
	_prompt.text = "F — Talk"
	_prompt.position = Vector2(-28, -70)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	_prompt.visible = false
	add_child(_prompt)
	_bubble = Label.new()
	_bubble.position = Vector2(-80, -100)
	_bubble.custom_minimum_size = Vector2(160, 40)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_theme_font_size_override("font_size", 13)
	_bubble.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_bubble.visible = false
	add_child(_bubble)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 48.0
	_prompt.visible = near and not _bubble.visible
	if near and Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_talk()


func _talk() -> void:
	_cooldown = 0.4
	_bubble.text = "%s: %s" % [npc_name, lines[randi() % lines.size()]]
	_bubble.visible = true
	await get_tree().create_timer(2.8).timeout
	if is_instance_valid(_bubble):
		_bubble.visible = false
