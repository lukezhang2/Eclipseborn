extends CharacterBody2D
class_name RivetMite
## Tiny brass mite that clings under ledges and drops when the player passes.


@export var attack_damage: int = 8
@export var max_hp: int = 8
@export var drop_speed: float = 420.0

var hp: int = 8
var _hurt_cd: float = 0.0
var _dead: bool = false
var _state: String = "cling" ## cling | drop | crawl
var _dir: float = 1.0
var _sprite: Sprite2D
var _anchor_y: float = 0.0

@onready var hurtbox: Hurtbox = null
@onready var hitbox: Hitbox = null


func _ready() -> void:
	hp = max_hp
	_anchor_y = position.y
	collision_layer = 0
	collision_mask = 1 | 4 | 8
	_build_combat()
	_build_sprite()
	add_to_group("enemies")


func _build_combat() -> void:
	hurtbox = Hurtbox.new()
	hurtbox.team = "enemy"
	hurtbox.owner_body = self
	var hcs := CollisionShape2D.new()
	var hr := CircleShape2D.new()
	hr.radius = 10.0
	hcs.shape = hr
	hcs.position = Vector2(0, 2)
	hurtbox.add_child(hcs)
	hurtbox.hurt.connect(_on_hurt)
	add_child(hurtbox)

	hitbox = Hitbox.new()
	hitbox.team = "enemy"
	hitbox.owner_body = self
	hitbox.damage = attack_damage
	var ics := CollisionShape2D.new()
	var ir := CircleShape2D.new()
	ir.radius = 11.0
	ics.shape = ir
	hitbox.add_child(ics)
	add_child(hitbox)
	hitbox.activate()

	var body_cs := CollisionShape2D.new()
	var br := CircleShape2D.new()
	br.radius = 8.0
	body_cs.shape = br
	add_child(body_cs)


func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _make_tex()
	_sprite.position = Vector2(0, 2)
	add_child(_sprite)


func _make_tex() -> ImageTexture:
	var img := Image.create(20, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var brass := Color(0.62, 0.48, 0.28)
	var dark := Color(0.22, 0.16, 0.1)
	var eye := Color(0.9, 0.35, 0.15)
	_oval(img, 10, 7, 7, 5, brass)
	_oval(img, 10, 5, 5, 3, dark)
	_oval(img, 7, 6, 1, 1, eye)
	_oval(img, 13, 6, 1, 1, eye)
	for lx in [4, 8, 12, 16]:
		_oval(img, lx, 13, 1, 2, dark)
	return ImageTexture.create_from_image(img)


func _oval(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
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
	var p = GameState.player
	match _state:
		"cling":
			velocity = Vector2.ZERO
			if p and is_instance_valid(p):
				if absf(p.global_position.x - global_position.x) < 36.0 and p.global_position.y > global_position.y:
					_state = "drop"
					velocity.y = drop_speed * 0.35
		"drop":
			velocity.y = minf(velocity.y + 1400.0 * delta, drop_speed)
			move_and_slide()
			if is_on_floor():
				_state = "crawl"
				_dir = signf((p.global_position.x - global_position.x) if p else 1.0)
				if _dir == 0.0:
					_dir = 1.0
		"crawl":
			velocity.x = _dir * 70.0
			velocity.y += 980.0 * delta
			move_and_slide()
			if is_on_wall():
				_dir *= -1.0
	if _sprite:
		_sprite.flip_h = _dir < 0.0
	_touch_damage()


func _touch_damage() -> void:
	if _hurt_cd > 0.0 or _state == "cling":
		return
	var p = GameState.player
	if p == null or not is_instance_valid(p):
		return
	if global_position.distance_to(p.global_position) < 22.0:
		GameState.take_damage(attack_damage)
		_hurt_cd = 0.7


func _on_hurt(amount: int, from: Node) -> void:
	hp -= amount
	EnemyHitFX.play(_sprite, self, from)
	if hp <= 0 and not _dead:
		_dead = true
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			CurrencyPickup.spawn_burst(get_parent(), global_position)
			queue_free()
