extends Node2D

const BUILDABLE_AREA_LAYER: int = 3

@onready var play_area: CollisionShape2D = $PlayArea/CollisionShape2D
@onready var _tilemap: TileMap = $TileMap

func get_play_area_size() -> Vector2:
	return play_area.get_shape().size

func get_play_area_pos() -> Vector2:
	return play_area.global_position

# Returns cursor position if the area is not buildable
# Returns tilemap position if the area is buildable
func get_current_buildable_pos() -> Vector2:
	var world_pos: Vector2 = _tilemap.get_local_mouse_position()
	var map_pos: Vector2 = _tilemap.local_to_map(world_pos)
	var cell_at_mouse: int = _tilemap.get_cell_source_id(BUILDABLE_AREA_LAYER, map_pos)
	var mouse_is_on_buildable_cell: bool = cell_at_mouse != -1

	if mouse_is_on_buildable_cell:
		var clamped_world_pos: Vector2 = _tilemap.map_to_local(map_pos)
		clamped_world_pos += Vector2(32, 32)

		return clamped_world_pos
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()

		return mouse_pos

func can_build_at_mouse_pos() -> bool:
	var world_pos: Vector2 = _tilemap.get_local_mouse_position()
	var map_pos: Vector2 = _tilemap.local_to_map(world_pos)
	var buildable_area_cell_exists_at_pos: bool = _tilemap.get_cell_source_id(BUILDABLE_AREA_LAYER, map_pos) != -1

	return buildable_area_cell_exists_at_pos
