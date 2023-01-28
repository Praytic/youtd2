extends Node


var preloaded_towers: Dictionary
var towers_dir: String = "res://Scenes/Towers/Instances"
# var tower_props: Dictionary


func _init():
	# Merge JSON props with references to other JSON props into one
	# var tower_props_flattened = _flattened_properties()
	
	# Load all tower resources to dict and associate them with tower IDs
	var regex = RegEx.new()
	regex.compile("^(?!\\.).*\\.tscn$")
	var tower_files = Utils.list_files_in_directory(towers_dir, regex)
	for tower_file in tower_files:
		var tower_template = load("%s/%s" % [towers_dir, tower_file])
		var tower_name = tower_file.get_slice(".", 0)
		var tower_id: int = Properties.tower_id_map[tower_name]
		preloaded_towers[tower_id] = tower_template
	
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
