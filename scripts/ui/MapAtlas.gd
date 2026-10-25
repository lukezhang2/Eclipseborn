extends RefCounted
class_name MapAtlas
## Editor pieces for the player map: catalog seed plus the zone JSON overlay.
## Light radius is not part of the bounds, so a wide lamp does not shrink the fit.


static func pieces_for(zone_id: String) -> Array:
	if not ZoneCatalog.zone_ids().has(zone_id):
		return []
	return _merged(zone_id)


static func _merged(zone_id: String) -> Array:
	var data := LevelData.load_raw(zone_id)
	var removed: Array = data.get("removed_ids", [])
	var by_id := {}
	var order: Array = []
	for cat in ZoneCatalog.pieces_for(zone_id):
		if typeof(cat) != TYPE_DICTIONARY:
			continue
		var id := str(cat.get("id", ""))
		if id != "" and removed.has(id):
			continue
		by_id[id] = (cat as Dictionary).duplicate(true)
		order.append(id)
	for raw in data.get("pieces", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id := str(raw.get("id", ""))
		if id != "" and removed.has(id):
			continue
		if by_id.has(id):
			var piece: Dictionary = by_id[id]
			for key in (raw as Dictionary).keys():
				piece[key] = raw[key]
		elif not bool(raw.get("builtin", false)):
			by_id[id] = (raw as Dictionary).duplicate(true)
			order.append(id)
	var out: Array = []
	for id in order:
		out.append(by_id[id])
	out.sort_custom(func(a, b) -> bool:
		return int(a.get("layer", 0)) < int(b.get("layer", 0))
	)
	return out


static func world_rect(piece: Dictionary) -> Rect2:
	var kind := str(piece.get("kind", ""))
	var x := float(piece.get("x", 0.0))
	var y := float(piece.get("y", 0.0))
	var w := maxf(float(piece.get("w", 48.0)), 4.0)
	var h := maxf(float(piece.get("h", 48.0)), 4.0)
	var anchor := str(piece.get("anchor", PieceSpecs.anchor(kind)))
	var rect := Rect2(x - w * 0.5, y - h * 0.5, w, h)
	if anchor == "bottom":
		rect.position.y = y - h
	if kind == "prop_house":
		var extra := h * 0.45
		rect.position.y -= extra
		rect.size.y += extra
	elif kind == "prop_tower":
		var extra := h * 0.22
		rect.position.y -= extra
		rect.size.y += extra
	elif kind == "prop_bg_gear":
		rect = rect.grow(6.0)
	return rect


static func content_bounds(pieces: Array) -> Rect2:
	if pieces.is_empty():
		return Rect2(0, 160, 800, 360)
	var bounds := world_rect(pieces[0])
	for i in range(1, pieces.size()):
		if typeof(pieces[i]) != TYPE_DICTIONARY:
			continue
		bounds = bounds.merge(world_rect(pieces[i]))
	return bounds.grow(28.0)
