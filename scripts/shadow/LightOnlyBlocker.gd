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
	## Exact outline, split into convex pieces: as reliable for ray hits as a rectangle, but it
	## never blocks open space (a bounding box or hull blocks the empty corners beside a roof).
	for piece in Geometry2D.decompose_polygon_in_convex(local_poly):
		var cs := CollisionShape2D.new()
		var shape := ConvexPolygonShape2D.new()
		shape.points = piece
		cs.shape = shape
		body.add_child(cs)
	parent.add_child(body)

	## Full silhouette for geometry occlusion (includes roof peak).
	var occ := ShadowOccluder.new()
	occ.name = "LightOnlyOccluder"
	occ.set_meta("light_only_blocker", true)
	occ.local_polygon = local_poly
	## BG gears spin every frame — circular hull doesn't need dirty on rotate.
	if parent.has_meta("bg_gear_speed"):
		occ.ignore_rotation = true
	parent.add_child(occ)
	ShadowWorld.mark_dirty()
