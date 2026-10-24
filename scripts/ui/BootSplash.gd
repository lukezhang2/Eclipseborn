extends Control
## Black glass cracks, shards scroll away, gears turn until pieces leave.

@onready var black: ColorRect = $Black
@onready var shards: Node2D = $Shards
@onready var gears: Node2D = $Gears

var _gear_spinning: bool = true
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_gears()
	_build_shards()
	AudioManager.play_boot_crack()
	await get_tree().create_timer(0.35).timeout
	if not _done:
		AudioManager.play_boot_gears()
	_animate()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		_finish()


func _process(delta: float) -> void:
	if not _gear_spinning:
		return
	for g in gears.get_children():
		if g is Node2D:
			var speed: float = g.get_meta("speed", 40.0)
			g.rotation_degrees += speed * delta


func _build_gears() -> void:
	for i in 5:
		var g := Node2D.new()
		g.position = Vector2(180 + i * 220, 160 + (i % 2) * 320)
		g.set_meta("speed", 35.0 + i * 12.0 * (1 if i % 2 == 0 else -1))
		var disk := Polygon2D.new()
		disk.color = Color(0.25, 0.22, 0.2, 0.55)
		var pts := PackedVector2Array()
		for k in 12:
			var a := TAU * float(k) / 12.0
			pts.append(Vector2(cos(a), sin(a)) * (40.0 + (k % 2) * 10.0))
		disk.polygon = pts
		g.add_child(disk)
		gears.add_child(g)


func _build_shards() -> void:
	var centers := [
		Vector2(640, 360), Vector2(400, 220), Vector2(900, 280),
		Vector2(500, 500), Vector2(800, 480), Vector2(300, 400),
		Vector2(1000, 420), Vector2(200, 180), Vector2(1100, 200),
	]
	for i in centers.size():
		var holder := Node2D.new()
		holder.position = centers[i]
		var spread := 160.0 + i * 18.0
		var shard := Polygon2D.new()
		shard.color = Color(0.02, 0.02, 0.03, 1.0)
		shard.polygon = PackedVector2Array([
			Vector2(-spread * 0.3, -spread),
			Vector2(spread * 0.5, -spread * 0.4),
			Vector2(spread, spread * 0.2),
			Vector2(spread * 0.1, spread),
			Vector2(-spread * 0.6, spread * 0.35),
		])
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.7, 0.75, 0.85, 0.9)
		for p in shard.polygon:
			line.add_point(p)
		line.add_point(shard.polygon[0])
		holder.add_child(shard)
		holder.add_child(line)
		holder.set_meta("dir", Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized())
		shards.add_child(holder)

	var cracks := Line2D.new()
	cracks.width = 3.0
	cracks.default_color = Color(0.85, 0.88, 0.95, 0.95)
	cracks.add_point(Vector2(640, 360))
	cracks.add_point(Vector2(420, 200))
	cracks.add_point(Vector2(200, 140))
	cracks.add_point(Vector2(640, 360))
	cracks.add_point(Vector2(980, 240))
	cracks.add_point(Vector2(1180, 180))
	cracks.add_point(Vector2(640, 360))
	cracks.add_point(Vector2(500, 560))
	cracks.add_point(Vector2(300, 680))
	cracks.add_point(Vector2(640, 360))
	cracks.add_point(Vector2(860, 600))
	cracks.name = "CrackLines"
	shards.add_child(cracks)


func _animate() -> void:
	await get_tree().create_timer(0.55).timeout
	if _done:
		return
	if black:
		create_tween().tween_property(black, "modulate:a", 0.0, 0.4)
	var cracks := shards.get_node_or_null("CrackLines")
	if cracks:
		create_tween().tween_property(cracks, "modulate:a", 0.0, 0.3)

	for shard in shards.get_children():
		if shard.name == "CrackLines":
			continue
		if not shard is Node2D:
			continue
		var dir: Vector2 = shard.get_meta("dir", Vector2.RIGHT)
		var target: Vector2 = shard.position + dir * 1500.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", target, randf_range(1.1, 1.7)).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "rotation_degrees", randf_range(-140, 140), 1.4)
		tw.tween_property(shard, "modulate:a", 0.0, 1.5)

	await get_tree().create_timer(1.7).timeout
	_gear_spinning = false
	await get_tree().create_timer(0.2).timeout
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	_gear_spinning = false
	get_tree().change_scene_to_file("res://scenes/ui/TitleMenu.tscn")
