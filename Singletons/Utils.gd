extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(map_parent: Node2D, pos: Vector2) -> bool:
	var ground_map = map_parent.get_node("Floor")
	
	for child_map in map_parent.get_children():
		if child_map == ground_map:
			continue
		
		var map_is_empty_at_pos = child_map.get_cellv(pos) == TileMap.INVALID_CELL
		
		if !map_is_empty_at_pos:
			return false
	
	return true

