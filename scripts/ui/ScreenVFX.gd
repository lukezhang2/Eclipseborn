extends CanvasLayer
## Soft elliptical vignettes — violet for shade drain, ash-orange for health burn.

@onready var shade_edges: Control = $ShadeEdges
@onready var health_edges: Control = $HealthEdges

var _shade_pulse: float = 0.0
var _health_pulse: float = 0.0
var _prev_health: int = 100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	_fill_vignette(shade_edges, Color(0.4, 0.18, 0.65, 1.0))
	_fill_vignette(health_edges, Color(0.95, 0.35, 0.12, 1.0))
	GameState.health_changed.connect(_on_health)
	GameState.shade_changed.connect(_on_shade)
	_prev_health = GameState.health
	shade_edges.modulate.a = 0.0
	health_edges.modulate.a = 0.0
	shade_edges.visible = false
	health_edges.visible = false


func _fill_vignette(root: Control, color: Color) -> void:
	for c in root.get_children():
		c.queue_free()
	var tex := TextureRect.new()
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.texture = _make_radial_vignette(color)
	root.add_child(tex)


func _make_radial_vignette(color: Color) -> ImageTexture:
	var w := 256
	var h := 144
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx := w * 0.5
	var cy := h * 0.5
	for y in h:
		for x in w:
			var nx := (float(x) - cx) / cx
			var ny := (float(y) - cy) / cy
			# Elliptical distance; soft falloff from edges inward.
			var d := sqrt(nx * nx + ny * ny)
			var edge := clampf((d - 0.35) / 0.75, 0.0, 1.0)
			edge = edge * edge * (3.0 - 2.0 * edge)  # smoothstep
			img.set_pixel(x, y, Color(color.r, color.g, color.b, edge * 0.85))
	return ImageTexture.create_from_image(img)


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
	var shade_a := _shade_pulse * (0.4 + 0.2 * sin(t * 8.0))
	var health_a := _health_pulse * (0.5 + 0.2 * absf(sin(t * 12.0)))
	_apply(shade_edges, shade_a)
	_apply(health_edges, health_a)


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
