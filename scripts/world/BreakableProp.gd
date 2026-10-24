extends StaticBody2D
class_name BreakableProp
## Glowing breakable that pops silver gear currency when smashed.

@export var breakable_id: String = ""
@export var prop_size: Vector2 = Vector2(28, 36)
@export var currency_drops: int = 2

var _broken: bool = false
var _hurtbox: Hurtbox
var _visual: Node2D
var _glow: Sprite2D
var _pulse: float = 0.0


func _ready() -> void:
	if GameState.is_broken(breakable_id):
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	_build()
	add_to_group("breakables")


func _process(delta: float) -> void:
	if _broken or _glow == null:
		return
	_pulse += delta * 3.0
	_glow.modulate.a = 0.35 + 0.35 * (0.5 + 0.5 * sin(_pulse))
	_glow.scale = Vector2.ONE * (1.15 + 0.08 * sin(_pulse * 1.3))


func _build() -> void:
	var half := prop_size * 0.5
	var poly := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	var cs := CollisionPolygon2D.new()
	cs.polygon = poly
	add_child(cs)

	_visual = Node2D.new()
	add_child(_visual)
	var body := Polygon2D.new()
	body.polygon = poly
	body.color = Color(0.35, 0.32, 0.28)
	_visual.add_child(body)
	# Rounded lid / jar rim
	var rim := Polygon2D.new()
	rim.color = Color(0.55, 0.5, 0.4)
	rim.polygon = PackedVector2Array([
		Vector2(-half.x + 2, -half.y - 4), Vector2(half.x - 2, -half.y - 4),
		Vector2(half.x - 4, -half.y + 2), Vector2(-half.x + 4, -half.y + 2),
	])
	_visual.add_child(rim)

	_glow = Sprite2D.new()
	_glow.texture = _make_glow_tex()
	_glow.centered = true
	_glow.z_index = -1
	_glow.modulate = Color(0.85, 0.95, 1.0, 0.5)
	_glow.scale = Vector2(prop_size.x / 32.0 * 2.2, prop_size.y / 32.0 * 2.2)
	add_child(_glow)

	var occ := ShadowOccluder.new()
	occ.local_polygon = poly
	add_child(occ)

	_hurtbox = Hurtbox.new()
	_hurtbox.team = "enemy"
	_hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# Slightly larger than the jar so close swings still connect.
	rect.size = prop_size + Vector2(14, 10)
	hcs.shape = rect
	hcs.position = Vector2(0, -2)
	_hurtbox.add_child(hcs)
	_hurtbox.hurt.connect(_on_hurt)
	add_child(_hurtbox)


func _make_glow_tex() -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	for y in s:
		for x in s:
			var d := Vector2(x, y).distance_to(c) / (s * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(0.7, 0.9, 1.0, a))
	return ImageTexture.create_from_image(img)


func _on_hurt(_amount: int, _from: Node) -> void:
	if _broken:
		return
	_broken = true
	GameState.mark_broken(breakable_id)
	AudioManager.play_break()
	# Spawn silver gears with a little pop.
	for i in currency_drops:
		var gear := CurrencyPickup.new()
		gear.pop_velocity = Vector2(randf_range(-110, 110), randf_range(-260, -140))
		get_parent().add_child(gear)
		gear.global_position = global_position + Vector2(randf_range(-6, 6), -10)
		gear.velocity = gear.pop_velocity
	# Shatter fade
	if _glow:
		_glow.visible = false
	if _visual:
		_visual.modulate.a = 0.3
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_deferred("disabled", true)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	await get_tree().create_timer(0.2).timeout
	SaveManager.autosave()
	queue_free()
