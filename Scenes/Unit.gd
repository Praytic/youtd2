class_name Unit
extends KinematicBody2D


# Unit implements application of buffs and modifications.

# NOTE: can't use static typing for Buff because of cyclic
# dependency


var level: int = 1
var buff_map: Dictionary
var modifier_list: Array

func _ready():
	pass


func apply_buff(buff):
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = buff_map.has(buff_id)
	
	var override_success: bool = false

	if is_already_applied_to_target:
		var current_buff = buff_map[buff_id]
		var should_override: bool = buff.power_level >= current_buff.power_level

		if should_override:
			current_buff.stop()
			override_success = true

	if !is_already_applied_to_target || override_success:
		buff_map[buff_id] = buff
		buff.target = self
		buff.connect("expired", self, "_on_buff_expired", [buff])
		_apply_buff_internal(buff, 1)
		add_child(buff)


func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, level, 1)
	modifier_list.append(modifier)


# TODO: not sure how to implement remove_modifier(). Maybe
# assign modifiers an id in add_modifier()? Need to see
# concrete use case for removing modifiers first. Will
# probably encounter it when implementing items.


func _change_level(new_level: int):
	level = new_level

#	NOTE: re-add all modifiers to apply level bonus
	for modifier in modifier_list:
		_apply_modifier(modifier, level, -1)
		_apply_modifier(modifier, level, 1)


func _on_buff_expired(buff):
	_apply_buff_internal(buff, -1)

	var buff_id: String = buff.get_id()
	buff_map.erase(buff_id)
	buff.queue_free()


func modify_property(modification_type: int, value: float):
	_modify_property(modification_type, value)


func _modify_property(_modification_type: int, _value: float):
	pass


func _apply_buff_internal(buff, apply_direction: int):
	var modifier: Modifier = buff.modifier
	var modifier_level: int = buff.get_modifier_level()
	_apply_modifier(modifier, modifier_level, apply_direction)


func _apply_modifier(modifier: Modifier, modifier_level: int, apply_direction: int):
	var modification_list: Array = modifier.modification_list

	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (modifier_level - 1)
		var value: float = apply_direction * modification.value_base * level_bonus
		_modify_property(modification.type, value)
