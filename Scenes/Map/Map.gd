class_name Map extends Node2D


@export var play_area: Area2D
@export var play_area_shape: CollisionShape2D
@export var _black_border: Node2D
@export var _buildable_area: TileMap
@export var _prerendered_background: Node2D
@export var _foreground_map: TileMap
@export var _ground_indicator_map: TileMap

const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.5
const BUILDABLE_PULSE_PERIOD = 1.0
const TILE_SIZE_HALF: float = Constants.TILE_SIZE_PIXELS / 2

# List of offsets for getting 4 quarter tiles around a
# position at an intersection. These positions use the
# rotated top-down coordinate system, where tile origin is
# at the bottom left corner of the tile.
# NOTE: order is important because get_build_info_for_pos()
# depens on it.
const QUARTER_OFFSET_LIST_NORMAL: Array[Vector2i] = [
#	x.
#	..
	Vector2i(-1, 0),
#	.x
#	..
	Vector2i(0, 0),
#	..
#	.x
	Vector2i(0, 1),
#	..
#	x.
	Vector2i(-1, 1),
]

# Alternative list for Maverick builder which doesn't allow
# adjacent towers.
const QUARTER_OFFSET_LIST_BIG: Array[Vector2i] = [
#	Up-left
	Vector2i(-1, 0),
	Vector2i(-2, 0),
	Vector2i(-2, -1),
	Vector2i(-1, -1),

#	Up-right
	Vector2i(0, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	
#	Bottom-left
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, 2),
	Vector2i(0, 2),
	
#	Bottom-right
	Vector2i(-1, 1),
	Vector2i(-1, 2),
	Vector2i(-2, 2),
	Vector2i(-2, 1),
]

# NOTE: need to use Vector2i to avoid problems with Vector2
# being slightly not equal because of float components.
var _occupied_quarter_list: Array[Vector2i] = []


#########################
###     Built-in      ###
#########################

func _ready():
	var camera: Camera2D = get_viewport().get_camera_2d()
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

	_prerendered_background.visible = Config.use_prerendered_background()

#	NOTE: create real tilemap if not using prerendered
#	version. We do this here instead of in scene to avoid
#	the real tilemap eating VRAM while being hidden.
	if !Config.use_prerendered_background():
		print_verbose("Using raw map (not prerendered)")
		var background_map_scene: PackedScene = load("res://Scenes/Map/BackgroundMap.tscn")
		var background_map = background_map_scene.instantiate()
		_buildable_area.add_sibling(background_map)
	else:
		print_verbose("Using prerendered map")


#########################
###       Public      ###
#########################

func setup_for_prerendering():
	_prerendered_background.hide()
	_black_border.hide()
	_foreground_map.hide()


func get_play_area_size() -> Vector2:
	return play_area_shape.get_shape().size


func get_play_area_pos() -> Vector2:
	return play_area_shape.global_position


# NOTE: this f-n needs to rotate the position because canvas
# coordinates have North pointing to up-right direction
# while top down map coordinates have North pointing to up
# direction
func get_pos_on_tilemap_clamped(pos_canvas: Vector2) -> Vector2:
	var pos_top_down: Vector2 = VectorUtils.canvas_to_top_down(pos_canvas)
	var pos_top_down_rotated: Vector2 = Vector2(pos_top_down.rotated(deg_to_rad(-45)))
	var pos_top_down_rotated_snapped: Vector2 = pos_top_down_rotated.snapped(Vector2(TILE_SIZE_HALF, TILE_SIZE_HALF))
	var pos_top_down_snapped: Vector2 = pos_top_down_rotated_snapped.rotated(deg_to_rad(45))
	var pos_canvas_snapped: Vector2 = VectorUtils.top_down_to_canvas(pos_top_down_snapped)

	return pos_canvas_snapped


func can_build_at_pos(global_pos: Vector2) -> bool:
	var build_info: Array = get_build_info_for_pos(global_pos)
	var can_build: bool = !build_info.has(false)

	return can_build


