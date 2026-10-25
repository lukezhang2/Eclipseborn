extends RefCounted
class_name LightOnlyBlocker
## Attach a light-blocking body (physics layer 128) + ShadowOccluder.
## Geometry occluder is authoritative for burns + washes; physics is backup.
## Does not collide with the player.


static func attach(parent: Node2D, local_poly: PackedVector2Array, enabled: bool = true) -> void:
	for c in parent.get_children():
		if c.has_meta("light_only_blocker"):
			c.queue_free()
	if not enabled or local_poly.size() < 3:
		ShadowWorld.mark_dirty()
		return

	## Physics body — layer 8 bit (128). Player mask never includes this.
	var body := StaticBody2D.new()
	body.name = "LightOnlyBody"
	body.set_meta("light_only_blocker", true)
	body.collision_layer = PieceSpecs.LIGHT_BLOCK_PHYSICS_LAYER
	body.collision_mask = 0
	## Rectangle hull is more reliable for ray hits than a concave roof poly.
	var aabb := Rect2(local_poly[0], Vector2.ZERO)
	for p in local_poly:
		aabb = aabb.expand(p)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = aabb.size
	cs.shape = rect
	cs.position = aabb.position + aabb.size * 0.5
	body.add_child(cs)
	parent.add_child(body)

	## Full silhouette for geometry occlusion (includes roof peak).
	var occ := ShadowOccluder.new()
	occ.name = "LightOnlyOccluder"
	occ.set_meta("light_only_blocker", true)
	occ.local_polygon = local_poly
	parent.add_child(occ)
	ShadowWorld.mark_dirty()
