extends Node


# Map position is free if it contains only ground tiles
static func map_pos_is_free(map_parent: Node2D, buildable_area: TileMap, pos: Vector2) -> bool:
	return buildable_area.get_cellv(pos) != TileMap.INVALID_CELL

