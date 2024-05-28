class_name BuffContainer extends GridContainer


# Displays buffs of a unit.


var _buff_display_list: Array[BuffDisplay] = []


#########################
###     Built-in      ###
#########################

func _ready():
	var child_node_list: Array[Node] = get_children()
	
	for child_node in child_node_list:
		if !child_node is BuffDisplay:
			push_error("BuffContainer must have BuffDisplay children.")
			
			return
		
		var buff_display: BuffDisplay = child_node as BuffDisplay
		_buff_display_list.append(buff_display)


#########################
###       Public      ###
#########################

func load_buffs_for_unit(unit: Unit):
	var buff_list: Array[Buff] = unit.get_buff_list()

	var hidden_buff_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_hidden():
			hidden_buff_list.append(buff)

	if !Config.show_hidden_buffs():
		for buff in hidden_buff_list:
			buff_list.erase(buff)

	var perma_buff_list: Array[Buff] = []
	for buff in buff_list:
		var buff_is_perma: bool = buff.get_original_duration() < 0
		if buff_is_perma:
			perma_buff_list.append(buff)

#	NOTE: need to put permanent buffs first, otherwise they
#	will just around too much due to temporary buffs
#	expiring
	for buff in perma_buff_list:
		buff_list.erase(buff)
		buff_list.insert(0, buff)

	for buff_display in _buff_display_list:
		buff_display.set_buff(null)
		buff_display.hide()

	for i in range(0, buff_list.size()):
		if i >= _buff_display_list.size():
			break
		
		var buff_display: BuffDisplay = _buff_display_list[i]
		var buff: Buff = buff_list[i]
		buff_display.set_buff(buff)
		buff_display.show()
