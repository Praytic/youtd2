extends Node


# TowerScriptManager stores loaded instances of tower
# scripts. Each tower script has it's own single script
# instance that is reused by tower instances. Use
# get_script_instance() to get the script instance.


# Mapping of script path->script instance
var script_instance_map: Dictionary = {}


func _init():
	for tower_info in Properties.towers.values():
		if !tower_info.has("script"):
			print_debug("Tower doesn't define a script:", tower_info["name"])

			continue

		var script_path: String = tower_info["script"]
		var script: Script = load(script_path)

		if script == null:
			print_debug("Failed to load tower script:", script_path)

			continue

		var script_instance = script.new()
		add_child(script_instance)
		script_instance_map[script_path] = script_instance


func get_script_instance(script_path: String) -> Node:
	if script_instance_map.has(script_path):
		var script_instance: Node = script_instance_map[script_path]

		return script_instance
	else:
		return null
