class_name LanLobbyMenu extends PanelContainer


# Menu for an open LAN lobby, before the game begins.
# Displays players in the lobby.


signal start_pressed()
signal back_pressed()


@export var _player_list: ItemList
@export var _match_config_label: RichTextLabel
@export var _host_address_container: HBoxContainer
@export var _host_address_line_edit: LineEdit
@export var _start_button: Button


#########################
###       Public      ###
#########################

func set_player_list(player_list: Array[String]):
	_player_list.clear()
	
	for player in player_list:
		_player_list.add_item(player)
	
	for i in range(0, _player_list.item_count):
		_player_list.set_item_selectable(i, false)


func display_match_config(match_config: MatchConfig):
	var match_config_string: String = match_config.get_display_string_rich()
	
	_match_config_label.clear()
	_match_config_label.append_text(match_config_string)


func set_host_address(value: String):
	_host_address_line_edit.text = value


func set_host_address_visible(value: bool):
	_host_address_container.visible = value


func set_start_button_visible(value: bool):
	_start_button.visible = value


#########################
###     Callbacks     ###
#########################

func _on_back_button_pressed():
	back_pressed.emit()


func _on_start_button_pressed():
	start_pressed.emit()
