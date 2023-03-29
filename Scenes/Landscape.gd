extends Node2D

const BUILDABLE_AREA_LAYER: int = 3

@onready var play_area: Area2D = $PlayArea
@onready var play_area_shape: CollisionShape2D = $PlayArea/CollisionShape2D
@onready var _tilemap: TileMap = $TileMap
@onready var camera: Camera2D = %Map/Camera2D


func _ready():
	var s = play_area.scale
	var ss = play_area_shape.scale
	var ps = get_play_area_size()
	var pp = get_play_area_pos()
	camera.limit_bottom = pp.y + ps.y / 2 * s.y * ss.y
	camera.limit_top = pp.y - ps.y / 2 * s.y * ss.y
	camera.limit_left = pp.x - ps.x / 2 * s.x * ss.x
	camera.limit_right = pp.x + ps.x / 2 * s.x * ss.x
	camera.position = pp
	print_debug("Set camera limits to [lb: %s, lt: %s, ll: %s, lr: %s] and pos [%s]" % camera.limit_bottom, camera.limit_top, camera.limit_left, camera.limit_right, pp)


func get_play_area_size() -> Vector2:
	return play_area_shape.get_shape().size

func get_play_area_pos() -> Vector2:
	return play_area_shape.global_position

# Returns cursor position if the area is not buildable
# Returns tilemap position if the area is buildable
func get_current_buildable_pos() -> Vector2:
	var world_pos: Vector2 = _tilemap.get_local_mouse_position()
	var map_pos: Vector2 = _tilemap.local_to_map(world_pos)
	var cell_at_mouse: int = _tilemap.get_cell_source_id(BUILDABLE_AREA_LAYER, map_pos)
	var mouse_is_on_buildable_cell: bool = cell_at_mouse != -1

	if mouse_is_on_buildable_cell:
		var clamped_world_pos: Vector2 = _tilemap.map_to_local(map_pos)

		return clamped_world_pos
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()

		return mouse_pos

func can_build_at_mouse_pos() -> bool:
	var world_pos: Vector2 = _tilemap.get_local_mouse_position()
	var map_pos: Vector2 = _tilemap.local_to_map(world_pos)
	var buildable_area_cell_exists_at_pos: bool = _tilemap.get_cell_source_id(BUILDABLE_AREA_LAYER, map_pos) != -1

	return buildable_area_cell_exists_at_pos


# NOTE: layer index is double floor index because between
# each floor there is a layer for connecting wall tiles.
func world_height_to_z_index(height: float) -> int:
	var floor_index: int = height / Constants.TILE_HEIGHT
	var layer_index: int = min(floor_index * 2, _tilemap.get_layers_count() - 1)
	var layer_z_index: int = _tilemap.get_layer_z_index(layer_index)

	return layer_z_index
