class_name GameScene extends Node


@export var map_node: Node2D
@export var _pregame_hud: Control
@export var _pause_hud: Control
@export var _hud: HUD
@export var _wave_spawner: WaveSpawner
@export var _tutorial_menu: TutorialMenu
@export var _ui_canvas_layer: CanvasLayer
@export var _camera: Camera2D
@export var _item_stash: ItemStash
@export var _tower_stash: TowerStash


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("GameScene has loaded.")
	
#	NOTE: resetting singletons here covers two cases:
#	1. launching the game
#	2. restarting the game
	_reset_singletons()

#	NOTE: below are special tools which are not run during
#	normal gameplay.
	if Config.run_save_tooltips_tool():
		SaveTooltipsTool.run()

	if Config.run_prerender_tool():
		var running_on_web: bool = OS.get_name() == "Web"

		if !running_on_web:
			PrerenderTool.run(self, _ui_canvas_layer, map_node)
			Globals.set_game_state(Globals.GameState.PREGAME)

#			NOTE: do early return here so that the game is
#			not paused and we can take pictures of the map
#			properly.
			return
		else:
			push_error("config/run_prerender_tool is enabled by mistake. Skipping prerender because this is a Web build.")

# 	NOTE: this is where normal gameplay starts
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()

	Globals.set_game_state(Globals.GameState.PREGAME)
	get_tree().set_pause(true)
	
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		var room_code = _get_cmdline_value("room_code")
		assert(room_code, "Room code wasn't provided with headless mode enabled.")
		print("Room code: %s" % room_code)
		Globals.room_code = room_code

	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()

	if show_pregame_settings_menu:
		_pregame_hud.show()
	else:
		_transition_from_pregame_settings_state()


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
	_item_stash.cancel_move()
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


func _transition_from_pregame_settings_state():
	get_tree().set_pause(false)

	var builder_id: int = PregameSettings.get_builder_id()
	var builder_instance: Builder = Builder.create_instance(builder_id)
	add_child(builder_instance)
	Globals._builder_instance = builder_instance

	PregameSettings.finalized.emit()

	var wave_count: int = PregameSettings.get_wave_count()
	var difficulty: Difficulty.enm = PregameSettings.get_difficulty()
	var difficulty_string: String = Difficulty.convert_to_string(difficulty)
	var game_mode: GameMode.enm = PregameSettings.get_game_mode()
	var game_mode_string: String = GameMode.convert_to_string(game_mode)

	Messages.add_normal("Welcome to You TD 2!")
	Messages.add_normal("Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, game_mode_string])
	Messages.add_normal("You can pause the game by pressing [color=GOLD]Esc[/color]")

	_wave_spawner.generate_waves(wave_count, difficulty)

	var tutorial_enabled: bool = PregameSettings.get_tutorial_enabled()
	
	if tutorial_enabled:
		Globals.set_game_state(Globals.GameState.TUTORIAL)
		_tutorial_menu.show()
	else:
		_transition_from_tutorial_state()


func _transition_from_tutorial_state():
	Globals.set_game_state(Globals.GameState.PLAYING)
	_tutorial_menu.queue_free()
	_wave_spawner.start_initial_timer()

	Messages.add_normal("The first wave will spawn in 3 minutes.")
	Messages.add_normal("You can start the first wave early by pressing on [color=GOLD]Start next wave[/color].")

#	NOTE: tower tests need to run after everything else has
#	been initialized
	if Config.run_test_towers_tool():
		TestTowersTool.run(self)

	if Config.run_test_horadric_tool():
		TestHoradricTool.run()


# TODO: move global state into nodes which are children of
# GameScene so that it's automatically reset
func _reset_singletons():
	FoodManager.reset()
	KnowledgeTomesManager.reset()
	CombatLog.reset()
	Effect.reset()
	ElapsedTimer.reset()
	ElementLevel.reset()
	Globals.reset()
	GoldControl.reset()
	ManualAttackTarget.reset()
	MouseState.reset()
	PortalLives.reset()
	PregameSettings.reset()
	SelectPointForCast.reset()
	SelectTargetForCast.reset()
	SelectUnit.reset()
	WaveLevel.reset()


#########################
###     Callbacks     ###
#########################

func _on_pause_hud_resume_pressed():
	_unpause_the_game()


func _on_pregame_hud_hidden():
	_transition_from_pregame_settings_state()


func _on_tutorial_menu_hidden():
	_transition_from_tutorial_state()


func _on_settings_changed():
	var interface_size: float = Settings.get_interface_size()
	get_tree().root.content_scale_factor = interface_size

#	NOTE: need to call update_zoom() to update camera zoom
#	when interface size is changed in settings menu. Calling
#	update_zoom() inside Camera script via callback does not
#	work because the game is paused while the settings menu
#	is open.
	_camera.update_zoom()


func _on_pause_hud_restart_pressed():
	get_tree().reload_current_scene()


func _on_item_stash_main_stash_changed():
	var item_list: Array[Item] = _item_stash.get_items_in_main_stash()
	_hud.set_items(item_list)


func _on_item_stash_horadric_stash_changed():
	var item_list: Array[Item] = _item_stash.get_items_in_horadric_stash()
	_hud.set_items_for_horadric_cube(item_list)


func _on_tower_stash_changed():
	var towers: Dictionary = _tower_stash.get_towers()
	_hud.set_towers(towers)
