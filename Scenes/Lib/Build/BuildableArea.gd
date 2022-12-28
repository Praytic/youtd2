extends TileMap

export(bool) var buildable = true

func _ready():
	hide()
	add_to_group(Constants.Groups.BUILD_AREA_GROUP)

func can_build_at_pos(pos: Vector2) -> bool:
	return get_cellv(pos) != TileMap.INVALID_CELL and buildable
