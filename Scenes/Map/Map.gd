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

# List of offsets from tower center position which are used
# to generate positions of quarter tiles.
const QUARTER_OFFSET_LIST_NORMAL: Array[Vector2] = [
	Constants.TILE_SIZE * Vector2(0, -0.25),
	Constants.TILE_SIZE * Vector2(0, 0.25),
	Constants.TILE_SIZE * Vector2(0.25, 0),
	Constants.TILE_SIZE * Vector2(-0.25, 0),
]

# Alternative list for Maverick builder which doesn't allow
# adjacent towers.
const QUARTER_OFFSET_LIST_BIG: Array[Vector2] = [
	Constants.TILE_SIZE * Vector2(0, 0.25),
	Constants.TILE_SIZE * Vector2(0, -0.25),
	Constants.TILE_SIZE * Vector2(0.25, 0),
	Constants.TILE_SIZE * Vector2(-0.25, 0),

	Constants.TILE_SIZE * Vector2(0.75, 0),
	Constants.TILE_SIZE * Vector2(-0.75, 0),
	Constants.TILE_SIZE * Vector2(0, 0.75),
	Constants.TILE_SIZE * Vector2(0, -0.75),

	Constants.TILE_SIZE * Vector2(0.75, 0),
	Constants.TILE_SIZE * Vector2(-0.75, 0),
	Constants.TILE_SIZE * Vector2(0, 0.75),
	Constants.TILE_SIZE * Vector2(0, -0.75),

	Constants.TILE_SIZE * Vector2(0.25, 0.5),
	Constants.TILE_SIZE * Vector2(-0.25, 0.5),
	Constants.TILE_SIZE * Vector2(0.25, -0.5),
	Constants.TILE_SIZE * Vector2(-0.25, -0.5),

	Constants.TILE_SIZE * Vector2(0.5, 0.25),
	Constants.TILE_SIZE * Vector2(-0.5, 0.25),
	Constants.TILE_SIZE * Vector2(0.5, -0.25),
	Constants.TILE_SIZE * Vector2(-0.5, -0.25),
]

var _occupied_quarter_list: Array[Vector2] = []


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


func get_mouse_pos_on_tilemap_clamped() -> Vector2:
	var world_pos: Vector2 = _buildable_area.get_local_mouse_position()
	var map_pos: Vector2 = _buildable_area.local_to_map(world_pos)
	var clamped_world_pos: Vector2 = _buildable_area.map_to_local(map_pos)
	var clamped_global_pos: Vector2 = _buildable_area.to_global(clamped_world_pos)
	var center: Vector2 = clamped_global_pos

#	NOTE: after clamping, we also need to further modify
#	position so it's on the closest corner of the currently
#	moused over quarter tile. This is because buildable
#	tiles are quarter-sized and the tower will be built on a
#	corner/intersection of the quarter tile, not the center
#	of the quarter tile!
	var corner_pos_list: Array = [
		center + Constants.TILE_SIZE * Vector2(0, -0.25),
		center + Constants.TILE_SIZE * Vector2(0.25, 0),
		center + Constants.TILE_SIZE * Vector2(0, 0.25),
		center + Constants.TILE_SIZE * Vector2(-0.25, 0),
	]

	var min_corner_pos: Vector2 = corner_pos_list[0]
	var min_distance: float = 1000000000

	for corner_pos in corner_pos_list:
		var distance: float = corner_pos.distance_squared_to(center)

		if distance < min_distance:
			min_corner_pos = corner_pos
			min_distance = distance

	var clamped_pos: Vector2 = min_corner_pos

	return clamped_pos


func can_build_at_mouse_pos() -> bool:
	var build_info: Array = get_build_info_for_mouse_pos()
	var can_build: bool = !build_info.has(false)

	return can_build


# Returns an array of 4 bools, one per quarter tile. True if
# the quarter is buildable tile and is not occupied by a
# tower. Order: [up, right, down, left]
func get_build_info_for_mouse_pos() -> Array:
	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var quarter_list: Array = [
		pos + Constants.TILE_SIZE * Vector2(0, -0.25),
		pos + Constants.TILE_SIZE * Vector2(0.25, 0),
		pos + Constants.TILE_SIZE * Vector2(0, 0.25),
		pos + Constants.TILE_SIZE * Vector2(-0.25, 0),
	]

	var build_info: Array = [false, false, false, false]
	
	for i in range(0, 4):
		var quarter_pos: Vector2 = quarter_list[i]
		var quarter_pos_is_occupied: bool = quarter_is_occupied(quarter_pos)

		var local_pos: Vector2 = _buildable_area.to_local(quarter_pos)
		var map_pos: Vector2 = _buildable_area.local_to_map(local_pos)
		var buildable_area_cell_exists_at_pos: bool = _buildable_area.get_cell_source_id(0, map_pos) != -1
		var quarter_is_buildable: bool = buildable_area_cell_exists_at_pos

		build_info[i] = !quarter_pos_is_occupied && quarter_is_buildable

	return build_info


func can_transform_at_mouse_pos() -> bool:
	if !Globals.game_mode_allows_transform():
		return false

	var pos: Vector2 = get_mouse_pos_on_tilemap_clamped()
	var there_is_a_tower_under_mouse: bool = Utils.tower_exists_on_position(pos)
	var can_transform: bool = there_is_a_tower_under_mouse

	return can_transform


func get_mouse_world_pos() -> Vector2:
	var out: Vector2 = _buildable_area.get_local_mouse_position()

	return out


func pos_is_on_ground(pos: Vector2) -> bool:
	var map_pos = _ground_indicator_map.local_to_map(pos)
	var tile_data_at_pos: TileData = _ground_indicator_map.get_cell_tile_data(0, map_pos)
	var tile_exists: bool = tile_data_at_pos != null

	return tile_exists


func quarter_is_occupied(pos: Vector2) -> bool:
	var occupied: bool = _occupied_quarter_list.has(pos)

	return occupied


func set_buildable_area_visible(value: bool):
	_buildable_area.visible = value


#########################
###      Private      ###
#########################

func _get_positions_occupied_by_tower(tower: Tower) -> Array[Vector2]:
#	NOTE: need to use visual position because tower's
#	"position" is on 1st floor and occupied positions are
#	tracked in terms of 2nd floor
	var pos_list: Array[Vector2] = []
	var visual_position: Vector2 = tower.position - Vector2(0, Constants.TILE_SIZE.y)
	var player: Player = tower.get_player()
	var builder: Builder = player.get_builder()

	for offset in _get_quarter_offset_list(builder):
		var pos: Vector2 = visual_position + offset
		pos_list.append(pos)

	return pos_list


func _get_quarter_offset_list(builder: Builder) -> Array[Vector2]:
	if builder.get_allow_adjacent_towers():
		return QUARTER_OFFSET_LIST_NORMAL
	else:
		return QUARTER_OFFSET_LIST_BIG


#########################
###     Callbacks     ###
#########################

# When tower is sold, mark space which is occupied by tower.
func add_space_occupied_by_tower(tower: Tower):
	var occupied_list: Array[Vector2] = _get_positions_occupied_by_tower(tower)

	for pos in occupied_list:
		_occupied_quarter_list.append(pos)


# When tower is sold, clear space which was used to be
# occupied by tower
func clear_space_occupied_by_tower(tower: Tower):
	var occupied_list: Array[Vector2] = _get_positions_occupied_by_tower(tower)

	for pos in occupied_list:
		_occupied_quarter_list.erase(pos)
