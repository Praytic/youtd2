class_name RoomMenu extends PanelContainer


signal back_pressed()
signal start_pressed()


@export var _player_list: ItemList
@export var _game_mode_ui: GameModeUI
@export var _start_button: Button


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

func get_difficulty() -> Difficulty.enm:
	return _game_mode_ui.get_difficulty()


func get_game_length() -> int:
	return _game_mode_ui.get_game_length()


func get_game_mode() -> GameMode.enm:
	return _game_mode_ui.get_game_mode()


func set_server_controls_disabled(value: bool):
	_game_mode_ui.set_disabled(value)
	_start_button.disabled = value


#########################
###     Callbacks     ###
#########################

func _on_back_button_pressed():
	back_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()
