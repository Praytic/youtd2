class_name OnlineRoomMenu extends PanelContainer


# Menu for an open LAN room, before the game begins.
# Displays players in the room.


signal start_pressed()
signal back_pressed()


@export var _player_list: ItemList
@export var _room_config_label: RichTextLabel


#########################
###       Public      ###
#########################

#func set_player_list(player_list: Array[String]):
#	_player_list.clear()
#
#	for player in player_list:
#		_player_list.add_item(player)
#
#	for i in range(0, _player_list.item_count):
#		_player_list.set_item_selectable(i, false)


func add_presences(presence_list: Array):
	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e
		
		_player_list.add_item(presence.username)
		
		var new_item_index: int = _player_list.get_item_count() - 1
		_player_list.set_item_metadata(new_item_index, presence.user_id)
		_player_list.set_item_selectable(new_item_index, false)


func remove_presences(presence_list: Array):
	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e
		
		_player_list.add_item(presence.username)
		var found_index: int = _find_item_in_item_list_by_metadata(_player_list, presence.user_id)
		
		if found_index == -1:
			push_error("Failed to find leaver in player list.")
			
			continue
		
		_player_list.remove_item(found_index)


func display_room_config(room_config: RoomConfig):
	var room_config_string: String = room_config.get_display_string_rich()
	
	_room_config_label.clear()
	_room_config_label.append_text(room_config_string)


func _find_item_in_item_list_by_metadata(item_list: ItemList, metadata: Variant) -> int:
	var index: int = -1
	
	for i in item_list.get_item_count():
		var this_metadata: Variant = item_list.get_item_metadata(i)
		var metadata_matches: bool = this_metadata == metadata
		
		if metadata_matches:
			index = i
			
			break
	
	return index


#########################
###     Callbacks     ###
#########################

func _on_back_button_pressed():
	back_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()
