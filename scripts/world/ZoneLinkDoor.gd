extends Interactable
class_name ZoneLinkDoor
## Zone travel door (editor `prop_exit`) — Interact / walk-into to change zones.


@export var target_zone: String = "lantern_village"
@export var spawn_pos: Vector2 = Vector2(520, 460)
@export var travel_caption: String = ""
@export var show_exit_arrow: bool = true

var _walk_armed: bool = false
var _player_inside: bool = false


func _ready() -> void:
	if verb == "" or verb == "Interact":
		verb = "Leave" if target_zone != "" else "Enter"
	interact_range = 96.0
	prompt_offset = Vector2(-40, -70)
	_build_visual()
	super._ready()
	var area := Area2D.new()
	area.name = "WalkExit"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 70)
	cs.shape = rect
	cs.position = Vector2(0, -30)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_walk_enter)
	area.body_exited.connect(_on_walk_exit)
	call_deferred("_boot_guard")


func _boot_guard() -> void:
	await get_tree().create_timer(0.9).timeout
	if not _player_inside:
		_walk_armed = true


func _build_visual() -> void:
	var frame := Polygon2D.new()
	frame.color = Color(0.18, 0.12, 0.08)
	frame.polygon = PackedVector2Array([
		Vector2(-24, 0), Vector2(24, 0), Vector2(22, -58), Vector2(-22, -58)
	])
	add_child(frame)
	var door := Polygon2D.new()
	door.color = Color(0.08, 0.06, 0.05)
	door.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0), Vector2(16, -52), Vector2(-16, -52)
	])
	add_child(door)
	var glow := Polygon2D.new()
	glow.color = Color(0.55, 0.45, 0.25, 0.45)
	glow.polygon = PackedVector2Array([
		Vector2(-12, -4), Vector2(12, -4), Vector2(11, -46), Vector2(-11, -46)
	])
	add_child(glow)
	var knob := Polygon2D.new()
	knob.color = Color(0.75, 0.65, 0.35)
	knob.polygon = PackedVector2Array([
		Vector2(8, -26), Vector2(12, -26), Vector2(12, -22), Vector2(8, -22)
	])
	add_child(knob)
	if show_exit_arrow:
		var arrow := Label.new()
		arrow.text = "← EXIT"
		arrow.position = Vector2(-28, -78)
		arrow.add_theme_font_size_override("font_size", 14)
		arrow.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
		add_child(arrow)


func _on_walk_enter(body: Node) -> void:
	if not (body is Player or (body and body.is_in_group("player"))):
		return
	_player_inside = true
	if _walk_armed and GameState.can_interact():
		interact()


func _on_walk_exit(body: Node) -> void:
	if body is Player or (body and body.is_in_group("player")):
		_player_inside = false
		_walk_armed = true


func interact() -> void:
	if not GameState.can_interact():
		return
	var zone := target_zone.strip_edges()
	if zone == "":
		zone = "lantern_village"
	var scene := SaveManager.scene_for_zone(zone)
	var caption := travel_caption.strip_edges()
	if caption == "":
		caption = "Traveling…"
	GameState.current_zone_id = zone
	GameState.pending_spawn = spawn_pos
	GameState.last_position = spawn_pos
	GameState.lock_interact(1.25)
	ZoneTransition.go(get_tree(), scene, caption)
