class_name PregameHUD extends Control

# This HUD is shown when the game starts and blocks input to
# the normal HUD. Once the player chooses all of the
# settings, this hud gets hidden and the game starts.


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

func get_room_address() -> String:
	var room_address: String = _coop_menu.get_room_address()
	
	return room_address


func show_address_error():
	_coop_menu.show_address_error()


func change_tab(tab: PregameHUD.Tab):
	_tab_container.current_tab = tab


#########################
###     Callbacks     ###
#########################

func _on_submenu_finished():
	var current_tab: PregameTab = _tab_container.get_current_tab_control() as PregameTab
	var current_tab_index: PregameHUD.Tab = current_tab.tab_index
	
	match current_tab_index:
		Tab.PLAYER_MODE:
			var player_mode: PlayerMode.enm = _player_mode_menu.get_player_mode()
			
			match player_mode:
				PlayerMode.enm.SINGLE: change_tab(Tab.GAME_LENGTH)
				PlayerMode.enm.COOP: change_tab(Tab.COOP_ROOM)
				PlayerMode.enm.SERVER: push_error("unhandled case")
		Tab.COOP_ROOM: change_tab(Tab.GAME_LENGTH)
		Tab.GAME_LENGTH: change_tab(Tab.DISTRIBUTION)
		Tab.DISTRIBUTION: change_tab(Tab.DIFFICULTY)
		Tab.DIFFICULTY: change_tab(Tab.BUILDER)
		Tab.BUILDER: change_tab(Tab.TUTORIAL_QUESTION)
		Tab.TUTORIAL_QUESTION: hide()


func _on_network_status_changed(text: String, _error: bool):
	_host_details_label.text = text
	_host_details_label.visible = true
