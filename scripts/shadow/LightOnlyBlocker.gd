extends RefCounted
class_name LightOnlyBlocker
## Attach a light-blocking body (physics layer 128) + ShadowOccluder.
## Does not collide with the player. Toggle via blocks_light.


static func attach(parent: Node2D, local_poly: PackedVector2Array, enabled: bool = true) -> void:
	## Remove any previous blocker children we tagged.
	for c in parent.get_children():
		if c.has_meta("light_only_blocker"):
			c.queue_free()
	if not enabled or local_poly.size() < 3:
		return

	var body := StaticBody2D.new()
	body.name = "LightOnlyBody"
	body.set_meta("light_only_blocker", true)
	body.collision_layer = PieceSpecs.LIGHT_BLOCK_PHYSICS_LAYER
	body.collision_mask = 0
	var cs := CollisionPolygon2D.new()
	cs.polygon = local_poly
	body.add_child(cs)
	parent.add_child(body)

	var occ := ShadowOccluder.new()
	occ.name = "LightOnlyOccluder"
	occ.set_meta("light_only_blocker", true)
	occ.local_polygon = local_poly
	parent.add_child(occ)
