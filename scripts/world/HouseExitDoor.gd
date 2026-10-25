extends ZoneLinkDoor
class_name HouseExitDoor
## Left-wall exit from a house interior — defaults to Lantern Village.


func _ready() -> void:
	## Prefer already-configured spawn/zone (LevelData). Else use house return_spawn.
	var parent := get_parent()
	if spawn_pos == Vector2(520, 460) and parent and "return_spawn" in parent:
		spawn_pos = parent.return_spawn
	if target_zone == "":
		target_zone = "lantern_village"
	if travel_caption == "":
		travel_caption = "Back to the street…"
	if verb == "" or verb == "Interact":
		verb = "Leave"
	show_exit_arrow = true
	super._ready()
