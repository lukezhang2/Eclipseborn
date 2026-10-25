extends Node2D
class_name SteamVent
## Floor grate that puffs transparent steam upward.


func _ready() -> void:
	_build()


func _build() -> void:
	var grate := Polygon2D.new()
	grate.color = Color(0.15, 0.15, 0.16)
	grate.polygon = PackedVector2Array([
		Vector2(-18, -4), Vector2(18, -4), Vector2(18, 4), Vector2(-18, 4)
	])
	add_child(grate)
	## Slot lines
	for i in 3:
		var slot := Polygon2D.new()
		slot.color = Color(0.08, 0.08, 0.09)
		var x0 := -12.0 + i * 10.0
		slot.polygon = PackedVector2Array([
			Vector2(x0, -2), Vector2(x0 + 3, -2), Vector2(x0 + 3, 2), Vector2(x0, 2)
		])
		add_child(slot)

	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 18
	particles.lifetime = 1.6
	particles.preprocess = 0.8
	particles.explosiveness = 0.05
	particles.randomness = 0.4
	particles.direction = Vector2(0, -1)
	particles.spread = 18.0
	particles.gravity = Vector2(0, -28)
	particles.initial_velocity_min = 28.0
	particles.initial_velocity_max = 55.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.4
	particles.angular_velocity_min = -40.0
	particles.angular_velocity_max = 40.0
	## Soft translucent steam (white → clear).
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.92, 0.94, 0.96, 0.0),
		Color(0.9, 0.92, 0.95, 0.35),
		Color(0.85, 0.88, 0.92, 0.18),
		Color(0.8, 0.84, 0.9, 0.0),
	])
	grad.offsets = PackedFloat32Array([0.0, 0.15, 0.55, 1.0])
	particles.color_ramp = grad
	particles.z_index = 2
	add_child(particles)

	## Soft animated billow polygons as backup visual
	for i in 3:
		var puff := Polygon2D.new()
		puff.z_index = 1
		puff.color = Color(0.88, 0.9, 0.93, 0.12)
		puff.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(6, 0), Vector2(10, -14), Vector2(-10, -14)
		])
		puff.position = Vector2((i - 1) * 6.0, -8.0 - i * 4.0)
		add_child(puff)
		_animate_puff(puff, 0.4 * i)


func _animate_puff(puff: Polygon2D, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(puff):
		return
	var base_y := puff.position.y
	while is_instance_valid(puff):
		var tw := create_tween()
		puff.modulate.a = 0.0
		puff.position.y = base_y
		puff.scale = Vector2(0.7, 0.7)
		tw.tween_property(puff, "modulate:a", 0.55, 0.35)
		tw.parallel().tween_property(puff, "position:y", base_y - 36.0, 1.2)
		tw.parallel().tween_property(puff, "scale", Vector2(1.6, 1.8), 1.2)
		tw.tween_property(puff, "modulate:a", 0.0, 0.35)
		await tw.finished
		if not is_instance_valid(puff):
			return
		await get_tree().create_timer(0.15).timeout
