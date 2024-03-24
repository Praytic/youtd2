extends Node


# Provides lookup for nodes via uid. Note that uid ranges
# can be different for each group.


var _group_map: Dictionary = {}


#########################
###       Public      ###
#########################

func add(group_name: String, node: Node, uid: int):
	node.add_to_group(group_name)

	if !_group_map.has(group_name):
		_group_map[group_name] = {}

	_group_map[group_name][uid] = node


func get_by_uid(group_name: String, uid: int) -> Node:
	if !_group_map.has(group_name):
		return null

	if !_group_map[group_name].has(uid):
		return null

	var is_valid: bool = is_instance_valid(_group_map[group_name][uid])

	if !is_valid:
		return 

	var node: Node = _group_map[group_name][uid]

	if node.is_queued_for_deletion():
		return null

	return node


func reset():
	_group_map = {}
