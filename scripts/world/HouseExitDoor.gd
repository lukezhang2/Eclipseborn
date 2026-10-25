extends Interactable
class_name HouseExitDoor
## Door on the left wall of a house interior — Interact to return to Lantern Village.


func _ready() -> void:
	verb = "Leave"
	interact_range = 56.0
	prompt_offset = Vector2(-36, -62)
	_build_visual()
	super._ready()


func _build_visual() -> void:
	var frame := Polygon2D.new()
	frame.color = Color(0.18, 0.12, 0.08)
	frame.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(22, 0), Vector2(20, -52), Vector2(-20, -52)
	])
	add_child(frame)
	var door := Polygon2D.new()
	door.color = Color(0.08, 0.06, 0.05)
	door.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(14, -46), Vector2(-14, -46)
	])
	add_child(door)
	var glow := Polygon2D.new()
	glow.color = Color(0.55, 0.45, 0.25, 0.4)
	glow.polygon = PackedVector2Array([
		Vector2(-10, -4), Vector2(10, -4), Vector2(9, -40), Vector2(-9, -40)
	])
	add_child(glow)
	var knob := Polygon2D.new()
	knob.color = Color(0.75, 0.65, 0.35)
	knob.polygon = PackedVector2Array([
		Vector2(6, -22), Vector2(10, -22), Vector2(10, -18), Vector2(6, -18)
	])
	add_child(knob)


func interact() -> void:
	var parent := get_parent()
	var spawn := Vector2(520, 460)
	if parent and "return_spawn" in parent:
		spawn = parent.return_spawn
	GameState.pending_spawn = spawn
	GameState.current_zone_id = "lantern_village"
	GameState.last_position = spawn
	get_tree().change_scene_to_file("res://scenes/rooms/LanternVillage.tscn")
