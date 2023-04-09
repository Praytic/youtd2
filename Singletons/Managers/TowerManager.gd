extends Node


var preloaded_towers: Dictionary
const towers_dir: String = "res://Scenes/Towers/Instances"
const PRINT_SCRIPT_NOT_FOUND_ERROR: bool = false
const PRINT_SCENE_NOT_FOUND_ERROR: bool = false
var _fallback_scene: PackedScene = preload("res://Scenes/Towers/Tower.tscn")
# var tower_props: Dictionary



func _ready():
	# Merge JSON props with references to other JSON props into one
	# var tower_props_flattened = _flattened_properties()
	
	# Load all tower resources to dict and associate them with tower IDs

	var preload_towers: bool = FF.preload_all_towers_on_startup()

	if preload_towers:
		var tower_id_list: Array = Properties.get_tower_id_list()

		for tower_id in tower_id_list:
			var tower_scene: PackedScene = _get_tower_scene(tower_id)

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


# Return new unique instance of the Tower by its ID. Get
# script for tower and attach to scene. Script name matches
# with scene name so this can be done automatically instead
# of having to do it by hand in scene editor.
func get_tower(id: int) -> Tower:
	var loaded_already: bool = preloaded_towers.has(id)

	if !loaded_already:
		var tower_scene: PackedScene = _get_tower_scene(id)

		preloaded_towers[id] = tower_scene
	
	var scene: PackedScene = preloaded_towers[id]
	var tower = scene.instantiate()
	var tower_script_path: String = _get_tower_script_path(id)
	var tower_script = load(tower_script_path)
	tower.set_script(tower_script)
	tower.set_id(id)

	var using_fallback_scene: bool = scene == _fallback_scene
	if using_fallback_scene:
		tower.enable_default_sprite()

	return tower


func get_tower_family_id(id: int) -> int:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	return csv_properties[Tower.CsvProperty.FAMILY_ID]


# Get path of tower script based on tower scene name. If
# scene name is TinyShrub4.tscn, then script name will be
# TinyShrub1.gd
func _get_tower_script_path(id: int) -> String:
	var family_name: String = _get_family_name(id)
	var path: String = "%s/%s1.gd" % [towers_dir, family_name]

	var script_exists: bool = FileAccess.file_exists(path)

	if script_exists:
		return path
	else:
		if PRINT_SCRIPT_NOT_FOUND_ERROR:
			print_debug("No script found for id:", id, ". Tried at path:", path)

		return "res://Scenes/Towers/Tower.gd"


# Scene filename = [name of first tier tower in family] +
# tier For example for "Greater Shrub" = "TinyShrub3.tscn"
func _get_tower_scene(id: int) -> PackedScene:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	var family_name: String = _get_family_name(id)
	var tier: String = csv_properties[Tower.CsvProperty.TIER]
	var scene_path: String = "%s/%s%s.tscn" % [towers_dir, family_name, tier]

	var scene_exists: bool = FileAccess.file_exists(scene_path)
	if scene_exists:
		var scene: PackedScene = load(scene_path)

		return scene
	else:
		if PRINT_SCENE_NOT_FOUND_ERROR:
			print_debug("No scene found for id:", id, ". Tried at path:", scene_path)

		return _fallback_scene


# Family name is the name of the first tier tower in the
# family, with spaces removed. Used to construct filenames
# for tower scenes and scripts.
func _get_family_name(id: int) -> String:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)

	if csv_properties.is_empty():
		return ""

	var family_id_string: String = csv_properties[Tower.CsvProperty.FAMILY_ID]
	var towers_in_family: Array = Properties.get_tower_csv_properties_by_filter(Tower.CsvProperty.FAMILY_ID, family_id_string)

	var first_tier_tower: Dictionary = {}

	for this_tower in towers_in_family:
		var this_tier: int = this_tower[Tower.CsvProperty.TIER].to_int()

		if this_tier == 1:
			first_tier_tower = this_tower

			break

	if first_tier_tower.is_empty():
		return ""

	var first_tier_name: String = first_tier_tower[Tower.CsvProperty.NAME]
	var family_name: String = first_tier_name.replace(" ", "")

	return family_name
