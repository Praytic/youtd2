extends Node

# BuffType stores information about modifiers and handles
# the application state on units. It should be created once
# in tower script's _init() function and used inside trigger
# functions to apply modifiers on units. Call apply() or
# apply_custom_timed() to apply the buff on a unit. You must
# call add_child() on the buff after creating it.

class_name BuffType


class Buff:
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
# Mapping of target->Buff
var active_buff_map: Dictionary = {}


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
	var is_already_applied_to_target: bool = active_buff_map.has(target)

	if is_already_applied_to_target:
		var current_buff: Buff = active_buff_map[target]
		var current_buff_level: int = current_buff.tower.level
		var new_buff_level: int = tower.level
		var should_override: bool = new_buff_level >= current_buff_level

		if should_override:
			on_duration_timer_timeout(current_buff)

			apply_custom_timed_internal(tower, target, value_modifier, duration_default)
	else:
		apply_custom_timed_internal(tower, target, value_modifier, duration_default)


func apply_custom_timed_internal(tower: Tower, target: Mob, value_modifier: float, duration: float):
	var duration_timer: Timer = Timer.new()
	add_child(duration_timer)

#	Record that the buff is active on the target
	var buff: Buff = Buff.new(tower, target, value_modifier, duration_timer)
	active_buff_map[target] = buff

	if modifier != null:
		modifier.apply(target, value_modifier)

	duration_timer.connect("timeout", self, "on_duration_timer_timeout", [buff])
	duration_timer.start(duration)


func on_duration_timer_timeout(buff: Buff):
	var duration_timer: Timer = buff.duration_timer
	duration_timer.queue_free()

#	NOTE: target can become invalid if it dies before the
#	buff expires.
	var target: Mob = buff.target
	if modifier != null && is_instance_valid(target):
		var value_modifier: float = buff.value_modifier
		modifier.undo_apply(target, value_modifier)

	active_buff_map.erase(target)
