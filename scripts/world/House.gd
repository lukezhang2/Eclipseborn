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
## Where the player lands inside the house (editor spawn X/Y).
@export var interior_spawn: Vector2 = Vector2(160, 460)
@export var travel_caption: String = ""
## WorldArt house style; -1 picks one of the timber designs from house_id so the village mixes.
@export var art_style: int = -1

const TIMBER_STYLES := [2, 6, 9]
## Known village houses each get their own timber design: workshop (C), jettied (C1), clockmaker (C4).
const HOUSE_STYLES := {"house_gear": 2, "house_keep": 6, "house_inn": 9}

var _prompt: Label


func _ready() -> void:
	## Above lantern washes (−3) so light does not paint through the facade.
	z_index = -1
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
	_prompt.position = Vector2(0, -60)
	_prompt.visible = false
	add_child(_prompt)
	UITheme.style_prompt(_prompt)


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
	UITheme.set_prompt_text(_prompt, "%s — Enter %s" % [InputMapManager.get_slot_text("interact", 0), house_name])
	if GameState.can_interact() and Input.is_action_just_pressed("interact"):
		_enter()


func _enter() -> void:
	if not GameState.can_interact() or GameState.is_dead:
		return
	var zone := house_id if house_id != "" else "house_keep"
	GameState.set_meta("pending_house_id", zone)
	## Land near the left exit, but not overlapping the walk-exit pad.
	GameState.pending_spawn = interior_spawn
	GameState.current_zone_id = zone
	GameState.last_position = GameState.pending_spawn
	var title := house_name if house_name != "" else "the house"
	var caption := travel_caption.strip_edges()
	if caption == "":
		caption = "Entering %s…" % title
	var scene := interior_scene
	if scene == "" or scene == "res://scenes/rooms/HouseInterior.tscn":
		scene = SaveManager.scene_for_zone(zone)
	GameState.change_zone(scene, caption, interior_spawn)
