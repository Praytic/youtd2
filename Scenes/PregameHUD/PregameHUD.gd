class_name PregameHUD extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


signal tab_finished()


enum Tab {
	PLAYER_MODE,
	COOP_ROOM,
	GAME_LENGTH,
	DISTRIBUTION,
	DIFFICULTY,
	BUILDER,
	TUTORIAL_QUESTION,
	WAITING_FOR_HOST,
}


@export var _tab_container: TabContainer
@export var _host_details_label: Label
@export var _player_mode_menu: PlayerModeMenu
@export var _coop_menu: CoopMenu


#########################
###     Built-in      ###
#########################

func _ready():
	_tab_container.current_tab = Tab.PLAYER_MODE
	Network.status_changed.connect(_on_network_status_changed)


#########################
###       Public      ###
#########################

func get_current_tab() -> PregameHUD.Tab:
	var current_tab: PregameHUD.Tab = _tab_container.current_tab as PregameHUD.Tab
	
	return current_tab


func get_room_address() -> String:
	var room_address: String = _coop_menu.get_room_address()
	
	return room_address


func show_address_error():
	_coop_menu.show_address_error()


func change_tab(tab: PregameHUD.Tab):
	_tab_container.current_tab = tab


func get_player_mode() -> PlayerMode.enm:
	return _player_mode_menu.get_player_mode()


#########################
###     Callbacks     ###
#########################

func _on_submenu_finished():
	tab_finished.emit()


func _on_network_status_changed(text: String, _error: bool):
	_host_details_label.text = text
	_host_details_label.visible = true
