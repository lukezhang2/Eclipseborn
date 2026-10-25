extends CharacterBody2D
class_name FuseBeetle
## Iron weevil with a cage lantern on its back — living light that snuffs on death.


@export var attack_damage: int = 10
@export var max_hp: int = 28
@export var move_speed: float = 48.0
@export var light_radius: float = 110.0

var hp: int = 28
var _dir: float = 1.0
var _hurt_cd: float = 0.0
var _charge_cd: float = 0.0
var _dead: bool = false
var _sprite: Sprite2D
var _lamp: LightSource

@onready var hurtbox: Hurtbox = null


func _ready() -> void:
	hp = max_hp
	collision_layer = 0
	collision_mask = 1 | 4 | 8
	_build()
	add_to_group("enemies")
	add_to_group("fuse_beetles")


func _build() -> void:
	var body_cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 20)
	body_cs.shape = rect
	body_cs.position = Vector2(0, -2)
	add_child(body_cs)

	hurtbox = Hurtbox.new()
	hurtbox.team = "enemy"
	hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(30, 22)
	hcs.shape = hr
	hcs.position = Vector2(0, -2)
	hurtbox.add_child(hcs)
	hurtbox.hurt.connect(_on_hurt)
	add_child(hurtbox)

	var hit := Hitbox.new()
	hit.team = "enemy"
	hit.owner_body = self
	hit.damage = attack_damage
	var ics := CollisionShape2D.new()
	var ir := CircleShape2D.new()
	ir.radius = 14.0
	ics.shape = ir
	hit.add_child(ics)
	add_child(hit)
	hit.activate()

	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _make_tex()
	_sprite.position = Vector2(0, -6)
	add_child(_sprite)

	_lamp = LightSource.new()
	_lamp.position = Vector2(0, -18)
	_lamp.light_kind = GameState.LightKind.CANDLE
	_lamp.radius = light_radius
	_lamp.shadow_length = light_radius + 40.0
	_lamp.pushable = false
	_lamp.is_enabled = true
	add_child(_lamp)


func _make_tex() -> ImageTexture:
	var img := Image.create(36, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var iron := Color(0.28, 0.26, 0.24)
	var brass := Color(0.7, 0.55, 0.3)
	var ember := Color(0.95, 0.55, 0.2)
	_fill_oval(img, 18, 16, 12, 8, iron)
	_fill_oval(img, 18, 10, 8, 6, iron)
	## Cage lamp
	_fill_oval(img, 18, 6, 5, 5, brass)
	_fill_oval(img, 18, 6, 3, 3, ember)
	for x in [14, 18, 22]:
		for y in range(3, 10):
			if img.get_pixel(x, y).a > 0.1:
				img.set_pixel(x, y, Color(brass.r, brass.g, brass.b, 0.85))
	_fill_oval(img, 12, 12, 1, 1, Color(0.9, 0.4, 0.15))
	_fill_oval(img, 24, 12, 1, 1, Color(0.9, 0.4, 0.15))
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
	if GameState.is_paused or GameState.intro_cutscene_playing:
		return
	_hurt_cd = maxf(0.0, _hurt_cd - delta)
	_charge_cd = maxf(0.0, _charge_cd - delta)
	var p = GameState.player
	var speed := move_speed
	if p and is_instance_valid(p) and _charge_cd <= 0.0:
		if absf(p.global_position.x - global_position.x) < 160.0 and absf(p.global_position.y - global_position.y) < 80.0:
			_dir = signf(p.global_position.x - global_position.x)
			if _dir == 0.0:
				_dir = 1.0
			speed = move_speed * 1.85
			_charge_cd = 1.4
	velocity.x = _dir * speed
	velocity.y += 980.0 * delta
	move_and_slide()
	if is_on_wall():
		_dir *= -1.0
	if is_on_floor():
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(_dir * 14.0, -2.0)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 24))
		q.collision_mask = collision_mask
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
	if global_position.distance_to(p.global_position) < 26.0:
		GameState.take_damage(attack_damage)
		_hurt_cd = 0.75


func _on_hurt(amount: int, from: Node) -> void:
	hp -= amount
	EnemyHitFX.play(_sprite, self, from)
	if hp <= 0 and not _dead:
		_dead = true
		if _lamp and is_instance_valid(_lamp):
			_lamp.set_on(false)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(self):
			CurrencyPickup.spawn_burst(get_parent(), global_position)
			queue_free()
