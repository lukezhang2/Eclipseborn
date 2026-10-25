extends Node2D
class_name House
## Village house facade — F at the door loads a real interior zone.
## blocks_light: occludes lanterns without player collision.


@export var house_name: String = "House"
@export var house_id: String = "house_keep"
@export var width: float = 120.0
@export var height: float = 90.0
@export var blocks_light: bool = true
@export var interior_scene: String = "res://scenes/rooms/HouseInterior.tscn"

var _prompt: Label


func _ready() -> void:
	z_index = -6
	_build()
	add_to_group("houses")


func _build() -> void:
	var hx := width * 0.5
	var wall := Polygon2D.new()
	wall.color = Color(0.28, 0.22, 0.18)
	wall.polygon = PackedVector2Array([
		Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, -height), Vector2(-hx, -height)
	])
	add_child(wall)
	var roof := Polygon2D.new()
	roof.color = Color(0.35, 0.18, 0.14)
	roof.polygon = PackedVector2Array([
		Vector2(-hx - 8, -height), Vector2(hx + 8, -height), Vector2(0, -height - 36)
	])
	add_child(roof)
	var door := Polygon2D.new()
	door.color = Color(0.12, 0.08, 0.06)
	door.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(11, -32), Vector2(-11, -32)
	])
	add_child(door)
	var door_glow := Polygon2D.new()
	door_glow.color = Color(0.55, 0.45, 0.25, 0.35)
	door_glow.polygon = PackedVector2Array([
		Vector2(-8, -4), Vector2(8, -4), Vector2(7, -28), Vector2(-7, -28)
	])
	add_child(door_glow)
	var win := Polygon2D.new()
	win.color = Color(0.55, 0.6, 0.35, 0.5)
	win.polygon = PackedVector2Array([
		Vector2(-hx + 16, -height + 20), Vector2(-hx + 36, -height + 20),
		Vector2(-hx + 36, -height + 40), Vector2(-hx + 16, -height + 40)
	])
	add_child(win)

	_apply_light_block(hx)

	_prompt = Label.new()
	_prompt.text = "F — Enter %s" % house_name
	_prompt.position = Vector2(-70, -48)
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7))
	_prompt.visible = false
	add_child(_prompt)


func set_blocks_light(on: bool) -> void:
	blocks_light = on
	var hx := width * 0.5
	_apply_light_block(hx)


func _apply_light_block(hx: float) -> void:
	var poly := PackedVector2Array([
		Vector2(-hx - 8, 0), Vector2(hx + 8, 0), Vector2(hx + 8, -height),
		Vector2(0, -height - 36), Vector2(-hx - 8, -height)
	])
	LightOnlyBlocker.attach(self, poly, blocks_light)


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 42.0
	_prompt.visible = near
	if near and Input.is_action_just_pressed("attack"):
		_enter()


func _enter() -> void:
	GameState.set_meta("pending_house_id", house_id)
	GameState.pending_spawn = Vector2(120, 460)
	GameState.current_zone_id = house_id
	GameState.last_position = GameState.pending_spawn
	get_tree().change_scene_to_file(interior_scene)
