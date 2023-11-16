extends Node2D


@export var play_area: Area2D
@export var play_area_shape: CollisionShape2D
@export var _tilemap: TileMap
@export var _buildable_area: TileMap
@onready var camera: Camera2D = %Map/Camera2D

const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.5
const BUILDABLE_PULSE_PERIOD = 1.0

var _floor2_layer: int = -1


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
	
	MouseState.mouse_state_changed.connect(_build_mode_changed)

#	Make buildable area pulse by tweening it's alpha between
#	min and max
	var buildable_area_tween = create_tween()
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MIN),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR)
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MAX),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR).set_delay(0.5 * BUILDABLE_PULSE_PERIOD)
	buildable_area_tween.set_loops()

	_floor2_layer = _find_floor2_layer()


func _build_mode_changed():
	_buildable_area.visible = MouseState.get_state() == MouseState.enm.BUILD_TOWER


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


func get_mouse_world_pos() -> Vector2:
	var out: Vector2 = _tilemap.get_local_mouse_position()

	return out


# NOTE: determine whether a position is on ground by
# checking if there's a floor2 tile at position. Need to do
# it this way instead of checking if there's floor1 tile at
# position. There are cases where there's both floor1 and
# floor2 tile on same position and for such cases position
# is considered "not on the ground".
func pos_is_on_ground(pos: Vector2) -> bool:
	var cell_at_pos = _tilemap.local_to_map(pos)
	var tile_data: TileData = _tilemap.get_cell_tile_data(_floor2_layer, cell_at_pos)
	var floor2_has_tile_at_pos: bool = tile_data != null
	var is_on_ground: bool = !floor2_has_tile_at_pos

	return is_on_ground


func _find_floor2_layer() -> int:
	for layer in range(0, _tilemap.get_layers_count()):
		var layer_name: String = _tilemap.get_layer_name(layer)

		if layer_name == "floor2":
			return layer

	return -1
