class_name Unit
extends KinematicBody2D


# Unit implements application of buffs and modifications.


var level: int = 1
var buff_map: Dictionary
var modifier_list: Array

func _ready():
	pass


func apply_buff(buff):
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = buff_map.has(buff_id)

	if is_already_applied_to_target:
		var current_buff = buff_map[buff_id]
		var should_override: bool = buff.power_level >= current_buff.power_level

		if should_override:
			current_buff.stop()
			_apply_buff_internal(buff)
	else:
		_apply_buff_internal(buff)


func add_modifier(modifier: Modifier):
	apply_modifier(modifier, level)
	modifier_list.append(modifier)


# TODO: not sure how to implement remove_modifier(). Maybe
# assign modifiers an id in add_modifier()? Need to see
# concrete use case for removing modifiers first. Will
# probably encounter it when implementing items.


func _change_level(new_level: int):
	level = new_level

#	NOTE: re-add all modifiers to apply level bonus
	for modifier in modifier_list:
		remove_modifier(modifier, level)
		apply_modifier(modifier, level)


# NOTE: applies buff without any checks for overriding
func _apply_buff_internal(buff):
	var buff_id: String = buff.get_id()
	print("buff_id=", buff_id)
	buff_map[buff_id] = buff
	add_child(buff)
	buff.on_apply_success(self)

	buff.connect("expired", self, "_on_buff_expired", [buff])


func _on_buff_expired(buff):
	var buff_id: String = buff.get_id()
	buff_map.erase(buff_id)


func modify_property(modification_type: int, value: float):
	_modify_property(modification_type, value)


func _modify_property(_modification_type: int, _value: float):
	pass


func apply_modifier(modifier: Modifier, modifier_level: int):
	_apply_modifier_with_direction(modifier, modifier_level, 1)


func remove_modifier(modifier: Modifier, modifier_level: int):
	_apply_modifier_with_direction(modifier, modifier_level, -1)


func _apply_modifier_with_direction(modifier: Modifier, modifier_level: int, apply_direction: int):
	var modification_list: Array = modifier.modification_list

	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (modifier_level - 1)
		var value: float = apply_direction * modification.value_base * level_bonus
		_modify_property(modification.type, value)
