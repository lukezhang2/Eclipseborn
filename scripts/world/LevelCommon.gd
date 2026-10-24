extends Node2D
class_name LevelCommon
## Helpers to build steel-and-steam rooms: floors, walls, pipes, UI, shadow root.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const UI_SCENE := preload("res://scenes/ui/GameUI.tscn")


static func add_steel_floor(parent: Node2D, x: float, y: float, width: float, height: float = 32.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	body.add_child(cs)
	var visual := Polygon2D.new()
	var hx := width * 0.5
	var hy := height * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	visual.color = Color(0.28, 0.3, 0.33)
	body.add_child(visual)
	# Rivet dots
	var rivets := Polygon2D.new()
	rivets.color = Color(0.45, 0.35, 0.22)
	var pts := PackedVector2Array()
	for i in range(int(width / 40.0)):
		var rx := -hx + 20.0 + i * 40.0
		pts.append(Vector2(rx - 2, -4))
		pts.append(Vector2(rx + 2, -4))
		pts.append(Vector2(rx + 2, 0))
		pts.append(Vector2(rx - 2, 0))
	rivets.polygon = pts
	body.add_child(rivets)
	parent.add_child(body)
	return body


static func add_wall(parent: Node2D, x: float, y: float, width: float, height: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	cs.shape = rect
	body.add_child(cs)
	var visual := ColorRect.new()
	# ColorRect is Control — use Polygon2D instead for Node2D parent.
	var poly := Polygon2D.new()
	var hx := width * 0.5
	var hy := height * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	poly.color = Color(0.18, 0.16, 0.15)
	body.add_child(poly)
	parent.add_child(body)
	return body


static func add_pipe(parent: Node2D, from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 10.0
	line.default_color = Color(0.4, 0.38, 0.35)
	line.add_point(from)
	line.add_point(to)
	parent.add_child(line)
	var line2 := Line2D.new()
	line2.width = 4.0
	line2.default_color = Color(0.55, 0.5, 0.42)
	line2.add_point(from)
	line2.add_point(to)
	parent.add_child(line2)


static func add_backdrop(parent: Node2D, width: float, height: float) -> void:
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(0, -200), Vector2(width, -200), Vector2(width, height), Vector2(0, height)
	])
	bg.color = Color(0.07, 0.06, 0.07)
	bg.z_index = -20
	parent.add_child(bg)


static func spawn_player(parent: Node2D, pos: Vector2) -> Player:
	var p: Player = PLAYER_SCENE.instantiate()
	p.global_position = pos
	parent.add_child(p)
	GameState.set_checkpoint(pos)
	return p


static func spawn_ui(parent: Node) -> void:
	if parent.get_node_or_null("GameUI") != null:
		return
	parent.add_child(UI_SCENE.instantiate())


static func make_room_trigger(parent: Node2D, pos: Vector2, size: Vector2, zone: String, room: String, hint: String = "", action: String = "") -> void:
	var t := RoomTrigger.new()
	t.position = pos
	t.zone_id = zone
	t.room_id = room
	t.hint = hint
	t.hint_action = action
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	t.add_child(cs)
	parent.add_child(t)


static func make_shadow_root(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "ShadowRoot"
	parent.add_child(root)
	ShadowWorld.set_world_root(root)
	return root
