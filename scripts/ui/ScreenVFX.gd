extends CanvasLayer
## Edge vignettes: violet ink when shade drains, ash-orange when health burns.

@onready var shade_edges: Control = $ShadeEdges
@onready var health_edges: Control = $HealthEdges

var _shade_pulse: float = 0.0
var _health_pulse: float = 0.0
var _prev_health: int = 100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	_fill_edges(shade_edges, Color(0.35, 0.15, 0.55, 0.55))
	_fill_edges(health_edges, Color(0.95, 0.35, 0.12, 0.65))
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	_prev_health = GameState.health
	shade_edges.modulate.a = 0.0
	health_edges.modulate.a = 0.0
	shade_edges.visible = false
	health_edges.visible = false


func _fill_edges(root: Control, color: Color) -> void:
	for c in root.get_children():
		c.queue_free()
	var thickness := 56.0
	for side in ["top", "bottom", "left", "right"]:
		var r := ColorRect.new()
		r.color = color
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match side:
			"top":
				r.set_anchors_preset(Control.PRESET_TOP_WIDE)
				r.offset_bottom = thickness
			"bottom":
				r.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
				r.offset_top = -thickness
			"left":
				r.set_anchors_preset(Control.PRESET_LEFT_WIDE)
				r.offset_right = thickness
			"right":
				r.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
				r.offset_left = -thickness
		root.add_child(r)


func _process(delta: float) -> void:
	var shade_draining := false
	var health_burning := false
	var player = GameState.player
	if player and is_instance_valid(player) and player._in_vulnerable_light:
		if GameState.shade > 0.0:
			shade_draining = true
		else:
			health_burning = true

	if shade_draining:
		_shade_pulse = minf(1.0, _shade_pulse + delta * 2.5)
	else:
		_shade_pulse = maxf(0.0, _shade_pulse - delta * 3.0)

	if health_burning:
		_health_pulse = minf(1.0, _health_pulse + delta * 4.0)
	else:
		_health_pulse = maxf(0.0, _health_pulse - delta * 2.5)

	var t := Time.get_ticks_msec() / 1000.0
	var shade_a := _shade_pulse * (0.35 + 0.2 * sin(t * 8.0))
	var health_a := _health_pulse * (0.45 + 0.25 * absf(sin(t * 14.0)))
	_apply(shade_edges, shade_a)
	_apply(health_edges, health_a)
	if health_a > 0.05:
		for c in health_edges.get_children():
			if c is ColorRect:
				(c as ColorRect).color.a = health_a * (0.7 + randf() * 0.3)


func _on_shade(ratio: float) -> void:
	if ratio < 1.0:
		_shade_pulse = maxf(_shade_pulse, (1.0 - ratio) * 0.5)


func _on_health(current: int, _maximum: int) -> void:
	if current < _prev_health:
		_health_pulse = 1.0
	_prev_health = current


func _apply(node: Control, a: float) -> void:
	node.modulate.a = clampf(a, 0.0, 1.0)
	node.visible = a > 0.01
