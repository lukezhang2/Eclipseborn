extends Node
## First-spawn cutscene: ash/ember effects, camera settles on the spirit.


func play(player: Player) -> void:
	GameState.intro_cutscene_playing = true
	player.set_control_locked(true)
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		GameState.intro_cutscene_playing = false
		player.set_control_locked(false)
		return

	# Start zoomed out and offset, with a dark flash.
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.add_child(overlay)
	player.get_tree().root.add_child(layer)

	cam.zoom = Vector2(0.7, 0.7)
	cam.offset = Vector2(0, -120)

	# Ember burst around player.
	var burst := Node2D.new()
	burst.global_position = player.global_position
	player.get_parent().add_child(burst)
	for i in 18:
		var p := Polygon2D.new()
		p.color = Color(0.7, 0.25, 0.1, 0.9)
		p.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		p.position = Vector2(randf_range(-10, 10), randf_range(-40, 0))
		burst.add_child(p)
		var twp := create_tween()
		twp.tween_property(p, "position", p.position + Vector2(randf_range(-80, 80), randf_range(-140, -40)), 1.2)
		twp.parallel().tween_property(p, "modulate:a", 0.0, 1.2)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.9)
	tw.parallel().tween_property(cam, "zoom", Vector2(1.4, 1.4), 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(cam, "offset", Vector2.ZERO, 1.6).set_ease(Tween.EASE_OUT)

	await tw.finished
	await get_tree().create_timer(0.25).timeout

	var hint := player.get_tree().get_first_node_in_group("tutorial_hint")
	if hint and hint.has_method("show_hint"):
		hint.show_hint("The boiler-house remembers you.")

	layer.queue_free()
	burst.queue_free()
	player.set_control_locked(false)
	GameState.intro_cutscene_playing = false
	GameState.needs_intro_cutscene = false
	queue_free()
