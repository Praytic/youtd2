extends Node


var preloaded_towers: Dictionary
const towers_dir: String = "res://Scenes/Towers/Instances"
const PRINT_SCRIPT_NOT_FOUND_ERROR: bool = false
const PRINT_SCENE_NOT_FOUND_ERROR: bool = false
var _fallback_scene: PackedScene = preload("res://Scenes/Towers/Tower.tscn")
# var tower_props: Dictionary



func _init():
	# Merge JSON props with references to other JSON props into one
	# var tower_props_flattened = _flattened_properties()
	
	# Load all tower resources to dict and associate them with tower IDs

	var tower_id_list: Array = Properties.get_tower_id_list()
	
	for tower_id in tower_id_list:
		var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
		var tower_scene_name: String = csv_properties[Tower.CsvProperty.SCENE_NAME]

		var tower_scene_path: String = "%s/%s.tscn" % [towers_dir, tower_scene_name]
		var tower_scene_exists: bool = FileAccess.file_exists(tower_scene_path)

		var tower_scene: PackedScene
		if tower_scene_exists:
			tower_scene = load(tower_scene_path)
		else:
			if PRINT_SCENE_NOT_FOUND_ERROR:
				print_debug("No scene found for id:", tower_id, ". Tried at path:", tower_scene_path)

			tower_scene = _fallback_scene

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


func get_tower_visual_only(id: int) -> Node:
	var tower = get_tower(id)
	var dummy_script = load("res://Scenes/Towers/DummyScript.gd")

	tower.set_script(dummy_script)

	return tower


func get_tower_family_id(id: int) -> int:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	return csv_properties[Tower.CsvProperty.FAMILY_ID]


# Get path of tower script based on tower scene name. If
# scene name is TinyShrub4.tscn, then script name will be
# TinyShrub1.gd
func _get_tower_script_path(id: int) -> String:
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	var scene_name: String = properties[Tower.CsvProperty.SCENE_NAME]
# 	NOTE: strip the tier digit from scene name
	var script_name: String = scene_name.substr(0, scene_name.length() - 1)
	var path: String = "%s/%s1.gd" % [towers_dir, script_name]

	var script_exists: bool = FileAccess.file_exists(path)

	if script_exists:
		return path
	else:
		if PRINT_SCRIPT_NOT_FOUND_ERROR:
			print_debug("No script found for id:", id, ". Tried at path:", path)

		return "res://Scenes/Towers/Tower.gd"
