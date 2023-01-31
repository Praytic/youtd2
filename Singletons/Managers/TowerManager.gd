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

#	NOTE: yes, this is very hacky way to get id.
#	Couldn't find a better solution without having to
#	duplicate id's outside tower scripts
	var tower_name_list: Array = get_tower_name_list()
	
	for tower_name in tower_name_list:
		var tower_script: String = "%s/%s.tscn" % [towers_dir, tower_name]
		var tower_scene: PackedScene = load(tower_script)
		var tower_instance: Tower = tower_scene.instance()
		var tower_id: int = tower_instance._get_base_properties()[Tower.Property.ID]

		preloaded_towers[tower_id] = tower_scene

		_tower_name_to_id_map[tower_name] = tower_id
		_tower_id_to_name_map[tower_id] = tower_name
	
	# # Change the key of the tower_props dict to ID instead of Filename
	# for key in tower_props_flattened:
	# 	tower_props[tower_props_flattened[key].id] = tower_props_flattened[key]


static func get_tower_name_list() -> Array:
	var regex = RegEx.new()
	regex.compile("^(?!\\.).*\\.tscn$")

	var tower_script_list: Array = Utils.list_files_in_directory(towers_dir, regex)

	var tower_name_list: Array = []

	for tower_script in tower_script_list:
		var tower_name: String = tower_script.trim_suffix(".tscn")
		tower_name_list.append(tower_name)

	return tower_name_list


func get_tower_id(tower_name: String) -> int:
	var tower_id: int = _tower_name_to_id_map[tower_name]

	return tower_id


func get_tower_name(tower_id: int) -> String:
	var tower_name: String = _tower_id_to_name_map[tower_id]

	return tower_name


func get_tower_id_list() -> Array:
	return _tower_id_to_name_map.keys()


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
