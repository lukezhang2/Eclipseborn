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
## WorldArt house style; -1 picks one of the timber designs from house_id so the village mixes.
@export var art_style: int = -1

const TIMBER_STYLES := [2, 6, 9]
## Known village houses each get their own timber design: workshop (C), jettied (C1), clockmaker (C4).
const HOUSE_STYLES := {"house_gear": 2, "house_keep": 6, "house_inn": 9}

var _prompt: Label


func _ready() -> void:
	z_index = -6
	_build()
	add_to_group("houses")


func _build() -> void:
	var hx := width * 0.5
	var art := WorldArt.new()
	art.kind = WorldArt.Kind.HOUSE
	art.style = art_style if art_style >= 0 else _pick_style()
	art.size = Vector2(width, height)
	add_child(art)

	_apply_light_block(hx)

	_prompt = Label.new()
	_prompt.position = Vector2(-70, -48)
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.86, 0.7))
	_prompt.visible = false
	add_child(_prompt)


func _pick_style() -> int:
	if HOUSE_STYLES.has(house_id):
		return HOUSE_STYLES[house_id]
	return TIMBER_STYLES[absi(hash(house_id)) % TIMBER_STYLES.size()]


func set_blocks_light(on: bool) -> void:
	blocks_light = on
	var hx := width * 0.5
	_apply_light_block(hx)


func _apply_light_block(_hx: float) -> void:
	## Silhouette of the drawn house (walls + roof) — geometry occluder drives burns AND wash cuts.
	var style := art_style if art_style >= 0 else _pick_style()
	LightOnlyBlocker.attach(self, WorldArt.house_silhouette(style, width, height), blocks_light)


func _process(_delta: float) -> void:
	var p = GameState.player
	var near := p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 42.0
	_prompt.visible = near and GameState.can_interact()
	if not near:
		return
	_prompt.text = "%s — Enter %s" % [InputMapManager.get_slot_text("interact", 0), house_name]
	if GameState.can_interact() and Input.is_action_just_pressed("interact"):
		_enter()


func _enter() -> void:
	if not GameState.can_interact():
		return
	GameState.set_meta("pending_house_id", house_id)
	## Land near the left exit, but not overlapping the walk-exit pad.
	GameState.pending_spawn = Vector2(160, 460)
	GameState.current_zone_id = house_id
	GameState.last_position = GameState.pending_spawn
	GameState.lock_interact(1.25)
	var title := house_name if house_name != "" else "the house"
	ZoneTransition.go(get_tree(), interior_scene, "Entering %s…" % title)
