extends ZoneLinkDoor
class_name TowerVillageDoor
## Lobby door back to Lantern Village (left of the tower facade).
## Interact only — walking into the door must not auto-leave.


func _ready() -> void:
	if target_zone == "":
		target_zone = "lantern_village"
	if spawn_pos == Vector2(520, 460):
		spawn_pos = Vector2(ClockworkTower.VILLAGE_DOOR_X - 80.0, 460)
	if travel_caption == "":
		travel_caption = "Back to Lantern Village…"
	if verb == "" or verb == "Interact":
		verb = "Village"
	show_exit_arrow = false
	walk_to_exit = false
	super._ready()
