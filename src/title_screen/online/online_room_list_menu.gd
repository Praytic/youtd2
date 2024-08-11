class_name OnlineRoomListMenu extends PanelContainer


signal join_pressed()
signal cancel_pressed()
signal create_room_pressed()


@export var _no_rooms_found_label: Label
@export var _item_list: ItemList


#########################
###       Public      ###
#########################

func get_selected_match_id() -> String:
	var selected_index_list: Array = _item_list.get_selected_items()
	
	if selected_index_list.is_empty():
		return ""
	
	var selected_index: int = selected_index_list[0]
	var selected_match_id: String = _item_list.get_item_metadata(selected_index)
	
	return selected_match_id


# TODO: maybe sort matches by creation time? But that is not available by
# default in nakama. Need to add this data to label.
func update_match_list(match_list: Array):
	var found_rooms: bool = !match_list.is_empty()
	
	_no_rooms_found_label.visible = !found_rooms
	_item_list.visible = found_rooms
	
	_item_list.clear()
	
	for match_ in match_list:
		var match_display_string: String = "%s %d/2 players" % [match_.match_id, match_.size]
		_item_list.add_item(match_display_string)
		
		var item_index: int = _item_list.get_item_count() - 1
		_item_list.set_item_metadata(item_index, match_.match_id)


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_room_button_pressed():
	create_room_pressed.emit()
