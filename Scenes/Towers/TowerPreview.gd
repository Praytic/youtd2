class_name TowerPreview
extends Node2D


onready var buildable_areas: Array = get_tree().get_nodes_in_group(Constants.Groups.BUILD_AREA_GROUP)


const opaque_red := Color("adff4545")
const opaque_green := Color("ad54ff3c")

var tower_id: int

onready var _area_of_effect: AreaOfEffect = $AreaOfEffect


func _ready():
	var tower_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var attack_range: float = tower_properties[Tower.CsvProperty.ATTACK_RANGE].to_float()

	_area_of_effect.set_radius(attack_range)

	var tower_instance = TowerManager.get_tower_visual_only(tower_id)
	add_child(tower_instance)


func _physics_process(_delta):
	modulate = get_current_color()
	position = get_current_pos()


func get_current_color() -> Color:
	if is_buildable():
		return opaque_green
	else:
		return opaque_red


func is_buildable() -> bool:
	for buildable_area in buildable_areas:
		var world_pos = buildable_area.get_local_mouse_position()
		var map_pos = buildable_area.world_to_map(world_pos)
	
		if buildable_area.get_cellv(map_pos) != TileMap.INVALID_CELL and buildable_area.can_build_at_pos(map_pos):
			return true
	return false

# Returns cursor position if the area is not buildable
# Returns clamped tilemap position if the area is buildable
func get_current_pos() -> Vector2:
	var cur_pos_dict = {}
	for tile_map in buildable_areas:
		var world_pos = tile_map.get_local_mouse_position()
		var map_pos = tile_map.world_to_map(world_pos)
		var tile_cell = tile_map.get_cellv(map_pos)
		if tile_cell != TileMap.INVALID_CELL:
			var clamped_world_pos = tile_map.map_to_world(map_pos)
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
