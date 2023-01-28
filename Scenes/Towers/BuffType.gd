extends Node

# BuffType stores buff description, creates buff instances
# and applies them to mobs. It should be created once in
# tower script's _init() function and used inside trigger
# functions to apply buffs on mobs. Call apply() or
# apply_custom_timed() to apply the buff on a unit. You must
# call add_child() on the buff after creating it.

class_name BuffType


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
			current_buff.stop()

			apply_custom_timed_internal(tower, target, value_modifier, duration)
	else:
		apply_custom_timed_internal(tower, target, value_modifier, duration)


func apply_custom_timed_internal(tower: Tower, target: Mob, value_modifier: float, duration: float):
	var buff: Buff = Buff.new(tower, target, value_modifier, duration, modifier)
	add_child(buff)
	active_buff_map[target] = buff
	buff.connect("expired", self, "on_buff_expired")


func on_buff_expired(buff: Buff):
	active_buff_map.erase(buff.target)
