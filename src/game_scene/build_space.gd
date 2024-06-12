class_name BuildSpace extends Node


# Keeps track of spaces which are occupied by towers.


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

var _occupied_map: Dictionary = {}
var _buildable_cells: Dictionary = {}


#########################
###       Public      ###
#########################

func set_buildable_cells(buildable_cells: Array[Vector2i]):
	for cell in buildable_cells:
		_buildable_cells[cell] = true


# NOTE: must be called while tower is in scene tree
func set_occupied_by_tower(tower: Tower, value: bool):
	var occupied_list: Array[Vector2i] = _get_positions_occupied_by_tower(tower)

	for pos in occupied_list:
		_occupied_map[pos] = value


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

	for i in range(0, 4):
		var quarter_pos: Vector2i = quarter_list[i]
		var quarter_pos_is_occupied: bool = _occupied_map.get(quarter_pos, false)
		var quarter_is_buildable: bool = _buildable_cells.has(quarter_pos)

		build_info[i] = !quarter_pos_is_occupied && quarter_is_buildable

	return build_info


func can_build_at_pos(global_pos: Vector2) -> bool:
	var build_info: Array = get_build_info_for_pos(global_pos)
	var can_build: bool = !build_info.has(false)

	return can_build


func can_transform_at_pos(pos_mouse: Vector2) -> bool:
	var transform_is_allowed: bool = Globals.game_mode_allows_transform()
	var tower_under_mouse: Tower = Utils.get_tower_at_canvas_pos(pos_mouse)
	var attempting_to_transform: bool = tower_under_mouse != null
	var can_transform: bool = attempting_to_transform && transform_is_allowed

	return can_transform


func buildable_cell_exists_at_pos(pos_map: Vector2i) -> bool:
	var result: bool = _buildable_cells.has(pos_map)

	return result


#########################
###      Private      ###
#########################

func _convert_pos_canvas_to_map(pos_canvas: Vector2) -> Vector2i:
	var pos_top_down: Vector2 = VectorUtils.canvas_to_top_down(pos_canvas)
	var pos_top_down_rotated: Vector2 = pos_top_down.rotated(deg_to_rad(-45))
	var pos_top_down_rotated_snapped: Vector2 = pos_top_down_rotated.snapped(Vector2(Constants.TILE_SIZE_PIXELS_HALF, Constants.TILE_SIZE_PIXELS_HALF))
	var pos_map_float: Vector2 = (pos_top_down_rotated_snapped / Constants.TILE_SIZE_PIXELS_HALF).round()
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
