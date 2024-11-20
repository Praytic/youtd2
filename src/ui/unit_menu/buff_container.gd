class_name BuffContainer extends VBoxContainer


# Displays buffs of a unit.

# NOTE: The weird setup of two grid containers for two rows
# is needed to make buffs appear on second row first, then
# on second when first row runs out of space.


var _buff_display_list: Array[BuffDisplay] = []

@export var _row_top: GridContainer
@export var _row_bottom: GridContainer


#########################
###     Built-in      ###
#########################

func _ready():
	var top_list: Array[Node] = _row_top.get_children()
	var bottom_list: Array[Node] = _row_bottom.get_children()
	
	var combined_list: Array = []
	combined_list.append_array(bottom_list)
	combined_list.append_array(top_list)
	
	for child_node in combined_list:
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

	for i in range(0, buff_list.size()):
		if i >= _buff_display_list.size():
			break
		
		var buff_display: BuffDisplay = _buff_display_list[i]
		var buff: Buff = buff_list[i]
		buff_display.set_buff(buff)

#	NOTE: need to be careful with how visibility is updated.
#	The method of "hide all, then show only valid buffs" is
#	bad because it disrupts tooltips. Instead, use method of
#	"hide only invalid"
	for buff_display in _buff_display_list:
		var has_assigned_buff: bool = buff_display.get_buff() != null
		buff_display.visible = has_assigned_buff
