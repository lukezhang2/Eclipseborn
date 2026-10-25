extends Node2D
class_name SteamVent
## Floor grate that puffs transparent steam upward.


func _ready() -> void:
	_build()


func _build() -> void:
	# Riveted iron grate; the steam itself stays particle-based.
	var grate := WorldArt.new()
	grate.kind = WorldArt.Kind.VENT
	grate.style = 1
	grate.position = Vector2(0, 2)
	add_child(grate)
	LightOnlyBlocker.attach(self, PackedVector2Array([
		Vector2(-18, -6), Vector2(18, -6), Vector2(18, 8), Vector2(-18, 8)
	]), true)

	# Steady column of soft steam plus a heavier puff every couple of seconds.
	add_child(_make_steam(22, 2.4, 0.15, Vector2(36, 70), 0.5, 1.8, 0.32))
	var burst := _make_steam(10, 1.9, 0.85, Vector2(70, 120), 0.8, 2.6, 0.4)
	burst.position = Vector2(0, -2)
	add_child(burst)
	_pulse(burst)


## Soft round puffs that rise, swell, drift and fade.
func _make_steam(amount: int, life: float, burst: float, speed: Vector2, s0: float, s1: float, alpha: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _puff_texture()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.explosiveness = burst
	p.randomness = 0.5
	p.direction = Vector2(0, -1)
	p.spread = 14.0
	p.gravity = Vector2(6, -22)
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.damping_min = 8.0
	p.damping_max = 18.0
	p.angular_velocity_min = -30.0
	p.angular_velocity_max = 30.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(12, 2)
	var grow := Curve.new()
	grow.add_point(Vector2(0, s0 / s1))
	grow.add_point(Vector2(1, 1))
	p.scale_amount_curve = grow
	p.scale_amount_min = s1 * 0.8
	p.scale_amount_max = s1 * 1.2
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.92, 0.94, 0.97, 0.0),
		Color(0.9, 0.92, 0.96, alpha),
		Color(0.82, 0.85, 0.9, alpha * 0.5),
		Color(0.78, 0.8, 0.86, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.12, 0.6, 1.0])
	p.color_ramp = ramp
	p.z_index = 2
	p.emitting = true
	return p


static var _puff_tex: Texture2D


static func _puff_texture() -> Texture2D:
	if _puff_tex == null:
		var g := GradientTexture2D.new()
		g.width = 32
		g.height = 32
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.gradient = grad
		_puff_tex = g
	return _puff_tex


## Heavier puffs come in pulses, like a pressure valve letting go.
func _pulse(p: CPUParticles2D) -> void:
	while is_inside_tree():
		p.emitting = true
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree():
			return
		p.emitting = false
		await get_tree().create_timer(randf_range(1.4, 2.6)).timeout
