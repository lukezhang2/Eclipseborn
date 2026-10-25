extends Area2D
class_name NPC
## Interactable villager / shopkeeper. Shopkeepers open the buy GUI; others talk.


@export var npc_name: String = "Villager"
@export var lines: PackedStringArray = PackedStringArray(["…"])
@export var is_shopkeeper: bool = false
## Array of {id, stock} — stock −1 = infinite. Empty + shopkeeper → catalog defaults.
@export var shop_items: Array = []

var shop_key: String = ""
var _prompt: Label
var _bubble: Label
var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	if shop_key == "" and has_meta("catalog_id"):
		shop_key = "%s/%s" % [GameState.current_zone_id, str(get_meta("catalog_id"))]
	elif shop_key == "":
		shop_key = "%s/%s" % [GameState.current_zone_id, npc_name.to_snake_case()]
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
	_prompt.position = Vector2(-36, -58)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	_prompt.visible = false
	add_child(_prompt)
	_bubble = Label.new()
	_bubble.position = Vector2(-80, -92)
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
	var shop_open := _is_shop_open()
	if near and not shop_open and (not _bubble.visible or is_shopkeeper):
		_prompt.text = "%s — %s" % [
			InputMapManager.get_slot_text("interact", 0),
			"Shop" if is_shopkeeper else "Talk",
		]
		_prompt.visible = true
	else:
		_prompt.visible = false
	if near and GameState.can_interact() and Input.is_action_just_pressed("interact") and _cooldown <= 0.0:
		if is_shopkeeper:
			_open_shop()
		else:
			_talk()


func _is_shop_open() -> bool:
	var ui := get_tree().get_first_node_in_group("shop_menu")
	return ui != null and ui.get("root") != null and bool(ui.root.visible)


func _open_shop() -> void:
	_cooldown = 0.35
	_bubble.visible = false
	var items := shop_items
	if items.is_empty():
		items = ShopCatalog.default_shop_stock()
	var ui := get_tree().get_first_node_in_group("shop_menu")
	if ui and ui.has_method("open_shop"):
		ui.open_shop(npc_name, shop_key, items)
		return
	var menu := preload("res://scripts/ui/ShopMenu.gd").new()
	menu.name = "ShopMenu"
	var host := get_tree().get_first_node_in_group("game_ui")
	if host == null:
		host = get_tree().current_scene
	host.add_child(menu)
	menu.open_shop(npc_name, shop_key, items)


func _talk() -> void:
	_cooldown = 0.4
	var line := "…"
	if lines.size() > 0:
		line = lines[randi() % lines.size()]
	_bubble.text = "%s: %s" % [npc_name, line]
	_bubble.visible = true
	await get_tree().create_timer(2.8).timeout
	if is_instance_valid(_bubble):
		_bubble.visible = false
