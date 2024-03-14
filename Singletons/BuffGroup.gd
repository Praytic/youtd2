extends Node


enum Mode {
	NONE = 0,
	OUTGOING = 1,
	INCOMING = 2,
	BOTH = 3,
}

const modes_list = [Mode.NONE, Mode.OUTGOING, Mode.INCOMING, Mode.BOTH]


func remove_unit_from_buff_group(tower: Tower, group_number: int, mode: Mode):
	var calculated_group_name = get_buff_group_name(group_number, mode)
	tower.get_buff_groups().erase(calculated_group_name)
	print_verbose("Removed unit [%s] from buff group [%s]. Unit groups are: %s" % \
		[tower, calculated_group_name, tower.get_buff_groups()])


func add_unit_to_buff_group(tower: Tower, group_number: int, mode: Mode):
	var calculated_group_name: String = get_buff_group_name(group_number, mode)
	tower.get_buff_groups().append(calculated_group_name)
	print_verbose("Added unit [%s] to buff group [%s]. Unit groups are: %s" % \
		[tower, calculated_group_name, tower.get_buff_groups()])


func get_buff_group_name(group_number: int, mode: Mode) -> String:
	return "%s_%s" % [group_number, Mode.keys()[mode]]


func get_buff_group_number(buff_group: String) -> int:
	return buff_group.split("_")[0].to_int()


func get_buff_group_mode(buff_group: String) -> Mode:
	return Mode.get(buff_group.get_slice("_", 1))


func is_buff_group(group: String) -> bool:
	var buff_group_number: String = group.get_slice("_", 0)
	var buff_group_mode: String = group.get_slice("_", 1)
	return buff_group_number != group && buff_group_number.is_valid_int() && \
		buff_group_mode != group && Mode.has(buff_group_mode)
