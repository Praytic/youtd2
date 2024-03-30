extends Node

# Main menu for the game. Opens when the game starts.


enum Tab {
	MAIN,
	CONFIGURE_SINGLEPLAYER,
	JOIN_OR_HOST,
	ROOM_MENU,
	SETTINGS,
	CREDITS,
	AUTH,
}

@export var _tab_container: TabContainer
@export var _configure_singleplayer_menu: ConfigureSinglePlayerMenu
@export var _auth_button: Button
@export var _spacer_before_quit_button: VBoxContainer
@export var _quit_button: Button


#########################
###     Built-in      ###
#########################

func _ready():
	_auth_button.visible = Config.enable_auth()
	
#	NOTE: show quit button only on pc platform because quit
#	function is not needed on web
	_quit_button.visible = OS.has_feature("pc")
	_spacer_before_quit_button.visible = OS.has_feature("pc")


#########################
###      Private      ###
#########################

func _switch_to_main_tab():
	_tab_container.current_tab = Tab.MAIN


#########################
###     Callbacks     ###
#########################

func _on_quit_button_pressed():
	get_tree().quit()


func _on_singleplayer_button_pressed():
	_tab_container.current_tab = Tab.CONFIGURE_SINGLEPLAYER


func _on_multiplayer_button_pressed():
	_tab_container.current_tab = Tab.JOIN_OR_HOST


func _on_settings_button_pressed():
	_tab_container.current_tab = Tab.SETTINGS


func _on_credits_button_pressed():
	_tab_container.current_tab = Tab.CREDITS


func _on_configure_singleplayer_menu_start_button_pressed():
	var difficulty: Difficulty.enm = _configure_singleplayer_menu.get_difficulty()
	var game_length: int = _configure_singleplayer_menu.get_game_length()
	var game_mode: GameMode.enm = _configure_singleplayer_menu.get_game_mode()
	
#	NOTE: save game settings into globals so that GameScene
#	can access them
	Globals._player_mode = PlayerMode.enm.SINGLE
	Globals._difficulty = difficulty
	Globals._wave_count = game_length
	Globals._game_mode = game_mode
	Globals._origin_seed = randi()
	
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)


func _on_join_or_host_menu_join_button_pressed():
	pass # Replace with function body.


func _on_join_or_host_menu_host_button_pressed():
	pass # Replace with function body.


func _on_auth_button_pressed():
	_tab_container.current_tab = Tab.AUTH


func _on_generic_tab_cancel_pressed():
	_switch_to_main_tab()


func _on_settings_menu_ok_pressed():
	_switch_to_main_tab()
