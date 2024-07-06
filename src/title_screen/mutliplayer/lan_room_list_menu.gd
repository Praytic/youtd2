class_name LanRoomListMenu extends PanelContainer


signal join_pressed()
signal join_address_pressed()
signal cancel_pressed()
signal create_room_pressed()


@export var _no_rooms_found_label: Label
@export var _item_list: ItemList
@export var _address_edit: LineEdit


#########################
###       Public      ###
#########################

func update_room_display(room_map: Dictionary):
	var found_rooms: bool = !room_map.is_empty()
	
	_no_rooms_found_label.visible = !found_rooms
	_item_list.visible = found_rooms
	
	var room_list: Array = room_map.values()

#	NOTE: sort by time to display newest rooms at the top
	room_list.sort_custom(func (a: RoomInfo, b: RoomInfo) -> bool:
		var time_a: float = a.get_create_time()
		var time_b: float = b.get_create_time()
		
		return time_a > time_b
	)
	
	_item_list.clear()
	
	for room in room_list:
		var room_string: String = room.get_display_string()
		_item_list.add_item(room_string)
		
		var item_index: int = _item_list.get_item_count() - 1
		var room_address: String = room.get_address()
		_item_list.set_item_metadata(item_index, room_address)


func get_selected_room_address() -> String:
	var selected_index_list: Array = _item_list.get_selected_items()
	
	if selected_index_list.is_empty():
		return ""
	
	var selected_index: int = selected_index_list[0]
	var selected_room_address: String = _item_list.get_item_metadata(selected_index)
	
	return selected_room_address


func get_entered_address() -> String:
	return _address_edit.text


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_room_button_pressed():
	create_room_pressed.emit()


func _on_join_address_button_pressed():
	join_address_pressed.emit()
