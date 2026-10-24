extends Node
## Spins parent background gear (no physics).


func _process(delta: float) -> void:
	var p := get_parent() as Node2D
	if p == null:
		return
	p.rotation_degrees += float(p.get_meta("bg_gear_speed", 10.0)) * delta