# Returns an array of 4 bools, one per quarter tile. True if
# the quarter is buildable tile and is not occupied by a
# tower. Order: [up, right, down, left]
func get_build_info_for_pos(pos_canvas: Vector2) -> Array:
	var pos_map: Vector2i = _convert_pos_canvas_to_map(pos_canvas)
	var quarter_list: Array[Vector2i] = []

	for offset in QUARTER_OFFSET_LIST_NORMAL:
		var quarter_pos: Vector2i = pos_map + offset
		quarter_list.append(quarter_pos)

	var build_info: Array = [false, false, false, false]

	var buildable_cells: Array[Vector2i] = _buildable_area.get_used_cells(0)
	
	for i in range(0, 4):
		var quarter_pos: Vector2i = quarter_list[i]
		var quarter_pos_is_occupied: bool = _occupied_quarter_list.has(quarter_pos)
		var quarter_is_buildable: bool = buildable_cells.has(quarter_pos)

		build_info[i] = !quarter_pos_is_occupied && quarter_is_buildable

	return build_info


func can_transform_at_pos(world_pos: Vector2) -> bool:
	if !Globals.game_mode_allows_transform():
		return false

	var pos: Vector2 = get_pos_on_tilemap_clamped(world_pos)
	var there_is_a_tower_under_mouse: bool = Utils.tower_exists_on_position(pos)
	var can_transform: bool = there_is_a_tower_under_mouse

	return can_transform


func pos_is_on_ground(pos: Vector2) -> bool:
	var map_pos = _ground_indicator_map.local_to_map(pos)
	var tile_data_at_pos: TileData = _ground_indicator_map.get_cell_tile_data(0, map_pos)
	var tile_exists: bool = tile_data_at_pos != null

	return tile_exists


func set_buildable_area_visible(value: bool):
	_buildable_area.visible = value


# When tower is sold, mark space which is occupied by tower.
# NOTE: must be called after adding tower to scene tree
func add_space_occupied_by_tower(tower: Tower):
	var occupied_list: Array[Vector2i] = _get_positions_occupied_by_tower(tower)

	for pos in occupied_list:
		_occupied_quarter_list.append(pos)


# When tower is sold, clear space which was used to be
# occupied by tower
func clear_space_occupied_by_tower(tower: Tower):
	var occupied_list: Array[Vector2i] = _get_positions_occupied_by_tower(tower)

	for pos in occupied_list:
		_occupied_quarter_list.erase(pos)


#########################
###      Private      ###
#########################

func _convert_pos_canvas_to_map(pos_canvas: Vector2) -> Vector2i:
	var pos_top_down: Vector2 = VectorUtils.canvas_to_top_down(pos_canvas)
	var pos_top_down_rotated: Vector2 = pos_top_down.rotated(deg_to_rad(-45))
	var pos_top_down_rotated_snapped: Vector2 = pos_top_down_rotated.snapped(Vector2(TILE_SIZE_HALF, TILE_SIZE_HALF))
	var pos_map_float: Vector2 = (pos_top_down_rotated_snapped / TILE_SIZE_HALF).round()
	var pos_map: Vector2i = Vector2i(pos_map_float)

	return pos_map


func _get_positions_occupied_by_tower(tower: Tower) -> Array[Vector2i]:
	var pos_canvas: Vector2 = tower.get_visual_position()
	var player: Player = tower.get_player()
	var builder: Builder = player.get_builder()
	var pos_map: Vector2i = _convert_pos_canvas_to_map(pos_canvas)
	
	var pos_list: Array[Vector2i] = []
	for offset in _get_quarter_offset_list(builder):
		var pos: Vector2i = pos_map + offset
		pos_list.append(pos)
	
	return pos_list


func _get_quarter_offset_list(builder: Builder) -> Array[Vector2i]:
	if builder.get_allow_adjacent_towers():
		return QUARTER_OFFSET_LIST_NORMAL
	else:
		return QUARTER_OFFSET_LIST_BIG
