class_name RoomMenu extends PanelContainer


signal start_pressed()
signal back_pressed()


@export var _player_list: ItemList
@export var _room_config_label: RichTextLabel


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	var peer_id_list: Array = multiplayer.get_peers()
	var local_peer_id: int = multiplayer.get_unique_id()
	peer_id_list.append(local_peer_id)
	
	_player_list.clear()
	
	for peer_id in peer_id_list:
		var peer_string: String = "Player %d" % peer_id
		_player_list.add_item(peer_string)
	
	for i in _player_list.item_count:
		_player_list.set_item_selectable(i, false)
	
#########################
###       Public      ###
#########################

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
