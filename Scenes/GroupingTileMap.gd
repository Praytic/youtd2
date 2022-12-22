extends TileMap

func get_used_rect():
	var used_rects = []
	for tilemap in get_children():
		used_rects.append(tilemap.get_used_rect())
	return used_rects
