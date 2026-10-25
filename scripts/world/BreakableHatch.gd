extends StaticBody2D
class_name BreakableHatch
## Floor hatch: break with F, then press S (crouch) while standing on it to enter the next zone.

signal broken

@export var hatch_size: Vector2 = Vector2(56, 18)
@export var next_scene: String = "res://scenes/rooms/LanternVillage.tscn"
@export var spawn_in_next: Vector2 = Vector2(140, 460)

var _broken: bool = false
var _hurtbox: Hurtbox
var _visual: Polygon2D
var _art: WorldArt
var _prompt: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("breakables")
	add_to_group("enterable_hatches")
	if GameState.is_broken("cottage_hatch"):
		_apply_broken(false)


func _build() -> void:
	var half := hatch_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)
	_visual = Polygon2D.new()
	_visual.polygon = poly
	# Invisible until broken; then it becomes the dark opening in the floor.
	_visual.color = Color(0, 0, 0, 0)
	add_child(_visual)
	# Brass cellar doors with a wheel lock; hidden once the hatch is broken open.
	_art = WorldArt.new()
	_art.kind = WorldArt.Kind.HATCH
	_art.style = 12
	_art.size = hatch_size
	add_child(_art)
	_snap_to_floor.call_deferred()
	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = hatch_size + Vector2(8, 20)
	hcs.shape = rect
	hcs.position = Vector2(0, -8)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)

	_prompt = Label.new()
	_prompt.text = ""
	_prompt.position = Vector2(-70, -36)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(0.92, 0.88, 0.7))
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	if not _broken:
		return
	var p = GameState.player
	if p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 48.0:
		_prompt.text = "Press S to enter"
		_prompt.visible = true
	else:
		_prompt.visible = false


func _on_hurt(_amount: int, _from: Node) -> void:
	if _broken:
		return
	_apply_broken(true)


## The raised hatch art stands on the floor surface below the hatch's collision box.
func _snap_to_floor() -> void:
	await get_tree().physics_frame
	if not is_instance_valid(self) or _art == null:
		return
	var d := WorldArt.floor_distance(self)
	if d >= 0.0:
		_art.position.y = d


func _apply_broken(persist: bool) -> void:
	_broken = true
	broken.emit()
	if persist:
		AudioManager.play_break()
		GameState.mark_broken("cottage_hatch")
		SaveManager.autosave()
	_visual.color = Color(0.12, 0.1, 0.09, 0.5)
	if _art:
		_art.visible = false
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_deferred("disabled", true)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)


func try_enter(player: Node) -> bool:
	if not _broken:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if global_position.distance_to((player as Node2D).global_position) > 52.0:
		return false
	_begin_transition()
	return true


func _begin_transition() -> void:
	## Transition node lives on the root so its await survives this scene unloading.
	GameState.set_paused(false)
	GameState.current_zone_id = "lantern_village"
	GameState.pending_spawn = spawn_in_next
	GameState.last_position = spawn_in_next
	GameState.checkpoint_position = spawn_in_next
	GameState.needs_intro_cutscene = false
	SaveManager.autosave()
	# Re-assert after autosave — capture must not keep the cottage X.
	GameState.last_position = spawn_in_next
	GameState.checkpoint_position = spawn_in_next
	GameState.pending_spawn = spawn_in_next
	# Transition lives on the root so awaits survive this hatch freeing with the cottage.
	ZoneTransition.go(get_tree(), next_scene, "Leaving the cottage…")
