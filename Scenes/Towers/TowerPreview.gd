class_name TowerPreview
extends Node2D


@onready var buildable_areas: Array = get_tree().get_nodes_in_group(Constants.Groups.BUILD_AREA_GROUP)


const opaque_red := Color(1, 0, 0, 0.5)
const opaque_green := Color(0, 1, 0, 0.5)

var tower_id: int
var _tower_instance: Node2D

@onready var _range_indicator: RangeIndicator = $RangeIndicator


func _ready():
	var tower_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var attack_range: float = tower_properties[Tower.CsvProperty.ATTACK_RANGE].to_float()

	_range_indicator.set_radius(attack_range)

	_tower_instance = TowerManager.get_tower_visual_only(tower_id)
	add_child(_tower_instance)


func _physics_process(_delta):
	_tower_instance.modulate = get_current_color()
	position = get_current_pos()


func get_current_color() -> Color:
	if is_buildable():
		return opaque_green
	else:
		return opaque_red


func is_buildable() -> bool:
	for buildable_area in buildable_areas:
		var world_pos = buildable_area.get_local_mouse_position()
		var map_pos = buildable_area.local_to_map(world_pos)
	
		if buildable_area.get_cell_source_id(0, map_pos) != -1 and buildable_area.can_build_at_pos(map_pos):
			return true
	return false

# Returns cursor position if the area is not buildable
# Returns limit_length tilemap position if the area is buildable
func get_current_pos() -> Vector2:
	var cur_pos_dict = {}
	for tile_map in buildable_areas:
		var world_pos = tile_map.get_local_mouse_position()
		var map_pos = tile_map.local_to_map(world_pos)
		var tile_cell = tile_map.get_cell_source_id(0, map_pos)
		if tile_cell != -1:
			var clamped_world_pos = tile_map.map_to_local(map_pos)
			#	Add half-tile because tower sprite position is at center
			#	Add tilemap position because it might not start at (0, 0) coordinates
			cur_pos_dict[tile_map] = clamped_world_pos + Vector2(32, 32) + tile_map.position
	
	var cur_pos_dict_size = cur_pos_dict.size()
	var cur_pos: Vector2
	if cur_pos_dict_size == 0:
		cur_pos = get_global_mouse_position()
	elif cur_pos_dict_size > 1:
		push_warning("Some buildable areas are overlapping: %s" % cur_pos_dict)
		cur_pos = cur_pos_dict.values()[0]
	else:
		cur_pos = cur_pos_dict.values()[0]
	
	return cur_pos
