extends Button


signal buff_group_changed(group_number: int, mode: BuffGroup.Mode)


var _current_mode: BuffGroup.Mode = BuffGroup.Mode.NONE
@export var _buff_group_number: int


func _on_pressed():
	var previous_mode = get_current_mode()
	if previous_mode == BuffGroup.Mode.BOTH:
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), BuffGroup.Mode.INCOMING)
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), BuffGroup.Mode.OUTGOING)
	elif previous_mode != BuffGroup.Mode.NONE:
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), previous_mode)
	
	_current_mode = (_current_mode + 1) % BuffGroup.modes_list.size()
	if get_current_mode() == BuffGroup.Mode.BOTH:
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), BuffGroup.Mode.INCOMING)
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), BuffGroup.Mode.OUTGOING)
	elif get_current_mode() == BuffGroup.Mode.OUTGOING or get_current_mode() == BuffGroup.Mode.INCOMING:
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), get_current_mode())
	
	text = "%s (%s)" % [get_buff_group_number(), get_current_mode()]


func get_current_mode() -> BuffGroup.Mode:
	return BuffGroup.modes_list[_current_mode]


func get_buff_group_number() -> int:
	return _buff_group_number
