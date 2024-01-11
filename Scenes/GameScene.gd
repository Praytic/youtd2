extends Node


@export var map_node: Node2D
@export var _pregame_hud: Control
@export var _pause_hud: Control
@export var _hud: HUD
@export var _wave_spawner: WaveSpawner
@export var _tutorial_menu: TutorialMenu
@export var _ui_canvas_layer: CanvasLayer


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("GameScene has loaded.")
	
	Globals.set_game_state(Globals.GameState.PREGAME)
	get_tree().set_pause(true)
	
	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()
	
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		var room_code = _get_cmdline_value("room_code")
		assert(room_code, "Room code wasn't provided with headless mode enabled.")
		print("Room code: %s" % room_code)
		Globals.room_code = room_code
	
	if show_pregame_settings_menu && !Config.run_prerender_tool():
		_pregame_hud.show()
	else:
#		Skip pregame settings menu and load default values
		var default_player_mode: PlayerMode.enm = Config.default_player_mode()
		var default_wave_count: int = Config.default_wave_count()
		var default_game_mode: GameMode.enm = Config.default_game_mode()
		var default_difficulty: Difficulty.enm = Config.default_difficulty()
		var default_tutorial_enabled: bool = Config.default_tutorial_enabled()

		_on_pregame_hud_finished(default_player_mode, default_wave_count, default_game_mode, default_difficulty, default_tutorial_enabled)

	if Config.run_prerender_tool():
		var running_on_web: bool = OS.get_name() == "Web"

		if !running_on_web:
			PrerenderTool.run(self, _ui_canvas_layer, map_node)
		else:
			push_error("config/run_prerender_tool is enabled by mistake. Skipping prerender because this is a Web build.")

	if Config.run_save_tooltips_tool():
		SaveTooltipsTool.run()


func _process(delta: float):
	var need_to_record_game_time: bool = Globals.get_game_state() == Globals.GameState.PLAYING && WaveLevel.get_current() > 0

	if need_to_record_game_time:
		Utils._current_game_time += delta


func _unhandled_input(event: InputEvent):
	var cancel_pressed: bool = event.is_action_released("ui_cancel") || event.is_action_released("pause")
	var cancel_consumed_by_mouse_action: bool = MouseState.get_state() != MouseState.enm.NONE
	var cancel_consumed_to_close_windows: bool = _hud.any_window_is_open()
	var cancel_was_consumed: bool = cancel_consumed_by_mouse_action || cancel_consumed_to_close_windows
	
	if cancel_pressed && cancel_consumed_to_close_windows:
		_hud.close_all_windows()
	
	if cancel_pressed && !cancel_was_consumed:
		match Globals.get_game_state():
			Globals.GameState.PLAYING: _pause_the_game()
			Globals.GameState.PAUSED: _unpause_the_game()


#########################
###      Private      ###
#########################

func _pause_the_game():
#	Cancel any in progress mouse actions
	BuildTower.cancel()
	ItemMovement.cancel()
	SelectTargetForCast.cancel()

	Globals.set_game_state(Globals.GameState.PAUSED)
	get_tree().set_pause(true)
	_pause_hud.show()


func _unpause_the_game():
	Globals.set_game_state(Globals.GameState.PLAYING)
	get_tree().set_pause(false)
	_pause_hud.hide()


func _get_cmdline_value(key: String):
	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""
	
	var cmdline_value = false
	if arguments.has(key):
		if arguments.get(key).is_empty():
			cmdline_value = true
		else:
			cmdline_value = arguments.get(key)
	
	return cmdline_value


#########################
###     Callbacks     ###
#########################

func _on_HUD_start_wave(wave_index):
	$Map/CreepSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/CreepSpawner.stop()


func _on_pregame_hud_finished(player_mode: PlayerMode.enm, wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, tutorial_enabled: bool):
	get_tree().set_pause(false)
	
	_pregame_hud.hide()

	var difficulty_string: String = Difficulty.convert_to_string(difficulty)

	Messages.add_normal("Welcome to You TD 2!")
	Messages.add_normal("Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, GameMode.convert_to_display_string(game_mode)])
	Messages.add_normal("You can pause the game by pressing [color=GOLD]Esc[/color]")

	_wave_spawner.generate_waves(wave_count, difficulty)

	Globals.wave_count = wave_count
	Globals.difficulty = difficulty
	
	if tutorial_enabled:
		Globals.set_game_state(Globals.GameState.TUTORIAL)
		_tutorial_menu.show()
	else:
		_on_tutorial_menu_finished()

	Globals.game_mode = game_mode
	Globals.player_mode = player_mode
	EventBus.game_mode_was_chosen.emit()


func _on_pause_hud_resume_pressed():
	_unpause_the_game()


func _on_tutorial_menu_finished():
	Globals.set_game_state(Globals.GameState.PLAYING)
	_tutorial_menu.queue_free()
	_wave_spawner.start_initial_timer()

	Messages.add_normal("The first wave will spawn in 3 minutes.")
	Messages.add_normal("You can start the first wave early by pressing on [color=GOLD]Start next wave[/color].")


