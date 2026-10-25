extends CharacterBody2D
class_name WanderEnemy
## Shade grub: walks back and forth, flips on walls, damages on contact.

@export var move_speed: float = 55.0
@export var attack_damage: int = 10
@export var max_hp: int = 24

var hp: int = 24
var _dir: float = 1.0
var _hurt_cd: float = 0.0
var _anim_t: float = 0.0
var _tex_a: ImageTexture
var _tex_b: ImageTexture

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
var _sprite: Sprite2D


func _ready() -> void:
	hp = max_hp
	# Layer 0: stand on world via mask, but do not body-block the player (damage via hit/hurt Areas).
	collision_layer = 0
	collision_mask = 1 | 4
	hurtbox.team = "enemy"
	hurtbox.owner_body = self
	hurtbox.hurt.connect(_on_hurt)
	hitbox.team = "enemy"
	hitbox.owner_body = self
	hitbox.damage = attack_damage
	hitbox.monitoring = true
	hitbox.activate()
	_tex_a = _make_grub_tex(0)
	_tex_b = _make_grub_tex(1)
	_build_sprite()
	add_to_group("enemies")


func _build_sprite() -> void:
	# Hide crystal polygon if present.
	var old := get_node_or_null("Visual")
	if old:
		old.visible = false
	var eyes := get_node_or_null("Eyes")
	if eyes:
		eyes.visible = false
	_sprite = Sprite2D.new()
	_sprite.name = "BodySprite"
	_sprite.centered = true
	_sprite.position = Vector2(0, -18)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _tex_a
	## Opaque body; only the texture's unused pixels stay transparent (no box bg).
	_sprite.modulate = Color.WHITE
	add_child(_sprite)


func _make_grub_tex(frame: int) -> ImageTexture:
	var img := Image.create(40, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color(0.16, 0.12, 0.2, 1.0)
	var shell := Color(0.28, 0.18, 0.32, 1.0)
	var belly := Color(0.35, 0.22, 0.28, 1.0)
	var eye := Color(0.95, 0.55, 0.2, 1.0)
	var outline := Color(0.05, 0.03, 0.08, 1.0)
	# Segmented body
	var bob := (frame % 2) * 1
	_fill_oval(img, 20, 18 + bob, 14, 10, body)
	_fill_oval(img, 12, 20 + bob, 7, 7, shell)
	_fill_oval(img, 28, 20 + bob, 7, 7, shell)
	_fill_oval(img, 20, 22 + bob, 10, 6, belly)
	# Head
	_fill_oval(img, 20, 10 + bob, 9, 8, body)
	_fill_oval(img, 16, 9 + bob, 2, 2, eye)
	_fill_oval(img, 24, 9 + bob, 2, 2, eye)
	# Mandibles
	_fill_oval(img, 14, 14 + bob, 2, 3, outline)
	_fill_oval(img, 26, 14 + bob, 2, 3, outline)
	# Legs
	var leg_shift := -1 if frame % 2 == 0 else 1
	for i in 3:
		var lx := 12 + i * 6
		_fill_oval(img, lx + leg_shift, 28, 2, 4, outline)
		_fill_oval(img, lx + 4 - leg_shift, 28, 2, 4, outline)
	# Soft outline rim
	for y in 36:
		for x in 40:
			if img.get_pixel(x, y).a < 0.1:
				continue
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var nx := x + ox
					var ny := y + oy
					if nx < 0 or ny < 0 or nx >= 40 or ny >= 36:
						continue
					if img.get_pixel(nx, ny).a < 0.1:
						img.set_pixel(nx, ny, outline)
	return ImageTexture.create_from_image(img)


func _fill_oval(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx := float(x - cx) / float(maxi(rx, 1))
			var dy := float(y - cy) / float(maxi(ry, 1))
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return
	_hurt_cd = maxf(0.0, _hurt_cd - delta)
	_anim_t += delta
	if _sprite:
		_sprite.texture = _tex_a if int(_anim_t * 6.0) % 2 == 0 else _tex_b
	velocity.x = _dir * move_speed
	velocity.y += 980.0 * delta
	move_and_slide()
	if is_on_wall():
		_dir *= -1.0
	if is_on_floor():
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(_dir * 16.0, -4.0)
		var to := from + Vector2(0, 28)
		var q := PhysicsRayQueryParameters2D.create(from, to)
		q.collision_mask = 1
		q.exclude = [self]
		if space.intersect_ray(q).is_empty():
			_dir *= -1.0
	if _sprite:
		_sprite.flip_h = _dir < 0.0
	_touch_damage()


func _touch_damage() -> void:
	if _hurt_cd > 0.0:
		return
	var p = GameState.player
	if p == null or not is_instance_valid(p):
		return
	if global_position.distance_to(p.global_position) < 28.0:
		GameState.take_damage(attack_damage)
		_hurt_cd = 0.8


func _on_hurt(amount: int, _from: Node) -> void:
	hp -= amount
	if _sprite:
		_sprite.modulate = Color(1.6, 1.6, 1.6)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return
	if _sprite:
		_sprite.modulate = Color.WHITE
	if hp <= 0:
		queue_free()
