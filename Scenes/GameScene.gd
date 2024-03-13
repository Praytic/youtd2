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
@export var _player: Player
@export var _game_start_timer: Timer
@export var _next_wave_timer: Timer
@export var _extreme_timer: Timer
@export var _game_time: GameTime
@export var _object_container: Node2D


var _built_at_least_one_tower: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("GameScene has loaded.")

#	NOTE: resetting singletons here covers two cases:
#	1. launching the game
#	2. restarting the game
	_reset_singletons()

	EventBus.wave_finished.connect(_on_wave_finished)
	EventBus.creep_reached_portal.connect(_on_creep_reached_portal)
	EventBus.player_requested_start_game.connect(_on_player_requested_start_game)
	EventBus.player_requested_next_wave.connect(_on_player_requested_next_wave)
	EventBus.tower_created.connect(_on_tower_created)
	EventBus.player_requested_to_roll_towers.connect(_on_player_requested_to_roll_towers)
	GoldControl.changed.connect(_on_gold_changed)
	KnowledgeTomesManager.changed.connect(_on_tomes_changed)
	FoodManager.changed.connect(_on_food_changed)
	
#	Load initial values
	_on_gold_changed()
	_on_tomes_changed()
	_on_food_changed()
	
	_hud.set_player(_player)

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

	var test_item_list: Array = Config.test_item_list()

	for item_id in test_item_list:
		var item: Item = Item.make(item_id)
		_item_stash.add_item_to_main_stash(item)

	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()

	if show_pregame_settings_menu:
		_pregame_hud.show()
	else:
		_transition_from_pregame_settings_state()


# NOTE: these stats are constantly changing and might even change multiple times per frame so we need to update them in _process instead of via signals
func _process(_delta: float):
	_hud.load_player_stats([_player])

	var game_time: float = Utils.get_time()
	_hud.set_game_time(game_time)
	

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

func _roll_towers_after_wave_finish():
	var rolled_towers: Array[int] = TowerDistribution.roll_towers(_player)
	_tower_stash.add_towers(rolled_towers)
	
#	Add messages about new towers
	Messages.add_normal("New towers were added to stash:")

#	Sort tower list by element to group messages for same
#	element together
	rolled_towers.sort_custom(func(a, b): 
		var element_a: int = TowerProperties.get_element(a)
		var element_b: int = TowerProperties.get_element(b)
		return element_a < element_b)

	for tower in rolled_towers:
		var element: Element.enm = TowerProperties.get_element(tower)
		var element_string: String = Element.convert_to_colored_string(element)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var rarity_color: Color = Rarity.get_color(rarity)
		var tower_name: String = TowerProperties.get_display_name(tower)
		var tower_name_colored: String = Utils.get_colored_string(tower_name, rarity_color)
		var message: String = "    %s: %s" % [element_string, tower_name_colored]

		Messages.add_normal(message)


func _pause_the_game():
#	Cancel any in progress mouse actions
	BuildTower.cancel()
	_item_stash.cancel_move()
	SelectTargetForCast.cancel()
	_game_time.set_enabled(false)

	Globals.set_game_state(Globals.GameState.PAUSED)
	get_tree().set_pause(true)
	_pause_hud.show()


func _unpause_the_game():
	Globals.set_game_state(Globals.GameState.PLAYING)
	get_tree().set_pause(false)
	_pause_hud.hide()
	_game_time.set_enabled(true)


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

	builder_instance.apply_to_player(_player)
	
	var wave_count: int = PregameSettings.get_wave_count()
	var difficulty: Difficulty.enm = PregameSettings.get_difficulty()
	var game_mode: GameMode.enm = PregameSettings.get_game_mode()
	
	_hud.set_pregame_settings(wave_count, game_mode, difficulty, builder_id)
	
	PregameSettings.finalized.emit()
	
	var difficulty_string: String = Difficulty.convert_to_string(difficulty)
	var game_mode_string: String = GameMode.convert_to_string(game_mode)

	Messages.add_normal("Welcome to You TD 2!")
	Messages.add_normal("Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, game_mode_string])
	Messages.add_normal("You can pause the game by pressing [color=GOLD]Esc[/color]")

	_wave_spawner.generate_waves(wave_count, difficulty)

	var next_waves: Array[Wave] = _get_next_5_waves()
	_hud.show_wave_details(next_waves)

	var tutorial_enabled: bool = PregameSettings.get_tutorial_enabled()
	
	if tutorial_enabled:
		Globals.set_game_state(Globals.GameState.TUTORIAL)
		_tutorial_menu.show()
	else:
		_transition_from_tutorial_state()


func _transition_from_tutorial_state():
	Globals.set_game_state(Globals.GameState.PLAYING)
	_tutorial_menu.queue_free()

	Messages.add_normal("The first wave will spawn in 3 minutes.")
	Messages.add_normal("You can start the first wave early by pressing on [color=GOLD]Start next wave[/color].")
	
	_game_start_timer.start(Constants.TIME_BEFORE_FIRST_WAVE)
	_hud.show_game_start_time()

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
	PregameSettings.reset()
	SelectPointForCast.reset()
	SelectTargetForCast.reset()
	SelectUnit.reset()


func _start_game():
	_game_start_timer.stop()
	_hud.hide_game_start_time()
	_hud.show_next_wave_button()

	_wave_spawner.start_wave(1)
	
	if PregameSettings.get_difficulty() == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)

