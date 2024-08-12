class_name OnlineRoomMenu extends PanelContainer


# Menu for an open LAN room, before the game begins.
# Displays players in the room.


signal ready_pressed()
signal leave_pressed()


const READY_TEXT_NO: String = "- Not Ready"
const READY_TEXT_YES: String = "- Ready!"


@export var _player_list: ItemList
@export var _room_config_label: RichTextLabel
@export var _ready_button: Button


#########################
###       Public      ###
#########################

func set_ready_for_player(user_id: String):
	var index: int = _find_item_in_item_list_by_metadata(_player_list, user_id)
	var current_text: String = _player_list.get_item_text(index)
	var new_text: String = current_text.replace(READY_TEXT_NO, READY_TEXT_YES)

	_player_list.set_item_text(index, new_text)


func add_presences(presence_list: Array):
	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e

		var item_text: String = "%s %s" % [presence.username, READY_TEXT_NO] 
		_player_list.add_item(item_text)
		
		var new_item_index: int = _player_list.get_item_count() - 1
		_player_list.set_item_metadata(new_item_index, presence.user_id)
		_player_list.set_item_selectable(new_item_index, false)


func remove_presences(presence_list: Array):
	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e
		
		var found_index: int = _find_item_in_item_list_by_metadata(_player_list, presence.user_id)
		
		if found_index == -1:
			push_error("Failed to find leaver in player list.")
			
			continue
		
		_player_list.remove_item(found_index)


func display_room_config(room_config: RoomConfig):
	var room_config_string: String = room_config.get_display_string_rich()
	
	_room_config_label.clear()
	_room_config_label.append_text(room_config_string)


func set_ready_button_disabled(value: bool):
	_ready_button.set_disabled(value)


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

func _on_ready_button_pressed():
	ready_pressed.emit()


func _on_leave_button_pressed():
	leave_pressed.emit()
