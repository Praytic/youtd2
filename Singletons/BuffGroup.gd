extends Node


enum Mode {
	NONE = 0,
	OUTGOING = 1,
	INCOMING = 2,
	BOTH = 3,
}

const modes_list = [Mode.NONE, Mode.OUTGOING, Mode.INCOMING, Mode.BOTH]


func remove_unit_from_buff_group(group_number: int, mode: Mode):
	var calculated_group_name = "%s_%s" % [group_number, Mode.keys()[mode]]
	var current_unit = SelectUnit.get_selected_unit()
	current_unit.remove_from_group(calculated_group_name)
	print("Removed unit [%s] from buff group [%s]. Unit groups are: [%s]" % \
		[current_unit, calculated_group_name, current_unit.get_groups()])


func add_unit_to_buff_group(group_number: int, mode: Mode):
	var calculated_group_name = "%s_%s" % [group_number, Mode.keys()[mode]]
	var current_unit = SelectUnit.get_selected_unit()
	current_unit.add_to_group(calculated_group_name)
	print("Added unit [%s] to buff group [%s]. Unit groups are: [%s]" % \
		[current_unit, calculated_group_name, current_unit.get_groups()])
