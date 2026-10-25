extends Interactable
class_name Checkpoint
## Rest hearth — Interact to save + open fast travel between activated checkpoints.


@export var checkpoint_id: String = "default"
@export var checkpoint_name: String = "Rest"

var _ember: Polygon2D
var _lit: bool = false


func _ready() -> void:
	verb = "Rest"
	interact_range = 64.0
	prompt_offset = Vector2(-36, -58)
	if checkpoint_name == "Rest" and checkpoint_id != "" and checkpoint_id != "default":
		checkpoint_name = checkpoint_id.replace("_", " ").capitalize()
	_build_visual()
	super._ready()
	add_to_group("checkpoints")
	## Auto-activate on touch as well (legacy feel), but menu needs Interact.
	var area := Area2D.new()
	area.name = "Touch"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	cs.shape = circle
	cs.position = Vector2(0, -12)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_touch)


func _build_visual() -> void:
	var hearth := Polygon2D.new()
	hearth.polygon = PackedVector2Array([
		Vector2(-28, 0), Vector2(28, 0), Vector2(22, -18), Vector2(-22, -18)
	])
	hearth.color = Color(0.14, 0.11, 0.1)
	add_child(hearth)
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([
		Vector2(-24, -18), Vector2(24, -18), Vector2(18, -26), Vector2(-18, -26)
	])
	lip.color = Color(0.22, 0.18, 0.16)
	add_child(lip)
	_ember = Polygon2D.new()
	_ember.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(5, -16), Vector2(-5, -16)
	])
	_ember.color = Color(0.45, 0.22, 0.1, 0.55)
	add_child(_ember)
	var label := Label.new()
	label.text = checkpoint_name
	label.position = Vector2(-28, -48)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	add_child(label)


func _on_touch(body: Node) -> void:
	if body is Player or (body and body.is_in_group("player")):
		_activate(false)


func interact() -> void:
	_activate(true)


func _activate(open_travel: bool) -> void:
	GameState.activate_checkpoint(
		checkpoint_id,
		GameState.current_zone_id,
		global_position,
		checkpoint_name
	)
	_lit = true
	if _ember:
		_ember.color = Color(0.85, 0.45, 0.18, 0.95)
	if open_travel:
		_open_fast_travel()


func _open_fast_travel() -> void:
	var ui := get_tree().get_first_node_in_group("fast_travel_menu")
	if ui and ui.has_method("open_menu"):
		ui.open_menu()
		return
	## Fallback: spawn menu under GameUI if missing from scene.
	var menu := preload("res://scripts/ui/FastTravelMenu.gd").new()
	menu.name = "FastTravelMenu"
	var host := get_tree().get_first_node_in_group("game_ui")
	if host == null:
		host = get_tree().current_scene
	host.add_child(menu)
	menu.add_to_group("fast_travel_menu")
	menu.open_menu()
