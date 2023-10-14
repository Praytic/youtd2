extends Node2D

const BUILDABLE_AREA_LAYER: int = 3

@export var play_area: Area2D
@export var play_area_shape: CollisionShape2D
@export var _tilemap: TileMap
@export var _buildable_area: TileMap
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
	print_verbose("Set camera limits to [lb: %s, lt: %s, ll: %s, lr: %s] and pos [%s]" \
		% [camera.limit_bottom, camera.limit_top, camera.limit_left, camera.limit_right, pp])


func get_play_area_size() -> Vector2:
	return play_area_shape.get_shape().size

func get_play_area_pos() -> Vector2:
	return play_area_shape.global_position


func get_mouse_pos_on_tilemap_clamped() -> Vector2:
	var world_pos: Vector2 = _buildable_area.get_local_mouse_position()
	var map_pos: Vector2 = _buildable_area.local_to_map(world_pos)
	var clamped_world_pos: Vector2 = _buildable_area.map_to_local(map_pos)
	var clamped_global_pos = _buildable_area.to_global(clamped_world_pos)

	return clamped_global_pos


func mouse_is_over_buildable_tile() -> bool:
	var global_pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var local_pos: Vector2 = _buildable_area.to_local(global_pos)
	var map_pos: Vector2 = _buildable_area.local_to_map(local_pos)
	var buildable_area_cell_exists_at_pos: bool = _buildable_area.get_cell_source_id(0, map_pos) != -1

	return buildable_area_cell_exists_at_pos


func can_build_at_mouse_pos() -> bool:
	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var occupied: bool = BuildTower.position_is_occupied(pos)

	var buildable_tile: bool = mouse_is_over_buildable_tile()

	var can_build: bool = !occupied && buildable_tile

	return can_build


func can_transform_at_mouse_pos() -> bool:
	if Globals.game_mode == GameMode.enm.BUILD && !Config.allow_transform_in_build_mode():
		return false

	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var there_is_a_tower_under_mouse: bool = BuildTower.position_is_occupied(pos)
	var can_transform: bool = there_is_a_tower_under_mouse

	return can_transform


# NOTE: layer index is double floor index because between
# each floor there is a layer for connecting wall tiles.
# NOTE: need to add "+1" to floor index so that units are
# drawn inbetween floor layers. For example, creep standing
# on the ground with height=0 should be drawn above layer
# "floor1" but below layer "floor2". So we make it be drawn
# on layer "between 1/2".
func world_height_to_z_index(height: float) -> int:
	var floor_index: int = floor(height) / Constants.TILE_HEIGHT
	var layer_index: int = floor_index * 2 + 1
	var layer_z_index: int = layer_index * Constants.Z_INDEX_PER_LAYER

	return layer_z_index


func get_mouse_world_pos() -> Vector2:
	var out: Vector2 = _tilemap.get_local_mouse_position()

	return out


func get_layer_at_current_pos() -> int:
	return get_layer_at_pos(_tilemap.get_global_mouse_position())


func get_layer_at_pos(pos: Vector2) -> int:
#	var local_pos = _tilemap.to_local(pos)
	var cell_at_pos = _tilemap.local_to_map(pos)
	var result: int = -1
	for layer in range(_tilemap.get_layers_count() - 1, -1, -1):
		var data = _tilemap.get_cell_tile_data(layer, cell_at_pos)
		if data:
			result = layer
			break
	return result
