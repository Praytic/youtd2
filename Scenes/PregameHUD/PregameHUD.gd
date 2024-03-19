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
	TUTORIAL_QUESTION,
	WAITING_FOR_HOST,
}


@export var _tab_container: TabContainer
@export var _host_details_label: Label
@export var _player_mode_menu: PlayerModeMenu
@export var _coop_menu: CoopMenu
@export var _game_length_menu: GameLengthMenu
@export var _game_mode_menu: GameModeMenu
@export var _difficulty_menu: DifficultyMenu
@export var _tutorial_question_menu: TutorialQuestionMenu


#########################
###     Built-in      ###
#########################

func _ready():
	_tab_container.current_tab = Tab.PLAYER_MODE


#########################
###       Public      ###
#########################

func show_network_status(text: String):
	_host_details_label.text = text
	_host_details_label.visible = true


func get_current_tab() -> PregameHUD.Tab:
	var current_tab: PregameHUD.Tab = _tab_container.current_tab as PregameHUD.Tab
	
	return current_tab


func get_game_length() -> int:
	return _game_length_menu.get_game_length()


func get_game_mode() -> GameMode.enm:
	return _game_mode_menu.get_game_mode()


func get_difficulty() -> Difficulty.enm:
	return _difficulty_menu.get_difficulty()


func get_room_address() -> String:
	var room_address: String = _coop_menu.get_room_address()
	
	return room_address


func get_tutorial_enabled() -> bool:
	return _tutorial_question_menu.get_tutorial_enabled()


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
