extends Interactable
class_name LightSwitch
## Railway-switch lever (light shows green on / red off). Links to lanterns / doors by catalog id (or node name).
## Interact (E) flips it; all linked targets get set_on(powered).


@export var target_ids: PackedStringArray = PackedStringArray()
@export var starts_on: bool = true
## Legacy NodePaths still work if set from old room scripts.
@export var target_light_paths: Array[NodePath] = []

var _on: bool = true
var _art: WorldArt


func _ready() -> void:
	verb = "Flip"
	super()
	_on = starts_on
	_build_lever()
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


func _build_lever() -> void:
	_art = WorldArt.new()
	_art.kind = WorldArt.Kind.LEVER
	_art.style = 1
	_art.on = _on
	add_child(_art)
	_snap_to_floor.call_deferred()


## Sit the lever base on whatever floor is below, wherever the editor placed it.
func _snap_to_floor() -> void:
	await get_tree().physics_frame
	if not is_instance_valid(self):
		return
	var d := WorldArt.floor_distance(self)
	if d >= 0.0:
		_art.position.y = d - 4.0  # Lever base bottom is 4px below the art origin.


func _apply_visual() -> void:
	if _art:
		_art.on = _on
		_art.queue_redraw()


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
