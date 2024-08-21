class_name OnlineRoomMenu extends PanelContainer


# Menu for an open LAN room, before the game begins.
# Displays players in the room.


signal start_pressed()
signal leave_pressed()


@export var _player_list: ItemList
@export var _room_config_label: RichTextLabel
@export var _start_button: Button


#########################
###       Public      ###
#########################

func set_start_button_visible(value: bool):
	_start_button.visible = value


func set_presences(presence_list: Array):
	_player_list.clear()

	for e in presence_list:
		var presence: NakamaRTAPI.UserPresence = e
		var user_id: String = presence.user_id
		var username: String = presence.username

		_player_list.add_item(username)
		
		var new_item_index: int = _player_list.get_item_count() - 1
		_player_list.set_item_metadata(new_item_index, user_id)
		_player_list.set_item_selectable(new_item_index, false)


func display_room_config(room_config: RoomConfig):
	var room_config_string: String = room_config.get_display_string_rich()
	
	_room_config_label.clear()
	_room_config_label.append_text(room_config_string)


#########################
###     Callbacks     ###
#########################

func _on_leave_button_pressed():
	leave_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()
