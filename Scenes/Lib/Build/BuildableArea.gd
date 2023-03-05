extends TileMap

@export var buildable: bool = true

func _ready():
	hide()
	add_to_group(Constants.Groups.BUILD_AREA_GROUP)

func can_build_at_pos(pos: Vector2) -> bool:
	return get_cell_source_id(0, pos) != -1 and buildable
