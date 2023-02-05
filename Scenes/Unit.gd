class_name Unit
extends KinematicBody2D


signal selected
signal unselected
signal dead

# Unit implements application of buffs and modifications.

# NOTE: can't use static typing for Buff because of cyclic
# dependency


var _level: int = 1 setget set_level, get_level
var _buff_map: Dictionary
var _modifier_list: Array

func _ready():
	pass


func apply_buff(buff):
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = _buff_map.has(buff_id)
	
	var override_success: bool = false

	if is_already_applied_to_target:
		var current_buff = _buff_map[buff_id]
		var should_override: bool = buff.get_level() >= current_buff.get_level()

		if should_override:
			current_buff.stop()
			override_success = true

	if !is_already_applied_to_target || override_success:
		_buff_map[buff_id] = buff
		buff.connect("expired", self, "_on_buff_expired", [buff])
		var buff_modifier: Modifier = buff.get_modifier()
		_apply_modifier(buff_modifier, 1)
		add_child(buff)
		buff.applied_successfully(self)


func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, 1)
	_modifier_list.append(modifier)


# TODO: not sure how to implement remove_modifier(). Maybe
# assign modifiers an id in add_modifier()? Need to see
# concrete use case for removing modifiers first. Will
# probably encounter it when implementing items.


func set_level(new_level: int):
	_level = new_level

#	NOTE: apply level change to modifiers
	for modifier in _modifier_list:
		_apply_modifier(modifier, -1)
		modifier.level = new_level
		_apply_modifier(modifier, 1)


func get_level() -> int:
	return _level


func die():
	emit_signal("dead")
	queue_free()


func _on_buff_expired(buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, -1)

	var buff_id: String = buff.get_id()
	_buff_map.erase(buff_id)
	buff.queue_free()


func modify_property(modification_type: int, value: float):
	_modify_property(modification_type, value)


func _modify_property(_modification_type: int, _value: float):
	pass


func _apply_modifier(modifier: Modifier, apply_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var level_bonus: float = 1.0 + modification.level_add * (modifier.level - 1)
		var value: float = apply_direction * modification.value_base * level_bonus
		_modify_property(modification.type, value)
