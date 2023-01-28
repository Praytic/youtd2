extends Node

# Buff stores information about modifiers and handles the
# application state on units. It should be created once in
# tower script's _init() function and used inside trigger
# functions to apply modifiers on units. Call apply() or
# apply_custom_timed() to apply the buff on a unit. You must
# call add_child() on the buff after creating it.

class_name Buff


class ApplyData:
	var tower: Tower
	var target: Mob
	var value_modifier: float
	var duration_timer: Timer

	func _init(tower_arg: Tower, target_arg: Mob, value_modifier_arg: float, duration_timer_arg: Timer):
		tower = tower_arg
		target = target_arg
		value_modifier = value_modifier_arg
		duration_timer = duration_timer_arg


var duration_default: float

var modifier: Modifier = null
# Mapping of target->apply data. This map is used to know when
# a buff is already applied on target.
var apply_map: Dictionary = {}


func _init(duration_default_arg: float):
	duration_default = duration_default_arg


func set_modifier(modifier_arg: Modifier):
	modifier = modifier_arg


func apply(tower: Tower, target: Mob, value_modifier: float):
	apply_custom_timed(tower, target, value_modifier, duration_default)


#	TODO: implement stacking behavior based on this article:
#	https://www.gamedeveloper.com/design/a-status-effect-stacking-algorithm
#	Current stacking behavior is simplistic with only
#	stronger or equal buffs being able to override weaker
#	buffs and prolong the effect.
func apply_custom_timed(tower: Tower, target: Mob, value_modifier: float, duration: float):
	var is_already_applied_to_target: bool = apply_map.has(target)

	if is_already_applied_to_target:
		var old_apply: ApplyData = apply_map[target]
		var old_apply_level: int = old_apply.tower.level
		var new_apply_level: int = tower.level
		var should_override: bool = new_apply_level >= old_apply_level

		if should_override:
			on_duration_timer_timeout(old_apply.tower, old_apply.target, old_apply.value_modifier, old_apply.duration_timer)

			apply_custom_timed_internal(tower, target, value_modifier, duration_default)
	else:
		apply_custom_timed_internal(tower, target, value_modifier, duration_default)


func apply_custom_timed_internal(tower: Tower, target: Mob, value_modifier: float, duration: float):
	var duration_timer: Timer = Timer.new()
	add_child(duration_timer)

#	Record that the buff is active on the target
	var apply_data: ApplyData = ApplyData.new(tower, target, value_modifier, duration_timer)
	apply_map[target] = apply_data

	if modifier != null:
		modifier.apply(target, value_modifier)

	duration_timer.connect("timeout", self, "on_duration_timer_timeout", [tower, target, value_modifier, duration_timer])
	duration_timer.start(duration)


func on_duration_timer_timeout(tower: Tower, target: Mob, value_modifier: float, duration_timer: Timer):
	duration_timer.queue_free()

	if modifier != null:
		modifier.undo_apply(target, value_modifier)

	apply_map.erase(target)
