class_name BuffContainer extends GridContainer


# Displays buffs of a unit.


const MAX_DISPLAYED_BUFF_COUNT: int = 24

var _buff_display_list: Array[BuffDisplay] = []


#########################
###     Built-in      ###
#########################

func _ready():
	for i in range(0, MAX_DISPLAYED_BUFF_COUNT):
		var buff_display: BuffDisplay = Preloads.buff_display_scene.instantiate()
		_buff_display_list.append(buff_display)
		add_child(buff_display)


#########################
###       Public      ###
#########################

func load_buffs_for_unit(unit: Unit):
	var friendly_buff_list: Array[Buff] = unit._get_buff_list(true)
	var unfriendly_buff_list: Array[Buff] = unit._get_buff_list(false)

	var buff_list: Array[Buff] = []
	buff_list.append_array(friendly_buff_list)
	buff_list.append_array(unfriendly_buff_list)

	var hidden_buff_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_hidden():
			hidden_buff_list.append(buff)

	if !Config.show_hidden_buffs():
		for buff in hidden_buff_list:
			buff_list.erase(buff)

	for buff_display in _buff_display_list:
		buff_display.hide()

	for i in range(0, buff_list.size()):
		if i >= MAX_DISPLAYED_BUFF_COUNT:
			break
		
		var buff_display: BuffDisplay = _buff_display_list[i]
		var buff: Buff = buff_list[i]
		buff_display.set_buff(buff)
		buff_display.show()
