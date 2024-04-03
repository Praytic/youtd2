extends Node


# Class for highlighting UI elements. Register possible
# targets using register_target(). Then use
# start_highlight() and stop_highlight() to highlight
# registered targets.

const HIGHLIGHT_PERIOD: float = 0.5

var _target_map: Dictionary = {}
var _active_tween_map: Dictionary = {}


#########################
###       Public      ###
#########################

# Register target by name. It will be available for
# highlighting.
func register_target(target_name: String, target: Control):
	if !_target_map.has(target_name):
		_target_map[target_name] = []
	
	_target_map[target_name].append(target)

#	NOTE: need to remove target when it exits tree to avoid
#	using invalid reference
	if !target.tree_exited.is_connected(_on_target_tree_exited):
		target.tree_exited.connect(_on_target_tree_exited.bind(target))


func start_highlight(target_name: String):
	var target_list: Array = _get_target_controls(target_name)

	if target_list.is_empty():
		return

	for target in target_list:
#		NOTE: need to call create_tween() on target node so
#		that tween is bound to target and handles target
#		getting removed correctly
		var tween: Tween = target.create_tween()
		tween.tween_property(target, "modulate", Color.YELLOW.darkened(0.2), HIGHLIGHT_PERIOD)
		tween.tween_property(target, "modulate", Color.WHITE, HIGHLIGHT_PERIOD)
		tween.tween_property(target, "z_index", 3, HIGHLIGHT_PERIOD)
		tween.set_loops()

		if _active_tween_map.has(target_name):
			_active_tween_map[target_name].append(tween)
		else:
			_active_tween_map[target_name] = [tween]


func stop_highlight(target_name: String):
	var target_list: Array = _get_target_controls(target_name)

	if target_list.is_empty():
		return

	if !_active_tween_map.has(target_name):
		push_error("There is no active tween for target with name [%s]" % target_name)

		return

	for tween in _active_tween_map[target_name]:
		tween.kill()
	
	for target in target_list:
		if is_instance_valid(target):
			target.modulate = Color.WHITE
			target.z_index = 0


#########################
###      Private      ###
#########################

func _get_target_controls(target_name: String) -> Array:
	if !_target_map.has(target_name):
		push_error("No target with name [%s] has been registered" % target_name)

		return []

	var target_list: Array = _target_map[target_name]

	return target_list


#########################
###     Callbacks     ###
#########################

func _on_target_tree_exited(target: Control):
	for target_name in _target_map.keys():
		_target_map[target_name].erase(target)
