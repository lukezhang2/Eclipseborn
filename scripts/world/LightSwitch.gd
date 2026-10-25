extends Interactable
class_name LightSwitch
## Minecraft-style lever. Links to lanterns / doors by catalog id (or node name).
## Interact (E) flips it; all linked targets get set_on(powered).


@export var target_ids: PackedStringArray = PackedStringArray()
@export var starts_on: bool = true
## Legacy NodePaths still work if set from old room scripts.
@export var target_light_paths: Array[NodePath] = []

var _on: bool = true
var _base: Node2D
var _stick: Node2D
var _cobble: Polygon2D


func _ready() -> void:
	verb = "Flip"
	super()
	_on = starts_on
	_build_minecraft_lever()
	_apply_visual()
	call_deferred("_apply_targets")


func set_target_ids(ids: PackedStringArray) -> void:
	target_ids = ids


func interact() -> void:
	_on = not _on
	_apply_visual()
	_apply_targets()


func is_powered() -> bool:
	return _on


func _build_minecraft_lever() -> void:
	_base = Node2D.new()
	_base.name = "LeverBase"
	add_child(_base)

	## Cobble wall plate (Minecraft lever sits on a block face).
	_cobble = Polygon2D.new()
	_cobble.color = Color(0.55, 0.55, 0.55)
	_cobble.polygon = PackedVector2Array([
		Vector2(-14, 4), Vector2(14, 4), Vector2(14, -22), Vector2(-14, -22)
	])
	_base.add_child(_cobble)
	## Speckle the cobble with darker/lighter chips.
	for offset in [
		Vector2(-8, -6), Vector2(4, -14), Vector2(-2, -18), Vector2(6, -4), Vector2(-10, -16)
	]:
		var chip := Polygon2D.new()
		chip.color = Color(0.42, 0.42, 0.44) if int(offset.x) % 2 == 0 else Color(0.68, 0.68, 0.66)
		chip.polygon = PackedVector2Array([
			offset + Vector2(-3, -2), offset + Vector2(3, -2),
			offset + Vector2(3, 2), offset + Vector2(-3, 2)
		])
		_base.add_child(chip)

	## Dark mortar lines
	var line_col := Color(0.32, 0.32, 0.34)
	for y in [-4.0, -12.0]:
		var mortar := Polygon2D.new()
		mortar.color = line_col
		mortar.polygon = PackedVector2Array([
			Vector2(-13, y - 0.6), Vector2(13, y - 0.6), Vector2(13, y + 0.6), Vector2(-13, y + 0.6)
		])
		_base.add_child(mortar)

	## Pivot mount
	var mount := Polygon2D.new()
	mount.color = Color(0.35, 0.35, 0.36)
	mount.polygon = PackedVector2Array([
		Vector2(-4, -8), Vector2(4, -8), Vector2(4, -12), Vector2(-4, -12)
	])
	_base.add_child(mount)

	## Stick pivots around the mount center.
	_stick = Node2D.new()
	_stick.name = "Stick"
	_stick.position = Vector2(0, -10)
	_base.add_child(_stick)
	var shaft := Polygon2D.new()
	shaft.color = Color(0.55, 0.35, 0.18)
	shaft.polygon = PackedVector2Array([
		Vector2(-2.5, 0), Vector2(2.5, 0), Vector2(2.0, -22), Vector2(-2.0, -22)
	])
	_stick.add_child(shaft)
	var tip := Polygon2D.new()
	tip.color = Color(0.65, 0.42, 0.22)
	tip.polygon = PackedVector2Array([
		Vector2(-3.5, -22), Vector2(3.5, -22), Vector2(3.0, -26), Vector2(-3.0, -26)
	])
	_stick.add_child(tip)


func _apply_visual() -> void:
	if _stick == null:
		return
	## ON = stick tilted up/back (Minecraft), OFF = tilted forward/down.
	_stick.rotation_degrees = -40.0 if _on else 40.0
	if _cobble:
		_cobble.modulate = Color(1.05, 1.05, 0.95) if _on else Color(0.85, 0.85, 0.9)


func _apply_targets() -> void:
	var seen: Dictionary = {}
	for id in target_ids:
		var sid := str(id)
		if sid == "" or seen.has(sid):
			continue
		seen[sid] = true
		_power_by_id(sid, _on)
	for path in target_light_paths:
		var n := get_node_or_null(path)
		if n:
			_power_node(n, _on)


func _power_by_id(id: String, powered: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("switch_targets"):
		if _node_matches_id(n, id):
			_power_node(n, powered)
	for n in tree.get_nodes_in_group("lights"):
		if _node_matches_id(n, id):
			_power_node(n, powered)
	## Also match by node name (StreetLamp etc.).
	var scene := tree.current_scene
	if scene:
		var by_name := scene.find_child(id, true, false)
		if by_name:
			_power_node(by_name, powered)


func _node_matches_id(n: Node, id: String) -> bool:
	if n.name == id:
		return true
	if n.has_meta("catalog_id") and str(n.get_meta("catalog_id")) == id:
		return true
	return false


func _power_node(n: Node, powered: bool) -> void:
	if n.has_method("set_on"):
		n.call("set_on", powered)
	elif n.has_method("set_powered"):
		n.call("set_powered", powered)
	elif n.has_method("set_open"):
		n.call("set_open", powered)
