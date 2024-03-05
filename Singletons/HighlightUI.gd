extends Node


# Class for highlighting UI elements. Register possible
# targets using register_target(). Then use
# start_highlight() and stop_highlight() to highlight
# registered targets.

# When user does a specific action to acknowledge the highlighted
# area, this signal should be emitted.
signal highlight_target_ack(highlight_target: String)

const HIGHLIGHT_PERIOD: float = 0.5

var _target_map: Dictionary = {}
var _active_tween_map: Dictionary = {}


#########################
###       Public      ###
#########################

# Register target by name. It will be available for
# highlighting.
func register_target(target_name: String, target: Control, append: bool = false):
	if append and _target_map.has(target_name):
		_target_map[target_name].append(target)
	else:
		_target_map[target_name] = [target]


func start_highlight(target_name: String):
	var targets = _get_target_controls(target_name)

	if targets.is_empty():
		return

	for target in targets:
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
	var targets = _get_target_controls(target_name)

	if targets.is_empty():
		return

	if !_active_tween_map.has(target_name):
		push_error("There is no active tween for target with name [%s]" % target_name)

		return
	
	for target in targets:
		if is_instance_valid(target):
			for tween in _active_tween_map[target_name]:
				target.modulate = Color.WHITE
				tween.kill()
			target.z_index = 0


#########################
###      Private      ###
#########################

func _get_target_controls(target_name: String) -> Array:
	if !_target_map.has(target_name):
		push_error("No target with name [%s] has been registered" % target_name)

		return []

	var target = _target_map[target_name]

	return target
