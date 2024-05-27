class_name BuffGroupEditor extends HBoxContainer


# Editor for changing modes of tower buff groups.


var _button_list: Array[BuffGroupButton] = []
var _tower: Tower = null


#########################
###     Built-in      ###
#########################

func _ready():
	var child_list: Array[Node] = get_children()
	
	for child in child_list:
		var button: BuffGroupButton = child as BuffGroupButton
		
		if button == null:
			continue
		
		_button_list.append(button)
		button.pressed.connect(_on_button_pressed.bind(button))


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	_tower = tower
	
	if prev_tower != null && prev_tower.buff_group_changed.is_connected(_on_tower_buff_group_changed):
		prev_tower.buff_group_changed.disconnect(_on_tower_buff_group_changed)

	if tower != null:
		tower.buff_group_changed.connect(_on_tower_buff_group_changed)
		_update_displayed_buff_group_modes()


#########################
###      Private      ###
#########################

func _update_displayed_buff_group_modes():
	for button in _button_list:
		var buff_group_number: int = button.get_buff_group_number()
		var buff_group_mode: BuffGroupMode.enm = _tower.get_buff_group_mode(buff_group_number)
		button.set_buff_group_mode(buff_group_mode)


#########################
###     Callbacks     ###
#########################

func _on_button_pressed(button: BuffGroupButton):
	var buff_group_number: int = button.get_buff_group_number()
	EventBus.player_clicked_tower_buff_group.emit(_tower, buff_group_number)


func _on_tower_buff_group_changed():
	_update_displayed_buff_group_modes()
