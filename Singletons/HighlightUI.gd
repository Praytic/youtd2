extends Node


# Class for highlighting UI elements. Register possible
# targets using register_target(). Then use
# start_highlight() and stop_highlight() to highlight
# registered targets.


const HIGHLIGHT_PERIOD: float = 0.5


var _target_map: Dictionary = {}
var _active_tween_map: Dictionary = {}


# Register target by name. It will be available for
# highlighting.
func register_target(target_name: String, target: Control):
	if _target_map.has(target_name):
		push_error("Element with name [%s] is already registered" % target_name)

		return

	_target_map[target_name] = target


func start_highlight(target_name: String):
	var target: Control = _get_target(target_name)

	if target == null:
		return

	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", Color.YELLOW.darkened(0.2), HIGHLIGHT_PERIOD)
	tween.tween_property(target, "modulate", Color.WHITE, HIGHLIGHT_PERIOD)
	tween.set_loops()

	_active_tween_map[target_name] = tween


func stop_highlight(target_name: String):
	var target: Control = _get_target(target_name)

	if target == null:
		return

	if !_active_tween_map.has(target_name):
		push_error("There is no active tween for target with name [%s]" % target_name)

		return

	var tween: Tween = _active_tween_map[target_name]
	target.modulate = Color.WHITE
	tween.kill()


func _get_target(target_name: String) -> Control:
	if !_target_map.has(target_name):
		push_error("No target with name [%s] has been registered" % target_name)

		return null

	var target: Control = _target_map[target_name]

	return target
