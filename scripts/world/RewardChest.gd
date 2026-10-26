extends StaticBody2D
class_name RewardChest
## Attackable brass pot-chest. Opens on hit and drops a shadow crystal piece.


@export var chest_id: String = "tower_reward_chest"
@export var piece_id: String = "tower_crystal_piece"

var _opened: bool = false
var _hurtbox: Hurtbox
var _visual: Node2D
var _lid: Polygon2D


func _ready() -> void:
	if GameState.is_broken(chest_id) or GameState.is_collected(piece_id):
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("breakables")


func _build() -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 32)
	cs.shape = rect
	cs.position = Vector2(0, -4)
	add_child(cs)

	_visual = Node2D.new()
	add_child(_visual)
	## Pot-like brass chest body
	var body := Polygon2D.new()
	body.color = Color(0.55, 0.42, 0.22)
	body.polygon = PackedVector2Array([
		Vector2(-16, -4), Vector2(16, -4), Vector2(14, 14), Vector2(-14, 14)
	])
	_visual.add_child(body)
	var band := Polygon2D.new()
	band.color = Color(0.75, 0.6, 0.3)
	band.polygon = PackedVector2Array([
		Vector2(-17, 2), Vector2(17, 2), Vector2(17, 6), Vector2(-17, 6)
	])
	_visual.add_child(band)
	_lid = Polygon2D.new()
	_lid.color = Color(0.62, 0.48, 0.26)
	_lid.polygon = PackedVector2Array([
		Vector2(-15, -4), Vector2(15, -4), Vector2(12, -16), Vector2(-12, -16)
	])
	_visual.add_child(_lid)
	var glow := Polygon2D.new()
	glow.color = Color(0.7, 0.35, 0.85, 0.35)
	glow.polygon = PackedVector2Array([
		Vector2(-6, -10), Vector2(6, -10), Vector2(4, -2), Vector2(-4, -2)
	])
	_visual.add_child(glow)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(44, 40)
	hcs.shape = hr
	hcs.position = Vector2(0, -6)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)


func _on_hurt(_amount: int, _from: Node) -> void:
	if _opened:
		return
	_opened = true
	GameState.mark_broken(chest_id)
	AudioManager.play_break()
	if _lid:
		var tw := create_tween()
		tw.tween_property(_lid, "position", Vector2(-8, -28), 0.25)
		tw.parallel().tween_property(_lid, "rotation", -0.9, 0.25)
	## Drop crystal piece
	var piece_script: Script = preload("res://scripts/world/ShadowCrystalPiece.gd")
	var piece: Node = piece_script.new()
	piece.set("pickup_id", piece_id)
	piece.set("display_name", "Shadow Crystal Piece")
	get_parent().add_child(piece)
	piece.global_position = global_position + Vector2(0, -18)
	if piece.has_method("pop_out"):
		piece.call("pop_out")
	_hurtbox.set_deferred("monitorable", false)
	SaveManager.autosave()
	## Fade the empty pot away so it doesn't sit as a glow blob on the arena floor.
	var fade := create_tween()
	fade.tween_interval(0.45)
	fade.tween_property(self, "modulate:a", 0.0, 0.35)
	fade.tween_callback(queue_free)
