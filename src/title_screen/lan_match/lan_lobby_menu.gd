class_name LanLobbyMenu extends PanelContainer


# Menu for an open LAN lobby, before the game begins.
# Displays players in the lobby.


signal start_pressed()
signal back_pressed()


@export var _player_list: ItemList
@export var _room_config_label: RichTextLabel


#########################
###       Public      ###
#########################

func set_player_list(player_list: Array[String]):
	_player_list.clear()
	
	for player in player_list:
		_player_list.add_item(player)
	
	for i in range(0, _player_list.item_count):
		_player_list.set_item_selectable(i, false)


func display_room_config(room_config: RoomConfig):
	var room_config_string: String = room_config.get_display_string_rich()
	
	_room_config_label.clear()
	_room_config_label.append_text(room_config_string)


#########################
###     Callbacks     ###
#########################

func _on_back_button_pressed():
	back_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()
