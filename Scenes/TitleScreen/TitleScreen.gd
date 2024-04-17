extends Node

# Main menu for the game. Opens when the game starts.


enum Tab {
	MAIN,
	CONFIGURE_SINGLEPLAYER,
	JOIN_OR_HOST,
	MULTIPLAYER_ROOM,
	PROFILE,
	SETTINGS,
	CREDITS,
	AUTH,
}

@export var _tab_container: TabContainer
@export var _configure_singleplayer_menu: ConfigureSinglePlayerMenu
@export var _multiplayer_button: Button
@export var _auth_button: Button
@export var _spacer_before_quit_button: VBoxContainer
@export var _quit_button: Button
@export var _room_menu: RoomMenu


#########################
###     Built-in      ###
#########################

func _ready():
#	NOTE: need to hide multiplayer button in production
#	builds because multiplayer is very rough right now
	_multiplayer_button.visible = Config.show_multiplayer_button()
	
	_auth_button.visible = Config.enable_auth()
	
#	NOTE: show quit button only on pc platform because quit
#	function is not needed on web
	_quit_button.visible = OS.has_feature("pc")
	_spacer_before_quit_button.visible = OS.has_feature("pc")

	if Config.autostart_game():
		var difficulty: Difficulty.enm = Config.autostart_difficulty()
		var game_mode: GameMode.enm = Config.autostart_game_mode()
		var wave_count: int = Config.autostart_wave_count()
		var origin_seed: int = randi()

		_start_game(PlayerMode.enm.SINGLE, wave_count, game_mode, difficulty, origin_seed)


#########################
###      Private      ###
#########################

func _switch_to_main_tab():
	_tab_container.current_tab = Tab.MAIN


# NOTE: this function transitions the game from title screen to game scene. Can be called either by client itself or the host if the game is in multiplayer mode.
@rpc("any_peer", "call_local", "reliable")
func _start_game(player_mode: PlayerMode.enm, wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, origin_seed: int):
#	NOTE: save game settings into globals so that GameScene
#	can access them
	Globals._player_mode = player_mode
	Globals._difficulty = difficulty
	Globals._wave_count = wave_count
	Globals._game_mode = game_mode
	Globals._origin_seed = origin_seed
	
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)


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
	var origin_seed: int = randi()

	var difficulty_string: String = Difficulty.convert_to_string(difficulty)
	var game_mode_string: String = GameMode.convert_to_string(game_mode)
	Settings.set_setting(Settings.CACHED_GAME_DIFFICULTY, difficulty_string)
	Settings.set_setting(Settings.CACHED_GAME_MODE, game_mode_string)
	Settings.set_setting(Settings.CACHED_GAME_LENGTH, game_length)
	Settings.flush()
	
	_start_game(PlayerMode.enm.SINGLE, game_length, game_mode, difficulty, origin_seed)


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


func _on_join_or_host_controller_completed():
	_tab_container.current_tab = Tab.MULTIPLAYER_ROOM


func _on_room_menu_back_pressed():
	_tab_container.current_tab = Tab.JOIN_OR_HOST


func _on_room_menu_start_pressed():
	var difficulty: Difficulty.enm = _room_menu.get_difficulty()
	var game_length: int = _room_menu.get_game_length()
	var game_mode: GameMode.enm = _room_menu.get_game_mode()
	var origin_seed: int = randi()

	_start_game.rpc(PlayerMode.enm.COOP, game_length, game_mode, difficulty, origin_seed)


func _on_profile_button_pressed():
	_tab_container.current_tab = Tab.PROFILE


func _on_profile_menu_close_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_auth_menu_finished():
	_switch_to_main_tab()
