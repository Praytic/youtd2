extends Node


var preloaded_towers: Dictionary
const towers_dir: String = "res://Scenes/Towers/Instances"
var _tower_name_to_id_map: Dictionary = {}
var _tower_id_to_name_map: Dictionary = {}
# var tower_props: Dictionary



func _init():
	# Merge JSON props with references to other JSON props into one
	# var tower_props_flattened = _flattened_properties()
	
	# Load all tower resources to dict and associate them with tower IDs

	var tower_id_list: Array = Properties.get_tower_id_list()
	
	for tower_id in tower_id_list:
		var tower_properties: Dictionary = Properties.get_csv_properties(tower_id)
		var tower_filename: String = tower_properties[Tower.Property.FILENAME]

		var tower_script_path: String = "%s/%s.tscn" % [towers_dir, tower_filename]
		var tower_scene: PackedScene = load(tower_script_path)

		preloaded_towers[tower_id] = tower_scene

	# # Change the key of the tower_props dict to ID instead of Filename
	# for key in tower_props_flattened:
	# 	tower_props[tower_props_flattened[key].id] = tower_props_flattened[key]


# Merge JSON props with references to other JSON props into one
# func _flattened_properties() -> Dictionary:
# 	# var props: Dictionary = Properties.towers
# 	var props: Dictionary = {}
# 	var family_props: Dictionary = Properties.tower_families
# 	var flattened_props: Dictionary = {}
# 	for tower_name in props:
# 		var flattened_tower_props = props[tower_name]
# 		for key in family_props[flattened_tower_props.family_id]:
# 			flattened_tower_props[key] = family_props[flattened_tower_props.family_id][key]
# 		flattened_props[tower_name] = flattened_tower_props
# 	return flattened_props


# Return new unique instance of the Tower by its ID
func get_tower(id: int) -> PackedScene:
	var tower = preloaded_towers[id].instance()
	return tower