#	NOTE: start counting game time after first wave starts
	_game_time.set_enabled(true)


func _start_next_wave():
	_extreme_timer.stop()
	_next_wave_timer.stop()
	_hud.hide_next_wave_time()

	_player.get_team().increment_level()
	var level: int = _player.get_team().get_level()

	var next_waves: Array[Wave] = _get_next_5_waves()
	_hud.show_wave_details(next_waves)
	
	_wave_spawner.start_wave(level)
	
	var started_last_wave: bool = level == PregameSettings.get_wave_count()
	
	if started_last_wave:
		_hud.disable_next_wave_button()
		
	if !started_last_wave && PregameSettings.get_difficulty() == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)


func _get_next_5_waves() -> Array[Wave]:
	var wave_list: Array[Wave] = []
	var current_level: int = _player.get_team().get_level()
	
	for level in range(current_level, current_level + 6):
		var wave: Wave = _wave_spawner.get_wave(level)
		
		if wave != null:
			wave_list.append(wave)

	return wave_list


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
#	NOTE: need to remove all units before restarting the
#	game to avoid issues with creeps emitting tree_exit()
#	signals, triggering wave_finished() signal and then
#	accessing Messages while HUD was already removed from
#	the tree.
	while _object_container.get_child_count() > 0:
		for child in _object_container.get_children():
			_object_container.remove_child(child)
			child.queue_free()
	
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


func _on_wave_finished(level: int):
	Messages.add_normal("=== Level [color=GOLD]%d[/color] completed! ===" % level)

	GoldControl.add_income(level)
	KnowledgeTomesManager.add_income()

	if PregameSettings.game_mode_is_random():
		_roll_towers_after_wave_finish()

	_extreme_timer.stop()
	_next_wave_timer.start(Constants.TIME_BETWEEN_WAVES)
	_hud.show_next_wave_time(Constants.TIME_BETWEEN_WAVES)

	var builder: Builder = Globals.get_builder()
	builder.apply_wave_finished_effect(_player)


func _on_gold_changed():
	var gold: float = GoldControl.get_gold()
	_hud.set_gold(gold)


func _on_tomes_changed():
	var tomes: int = KnowledgeTomesManager.get_current()
	_hud.set_tomes(tomes)


func _on_food_changed():
	var food: int = FoodManager.get_current_food()
	var food_cap: int = FoodManager.get_food_cap()
	_hud.set_food(food, food_cap)


func _on_creep_reached_portal(creep: Creep):
	var damage_to_portal = creep.get_damage_to_portal()
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 1)
	var damage_done: float = creep.get_damage_done()
	var damage_done_string: String = Utils.format_percent(damage_done, 2)
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_size_string: String = CreepSize.convert_to_string(creep_size)

	if creep_size == CreepSize.enm.BOSS:
		Messages.add_normal("Dealt %s damage to BOSS" % damage_done_string)
	else:
		Messages.add_normal("Failed to kill a %s" % creep_size_string.to_upper())		

	if damage_to_portal > 0:
		Messages.add_normal("You lose %s of your lives!" % damage_to_portal_string)

	_player.get_team().modify_lives(-damage_to_portal)

	SFX.play_sfx("res://Assets/SFX/Assets_SFX_hit_3.mp3")

	var out_of_lives: bool = _player.get_team().get_lives_percent() == 0
	
	if out_of_lives && !Globals.game_over:
		Messages.add_normal("[color=RED]The portal has been destroyed! The game is over.[/color]")
		Globals.game_over = true
		EventBus.game_over.emit()

		_hud.disable_next_wave_button()


func _on_player_requested_start_game():
	if !_built_at_least_one_tower:
		Messages.add_error("You have to build some towers before you can start the game!")

		return
	
	_game_start_timer.stop()
	_start_game()


func _on_game_start_timer_timeout():
	_start_game()


func _on_player_requested_next_wave():
	if Globals.game_over:
		Messages.add_error("Can't start next wave because the game is over.")

		return

	var wave_is_in_progress: bool = _wave_spawner.wave_is_in_progress()
	if wave_is_in_progress:
		Messages.add_error("Can't start next wave because a wave is in progress.")
		
		return
	
	_start_next_wave()


func _on_extreme_timer_timeout():
	_next_wave_timer.start(Constants.EXTREME_DELAY_BEFORE_NEXT_WAVE)
	_hud.show_next_wave_time(Constants.EXTREME_DELAY_BEFORE_NEXT_WAVE)


func _on_next_wave_timer_timeout():
	_start_next_wave()


func _on_tower_created(_tower: Tower):
	_built_at_least_one_tower = true


func _on_player_requested_to_roll_towers():
	var researched_any_elements: bool = false
	
	for element in Element.get_list():
		var researched_element: bool = _player.get_element_level(element)
		if researched_element:
			researched_any_elements = true
	
	if !researched_any_elements:
		Messages.add_error("Cannot roll towers yet! You need to research at least one element.")
	
		return

	var tower_count_for_roll: int = _player.get_tower_count_for_starting_roll()

	if tower_count_for_roll == 0:
		Messages.add_error("You cannot reroll towers anymore.")
	
		return

	_tower_stash.clear()
	
	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(_player, tower_count_for_roll)
	_tower_stash.add_towers(rolled_towers)
	_player.decrement_tower_count_for_starting_roll()
