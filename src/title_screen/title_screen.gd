class_name TitleScreen extends Node

# Main menu for the game. Opens when the game starts.


enum Tab {
	MAIN,
	CONFIGURE_SINGLEPLAYER,
	ONLINE_MATCH_LIST,
	LAN_MATCH_LIST,
	CREATE_ONLINE_MATCH,
	CREATE_LAN_MATCH,
	ONLINE_LOBBY,
	LAN_LOBBY,
	PROFILE,
	SETTINGS,
	CREDITS,
	LOADING,
}

@export var _tab_container: TabContainer
@export var _configure_singleplayer_menu: ConfigureSinglePlayerMenu
@export var _spacer_before_quit_button: VBoxContainer
@export var _quit_button: Button
@export var _lan_button: Button


#########################
###     Built-in      ###
#########################

func _ready():
	print(" \n")
	print("The messages about Basis universal can be ignored: \"Basis universal cannot unpack level 1.\".")
	print(" \n")
	
#	NOTE: show quit button only on pc platform because quit
#	function is not needed on web
	_quit_button.visible = OS.has_feature("pc")
	_spacer_before_quit_button.visible = OS.has_feature("pc")
	
	_lan_button.visible = Config.feature_lan_matches()


#########################
###      Private      ###
#########################

func switch_to_tab(tab: TitleScreen.Tab):
	_tab_container.current_tab = tab


func _switch_to_main_tab():
	_tab_container.current_tab = Tab.MAIN


# NOTE: this function transitions the game from title screen to game scene. Can be called either by client itself or the host if the game is in multiplayer mode.
@rpc("any_peer", "call_local", "reliable")
func start_game(player_mode: PlayerMode.enm, wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, origin_seed: int, connection_type: Globals.ConnectionType):
#	NOTE: save game settings into globals so that GameScene
#	can access them
	Globals._player_mode = player_mode
	Globals._difficulty = difficulty
	Globals._wave_count = wave_count
	Globals._game_mode = game_mode
	Globals._origin_seed = origin_seed
	Globals._connection_type = connection_type
	
#	NOTE: need to add a delay so that the game properly
#	switches to displaying LOADING tab before starting
#	change_scene_to_packed()
	_tab_container.current_tab = Tab.LOADING
	await get_tree().create_timer(0.1).timeout
	
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)


#########################
###     Callbacks     ###
#########################

func _on_quit_button_pressed():
	get_tree().quit()


func _on_singleplayer_button_pressed():
	_tab_container.current_tab = Tab.CONFIGURE_SINGLEPLAYER


func _on_lan_button_pressed():
	_tab_container.current_tab = Tab.LAN_MATCH_LIST


func _on_settings_button_pressed():
	_tab_container.current_tab = Tab.SETTINGS


func _on_credits_button_pressed():
	_tab_container.current_tab = Tab.CREDITS


func _on_configure_singleplayer_menu_start_button_pressed():
	var difficulty: Difficulty.enm = _configure_singleplayer_menu.get_difficulty()
	var game_length: int = _configure_singleplayer_menu.get_game_length()
	var game_mode: GameMode.enm = _configure_singleplayer_menu.get_game_mode()
	var origin_seed: int = randi()

	var difficulty_string: String = Difficulty.convert_to_string(difficulty)
	var game_mode_string: String = GameMode.convert_to_string(game_mode)
	Settings.set_setting(Settings.CACHED_GAME_DIFFICULTY, difficulty_string)
	Settings.set_setting(Settings.CACHED_GAME_MODE, game_mode_string)
	Settings.set_setting(Settings.CACHED_GAME_LENGTH, game_length)
	Settings.flush()
	
	start_game(PlayerMode.enm.SINGLE, game_length, game_mode, difficulty, origin_seed, Globals.ConnectionType.ENET)


func _on_generic_tab_cancel_pressed():
	_switch_to_main_tab()


func _on_settings_menu_ok_pressed():
	_switch_to_main_tab()


func _on_lan_room_menu_back_pressed():
	_tab_container.current_tab = Tab.LAN_MATCH_LIST


func _on_create_lan_room_menu_cancel_pressed():
	_tab_container.current_tab = Tab.LAN_MATCH_LIST


func _on_profile_button_pressed():
	_tab_container.current_tab = Tab.PROFILE


func _on_profile_menu_close_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_multiplayer_button_pressed():
	_tab_container.current_tab = Tab.ONLINE_MATCH_LIST


func _on_create_online_match_menu_cancel_pressed():
	_tab_container.current_tab = Tab.ONLINE_MATCH_LIST
