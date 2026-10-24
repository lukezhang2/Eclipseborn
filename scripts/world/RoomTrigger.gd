extends Area2D
class_name RoomTrigger
## Marks zone/room discovery for the Tab map. Shows a one-time control hint.

@export var zone_id: String = "cursed_cottage"
@export var room_id: String = "hall"
@export var hint: String = ""
@export var hint_action: String = ""  # input action name for key display

var _hint_shown: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not (body is Player or body.is_in_group("player")):
		return
	GameState.enter_room(zone_id, room_id)
	if hint != "" and not _hint_shown:
		_hint_shown = true
		var key := ""
		if hint_action != "" and InputMapManager:
			key = InputMapManager.get_binding_text(hint_action)
		var msg := hint if key == "" else "%s (%s)" % [hint, key]
		var ui := get_tree().get_first_node_in_group("tutorial_hint")
		if ui and ui.has_method("show_hint"):
			ui.show_hint(msg)
