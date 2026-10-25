extends Interactable
class_name Checkpoint
## Rest hearth — Interact to save + open fast travel between activated checkpoints.
## Tall touch volume so a jump arc cannot skip activation.


@export var checkpoint_id: String = "default"
@export var checkpoint_name: String = "Rest"

## Generous pad: wide + tall so jump arcs still hit.
const TOUCH_W := 120.0
const TOUCH_H := 140.0

var _art: WorldArt
var _lit: bool = false
var _touching: bool = false


func _ready() -> void:
	verb = "Rest"
	## Wide interact so the prompt is easy while near / above the hearth.
	interact_range = 96.0
	prompt_offset = Vector2(0, -118)
	if checkpoint_name == "Rest" and checkpoint_id != "" and checkpoint_id != "default":
		checkpoint_name = checkpoint_id.replace("_", " ").capitalize()
	_build_visual()
	super._ready()
	add_to_group("checkpoints")
	_build_touch()
	## Restore lit look from a prior save.
	call_deferred("_restore_from_save")


func _build_touch() -> void:
	var area := Area2D.new()
	area.name = "Touch"
	area.collision_layer = 0
	area.collision_mask = 2 ## Player body layer
	area.monitoring = true
	area.monitorable = false
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TOUCH_W, TOUCH_H)
	cs.shape = rect
	## Origin is floor; pad rises well above jump height and a bit below feet.
	cs.position = Vector2(0, -TOUCH_H * 0.5 + 8.0)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_touch_enter)
	area.body_exited.connect(_on_touch_exit)


func _build_visual() -> void:
	# Two short snuffed lamp posts with a steel bench; their ink flames brighten when lit.
	_art = WorldArt.new()
	_art.kind = WorldArt.Kind.CHECKPOINT
	_art.style = 6
	_art.on = _lit
	add_child(_art)
	var label := Label.new()
	label.text = checkpoint_name
	# Brass caption centered over the posts; the "E — Rest" plaque sits above it.
	label.add_theme_font_override("font", load(UITheme.PROMPT_FONT))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UITheme.BRASS_LIGHT)
	label.add_theme_color_override("font_outline_color", UITheme.COAL)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	label.reset_size()
	label.position = Vector2(-label.size.x * 0.5, -80)


func _restore_from_save() -> void:
	if GameState.is_checkpoint_activated(checkpoint_id, GameState.current_zone_id):
		_set_lit(true)


func _physics_process(_delta: float) -> void:
	## Backup for fast jump arcs that can skip Area2D body_entered.
	var p = GameState.player
	if p == null or not is_instance_valid(p):
		return
	var d: Vector2 = (p as Node2D).global_position - global_position
	if absf(d.x) <= TOUCH_W * 0.5 and d.y <= 24.0 and d.y >= -TOUCH_H:
		if not _touching:
			_touching = true
			_activate(false)


func _on_touch_enter(body: Node) -> void:
	if body is Player or (body and body.is_in_group("player")):
		_touching = true
		_activate(false)


func _on_touch_exit(body: Node) -> void:
	if body is Player or (body and body.is_in_group("player")):
		_touching = false


func interact() -> void:
	_activate(true)


func _activate(open_travel: bool) -> void:
	GameState.activate_checkpoint(
		checkpoint_id,
		GameState.current_zone_id,
		global_position,
		checkpoint_name
	)
	_set_lit(true)
	if open_travel:
		_open_fast_travel()


func _set_lit(on: bool) -> void:
	_lit = on
	if _art:
		_art.on = on


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
