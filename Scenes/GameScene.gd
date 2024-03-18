class_name GameScene extends Node


enum GameState {
	PREGAME,
	PLAYING,
	PAUSED,
}


@export var _pause_hud: Control
@export var _hud: HUD
@export var _map: Map
@export var _wave_spawner: WaveSpawner
@export var _ui_canvas_layer: CanvasLayer
@export var _camera: Camera2D
@export var _player_container: PlayerContainer
@export var _game_start_timer: Timer
@export var _next_wave_timer: Timer
@export var _extreme_timer: Timer
@export var _game_time: GameTime
@export var _object_container: Node2D
@export var _select_point_for_cast: SelectPointForCast
@export var _select_target_for_cast: SelectTargetForCast
@export var _move_item: MoveItem
@export var _select_unit: SelectUnit
@export var _build_tower: BuildTower
@export var _mouse_state: MouseState
@export var _tower_preview: TowerPreview
@export var _horadric_cube: HoradricCube
@export var _pregame_controller: PregameController
@export var _ui_layer: CanvasLayer


var _game_state: GameState = GameState.PREGAME
var _prev_effect_id: int = 0
var _game_over: bool = false
var _room_code: int = 0
var _difficulty: Difficulty.enm = Config.default_difficulty()
# This rng is used to create seeds for all other rng's and
# to sync seeds between peers.
var _origin_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tutorial_controller: TutorialController = null
var _tutorial_menu: TutorialMenu = null


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
	EventBus.creep_got_killed.connect(_on_creep_got_killed)
	EventBus.creep_reached_portal.connect(_on_creep_reached_portal)
	EventBus.player_requested_start_game.connect(_on_player_requested_start_game)
	EventBus.player_requested_next_wave.connect(_on_player_requested_next_wave)
	EventBus.player_requested_to_roll_towers.connect(_on_player_requested_to_roll_towers)
	EventBus.player_requested_to_research_element.connect(_on_player_requested_to_research_element)
	EventBus.player_requested_to_build_tower.connect(_on_player_requested_to_build_tower)
	EventBus.player_requested_to_upgrade_tower.connect(_on_player_requested_to_upgrade_tower)
	EventBus.player_requested_to_sell_tower.connect(_on_player_requested_to_sell_tower)
	EventBus.player_requested_to_select_point_for_autocast.connect(_on_player_requested_to_select_point_for_autocast)
	EventBus.player_requested_to_select_target_for_autocast.connect(_on_player_requested_to_select_target_for_autocast)
	EventBus.player_requested_transmute.connect(_on_player_requested_transmute)
	EventBus.player_requested_autofill.connect(_on_player_requested_autofill)

	_select_unit.selected_unit_changed.connect(_on_selected_unit_changed)

	if Config.run_prerender_tool():
		var running_on_web: bool = OS.get_name() == "Web"

		if !running_on_web:
			PrerenderTool.run(self, _ui_canvas_layer, _map)

#			NOTE: do early return here so that the game is
#			not paused and we can take pictures of the map
#			properly.
			return
		else:
			push_error("config/run_prerender_tool is enabled by mistake. Skipping prerender because this is a Web build.")

# 	NOTE: this is where normal gameplay starts
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()

	get_tree().set_pause(true)
	
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		_room_code = _get_cmdline_value("room_code")
		assert(_room_code, "Room code wasn't provided with headless mode enabled.")
		print("Room code: %s" % _room_code)
	
	_pregame_controller.start()


# NOTE: these stats are constantly changing and might even
# change multiple times per frame so we need to update them
# in _process instead of via signals
func _process(_delta: float):
	var local_player: Player = _player_container.get_local_player()
	
	if local_player == null:
		return
	
	var all_players: Array[Player] = _player_container.get_all_players()
	_hud.load_player_stats(local_player, all_players)

	var game_time: float = Utils.get_time()
	_hud.set_game_time(game_time)

	var gold: float = local_player.get_gold()
	_hud.set_gold(gold)

	var tomes: int = local_player.get_tomes()
	_hud.set_tomes(tomes)

	var food: int = local_player.get_food()
	var food_cap: int = local_player.get_food_cap()
	_hud.set_food(food, food_cap)
	

func _unhandled_input(event: InputEvent):
	var cancel_pressed: bool = event.is_action_released("ui_cancel") || event.is_action_released("pause")
	var left_click: bool = event.is_action_released("left_click")
	var right_click: bool = event.is_action_released("right_click")
	var hovered_unit: Unit = _select_unit.get_hovered_unit()
	var hovered_tower: Tower = hovered_unit as Tower
	var selected_unit: Unit = _select_unit.get_selected_unit()
	var local_player: Player = _player_container.get_local_player()
	
	if local_player == null:
		return

	if cancel_pressed:
#		1. First, any ongoing actions are cancelled
#		2. Then, if there are no mouse actions, hud windows
#		   are hidden
#		3. Finally, game is paused
		if _mouse_state.get_state() != MouseState.enm.NONE:
			_cancel_current_mouse_action()
		elif _hud.any_window_is_open():
			_hud.hide_all_windows()
		elif selected_unit != null:
			_select_unit.set_selected_unit(null)
		else:
			match _game_state:
				GameState.PLAYING: _pause_the_game()
				GameState.PAUSED: _unpause_the_game()
	elif left_click:
		match _mouse_state.get_state():
			MouseState.enm.BUILD_TOWER: _build_tower.try_to_finish(local_player)
			MouseState.enm.SELECT_POINT_FOR_CAST: _select_point_for_cast.finish(_map)
			MouseState.enm.SELECT_TARGET_FOR_CAST: _select_target_for_cast.finish(hovered_unit)
			MouseState.enm.MOVE_ITEM:
				if hovered_tower != null:
					_move_item.process_click_on_tower(hovered_tower)
				else:
					_move_item.process_click_on_nothing(_map)
			MouseState.enm.NONE:
#				NOTE: if clicked on unit, will selected that unit
#				if clicked on nothing - deselect
				_select_unit.set_selected_unit(hovered_unit)
	elif right_click:
		if _mouse_state.get_state() != MouseState.enm.NONE:
			_cancel_current_mouse_action()
		else:
			_do_manual_targetting()


#########################
###      Private      ###
#########################

func _cancel_current_mouse_action():
	match _mouse_state.get_state():
		MouseState.enm.BUILD_TOWER: _build_tower.cancel()
		MouseState.enm.SELECT_POINT_FOR_CAST: _select_point_for_cast.cancel()
		MouseState.enm.SELECT_TARGET_FOR_CAST: _select_target_for_cast.cancel()
		MouseState.enm.MOVE_ITEM: _move_item.cancel()


# Manual targeting forces towers to attack the clicked
# target until it dies.
# 
# There are two scenario's:
#
# 1. If no tower is selected, then all towers will switch to
#    the target.
# 2. If a tower is selected, then only the selected tower
#    will switch to the target.
func _do_manual_targetting():
	var selected_unit: Unit = _select_unit.get_selected_unit()
	var hovered_unit: Unit = _select_unit.get_hovered_unit()

	if !hovered_unit is Creep:
		return

	var hovered_creep: Creep = hovered_unit as Creep

	var tower_list: Array[Tower]
	if selected_unit is Tower:
		var selected_tower: Tower = selected_unit as Tower
		tower_list.append(selected_tower)
	else:
		tower_list = Utils.get_tower_list()

	for tower in tower_list:
		tower.force_attack_target(hovered_creep)

#	NOTE: destroy prev effect so that there's only one arrow
#	up at a time
	Effect.destroy_effect(_prev_effect_id)
	var effect: int = Effect.create_simple_on_unit("res://Scenes/Effects/TargetArrow.tscn", hovered_creep, Unit.BodyPart.HEAD)
	Effect.set_lifetime(effect, 2.0)
	_prev_effect_id = effect


# TODO: fix for multiplayer. Add towers to tower stash using rpc.
func _roll_towers_after_wave_finish():
	var local_player: Player = _player_container.get_local_player()
	var rolled_towers: Array[int] = TowerDistribution.roll_towers(local_player)
	var tower_stash: TowerStash = local_player.get_tower_stash()
	tower_stash.add_towers(rolled_towers)
	
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
	_game_time.set_enabled(false)

	_game_state = GameState.PAUSED
	get_tree().set_pause(true)
	_pause_hud.show()


func _unpause_the_game():
	_game_state = GameState.PLAYING
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


func _on_pregame_controller_finished():
	get_tree().set_pause(false)

	var local_builder_id: int = _pregame_controller.get_builder_id()

#	TODO: the current setup is incorrect for real game case.
#	We set same seed for team and then that same seed is
#	used to generate waves.
#	In reality, each player should have their own wave
#	spawner and each spawner should have different seed.
#	So need to implement multiple wave spawners and use
#	player seeds on them, not team seeds.
	var team_seed: int = _origin_rng.randi()

#	Create local player and remote players
	var local_peer_id: int = multiplayer.get_unique_id()
	var local_player: Player = Player.make(local_peer_id, local_builder_id)
	local_player.set_seed(team_seed)
	_player_container.add_player(local_player)
	print_verbose("Added local player with id: ", local_peer_id)
	
	var peer_id_list: PackedInt32Array = multiplayer.get_peers()
	for peer_id in peer_id_list:
#		TODO: use builder id which was selected by remote
#		player. Remote players need to communicate which
#		builder they selected.
		var remote_player: Player = Player.make(peer_id, local_builder_id)
		remote_player.set_seed(team_seed)
		_player_container.add_player(remote_player)
		print_verbose("Added remote player with id: ", peer_id)
	
	var local_builder: Builder = local_player.get_builder()
	var local_builder_name: String = local_builder.get_display_name()
	_hud.set_local_builder_name(local_builder_name)
	if local_builder.get_adds_extra_recipes():
		_hud.enable_extra_recipes()

	local_player.item_stash_changed.connect(_on_local_player_item_stash_changed)
	local_player.horadric_stash_changed.connect(_on_local_player_horadric_stash_changed)
	local_player.tower_stash_changed.connect(_on_local_player_tower_stash_changed)
	_hud.set_player(local_player)
	_move_item.set_player(local_player)
	_wave_spawner.set_player(local_player)
	_tower_preview.set_player(local_player)

	var wave_count: int = Globals.get_wave_count()
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var tutorial_enabled: bool = _pregame_controller.get_tutorial_enabled()
	
	_hud.set_pregame_settings(wave_count, game_mode, _difficulty)

	var upgrade_button_should_be_visible: bool = game_mode == GameMode.enm.BUILD || game_mode == GameMode.enm.RANDOM_WITH_UPGRADES
	_hud.set_upgrade_button_visible(upgrade_button_should_be_visible)

# 	TODO: fix for multiplayer. I think tutorial should be
# 	disabled in multiplayer case.
	if tutorial_enabled:
		var tutorial_item: Item = Item.make(80, local_player)
		var tutorial_oil: Item = Item.make(1001, local_player)
		var item_stash: ItemContainer = local_player.get_item_stash()
		item_stash.add_item(tutorial_item)
		item_stash.add_item(tutorial_oil)

# 	TODO: fix for multiplayer. Add towers to tower stash via rpc call.
	if game_mode == GameMode.enm.BUILD:
		var tower_stash: TowerStash = local_player.get_tower_stash()
		tower_stash.add_all_towers()
	
	var difficulty_string: String = Difficulty.convert_to_string(_difficulty)
	var game_mode_string: String = GameMode.convert_to_string(game_mode)

	Messages.add_normal("Welcome to You TD 2!")
	Messages.add_normal("Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, game_mode_string])
	Messages.add_normal("You can pause the game by pressing [color=GOLD]Esc[/color]")

	_wave_spawner.generate_waves(wave_count, _difficulty)

	var next_waves: Array[Wave] = _get_next_5_waves()
	_hud.show_wave_details(next_waves)

	if Globals.get_game_mode() == GameMode.enm.BUILD:
		_hud.hide_roll_towers_button()

	var test_item_list: Array = Config.test_item_list()
	for item_id in test_item_list:
		var item: Item = Item.make(item_id, local_player)
		var item_stash: ItemContainer = local_player.get_item_stash()
		item_stash.add_item(item)

	_game_state = GameState.PLAYING

	if tutorial_enabled:
		_start_tutorial(game_mode)
	else:
		_transition_from_tutorial_state()


func _start_tutorial(game_mode: GameMode.enm):
	var tutorial_menu_scene: PackedScene = preload("res://Scenes/HUD/TutorialMenu.tscn")
	_tutorial_menu = tutorial_menu_scene.instantiate()
	
#	NOTE: add tutorial below pause menu so that game can show the pause menu on top of tutorial
	_ui_layer.add_child(_tutorial_menu)
	var pause_menu_index: int = _pause_hud.get_index()
	_ui_layer.move_child(_tutorial_menu, pause_menu_index)
	
	_tutorial_controller = TutorialController.new()
	_tutorial_controller.finished.connect(_on_tutorial_controller_finished)
	add_child(_tutorial_controller)
	_tutorial_controller.start(_tutorial_menu, game_mode)


func _transition_from_tutorial_state():
	Messages.add_normal("The first wave will spawn in 3 minutes.")
	Messages.add_normal("You can start the first wave early by pressing on [color=GOLD]Start next wave[/color].")
	
	_game_start_timer.start(Constants.TIME_BEFORE_FIRST_WAVE)
	_hud.show_game_start_time()

	var local_player: Player = _player_container.get_local_player()

#	NOTE: below are special tools which are not run during
#	normal gameplay.
	if Config.run_save_tooltips_tool():
		SaveTooltipsTool.run(local_player)

#	NOTE: tower tests need to run after everything else has
#	been initialized
	if Config.run_test_towers_tool():
		TestTowersTool.run(self, local_player)

	if Config.run_test_horadric_tool():
		TestHoradricTool.run(local_player)


# TODO: move global state into nodes which are children of
# GameScene so that it's automatically reset
func _reset_singletons():
	Effect.reset()


@rpc("any_peer", "call_local", "reliable")
func _start_game():
	_game_start_timer.stop()
	_hud.hide_game_start_time()
	_hud.show_next_wave_button()
	_hud.hide_roll_towers_button()

	_wave_spawner.start_wave(1)
	
	if _difficulty == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)

#	NOTE: start counting game time after first wave starts
	_game_time.set_enabled(true)


@rpc("any_peer", "call_local", "reliable")
func _start_next_wave():
	_extreme_timer.stop()
	_next_wave_timer.stop()

	var local_player: Player = _player_container.get_local_player()
	local_player.get_team().increment_level()
	var level: int = local_player.get_team().get_level()

	_wave_spawner.start_wave(level)

	_hud.hide_next_wave_time()
	_hud.update_level(level)
	var next_waves: Array[Wave] = _get_next_5_waves()
	_hud.show_wave_details(next_waves)
	var started_last_wave: bool = level == Globals.get_wave_count()
	if started_last_wave:
		_hud.disable_next_wave_button()

	if !started_last_wave && _difficulty == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)


func _get_next_5_waves() -> Array[Wave]:
	var wave_list: Array[Wave] = []
	var local_player: Player = _player_container.get_local_player()
	var current_level: int = local_player.get_team().get_level()
	
	for level in range(current_level, current_level + 6):
		var wave: Wave = _wave_spawner.get_wave(level)
		
		if wave != null:
			wave_list.append(wave)

	return wave_list


@rpc("any_peer", "call_local", "reliable")
func _set_pregame_settings(game_length: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, origin_seed: int):
	Globals._wave_count = game_length
	Globals._game_mode = game_mode
	_difficulty = difficulty
	
# 	This function is used by host to set seeds on other peers
# 	so everyone in network has same origing seed.
	_origin_rng.seed = origin_seed
	
	if multiplayer.is_server():
		print_verbose("Host set origin seed to: ", origin_seed)
	else:
		print_verbose("Peer received origin seed from host: ", origin_seed)
	
	_pregame_controller.go_to_builder_tab()


#########################
###     Callbacks     ###
#########################

func _on_pause_hud_resume_pressed():
	_unpause_the_game()


func _on_tutorial_controller_finished():
	_tutorial_controller.queue_free()
	_tutorial_menu.queue_free()
	
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


func _on_local_player_item_stash_changed():
	var local_player: Player = _player_container.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_list: Array[Item] = item_stash.get_item_list()
	_hud.set_items(item_list)


func _on_local_player_horadric_stash_changed():
	var local_player: Player = _player_container.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	_hud.set_items_for_horadric_cube(item_list)


func _on_local_player_tower_stash_changed():
	var local_player: Player = _player_container.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var towers: Dictionary = tower_stash.get_towers()
	_hud.set_towers(towers)


func _on_wave_finished(level: int):
	Messages.add_normal("=== Level [color=GOLD]%d[/color] completed! ===" % level)
	
	var local_player: Player = _player_container.get_local_player()
	local_player.add_income(level)
	local_player.add_tome_income()

	if Globals.game_mode_is_random():
		_roll_towers_after_wave_finish()

	_extreme_timer.stop()
	_next_wave_timer.start(Constants.TIME_BETWEEN_WAVES)
	_hud.show_next_wave_time(Constants.TIME_BETWEEN_WAVES)

#	TODO: need to apply builder wave finished for all
#	players
	local_player.apply_builder_wave_finished_effect()


func _on_creep_got_killed(creep: Creep):
	var creep_score: float = creep.get_score(_difficulty, Globals.get_wave_count(), Globals.get_game_mode())

	if creep_score > 0:
		var player: Player = creep.get_player()
		player.add_score(creep_score)


func _on_creep_reached_portal(creep: Creep):
	var damage_to_portal = creep.get_damage_to_portal()
	var damage_to_portal_string: String = Utils.format_percent(damage_to_portal / 100, 1)
	var damage_done: float = creep.get_damage_done()
	var damage_done_string: String = Utils.format_percent(damage_done, 2)
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_size_string: String = CreepSize.convert_to_string(creep_size)
	var creep_score: float = creep.get_score(_difficulty, Globals.get_wave_count(), Globals.get_game_mode())

	if creep_size == CreepSize.enm.BOSS:
		Messages.add_normal("Dealt %s damage to BOSS" % damage_done_string)
	else:
		Messages.add_normal("Failed to kill a %s" % creep_size_string.to_upper())		

	if damage_to_portal > 0:
		Messages.add_normal("You lose %s of your lives!" % damage_to_portal_string)

	if creep_score > 0:
		creep.get_player().add_score(creep_score)

	var local_player: Player = _player_container.get_local_player()
	local_player.get_team().modify_lives(-damage_to_portal)

	SFX.play_sfx("res://Assets/SFX/Assets_SFX_hit_3.mp3")

	var out_of_lives: bool = local_player.get_team().get_lives_percent() == 0
	
	if out_of_lives && !_game_over:
		Messages.add_normal("[color=RED]The portal has been destroyed! The game is over.[/color]")
		_game_over = true

		_next_wave_timer.stop()
		_extreme_timer.stop()

		_hud.show_game_over()
		_hud.disable_next_wave_button()


func _on_player_requested_start_game():
	var tower_list: Array[Tower] = Utils.get_tower_list()
	var built_at_least_one_tower: bool = !tower_list.is_empty()

	if !built_at_least_one_tower:
		Messages.add_error("You have to build some towers before you can start the game!")

		return
	
	_start_game.rpc()


func _on_game_start_timer_timeout():
	_start_game()


func _on_player_requested_next_wave():
	if _game_over:
		Messages.add_error("Can't start next wave because the game is over.")

		return

	var wave_is_in_progress: bool = _wave_spawner.wave_is_in_progress()
	if wave_is_in_progress:
		Messages.add_error("Can't start next wave because a wave is in progress.")
		
		return
	
	_start_next_wave.rpc()


func _on_extreme_timer_timeout():
	_next_wave_timer.start(Constants.EXTREME_DELAY_BEFORE_NEXT_WAVE)
	_hud.show_next_wave_time(Constants.EXTREME_DELAY_BEFORE_NEXT_WAVE)


func _on_next_wave_timer_timeout():
	_start_next_wave()


func _on_player_requested_to_roll_towers():
	var researched_any_elements: bool = false
	
	var local_player: Player = _player_container.get_local_player()
	
	for element in Element.get_list():
		var researched_element: bool = local_player.get_element_level(element)
		if researched_element:
			researched_any_elements = true
	
	if !researched_any_elements:
		Messages.add_error("Cannot roll towers yet! You need to research at least one element.")
	
		return

	var tower_count_for_roll: int = local_player.get_tower_count_for_starting_roll()

	if tower_count_for_roll == 0:
		Messages.add_error("You cannot reroll towers anymore.")
	
		return
	
#	TODO: fix for multiplayer. Everything after this point
#	should be inside rpc call.
	var tower_stash: TowerStash = local_player.get_tower_stash()
	tower_stash.clear()
	
	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(local_player, tower_count_for_roll)
	tower_stash.add_towers(rolled_towers)
	local_player.decrement_tower_count_for_starting_roll()


func _on_player_requested_to_research_element(element: Element.enm):
	var local_player: Player = _player_container.get_local_player()
	var current_level: int = local_player.get_element_level(element)
	var element_at_max: bool = current_level == Constants.MAX_ELEMENT_LEVEL

	if element_at_max:
		Messages.add_error("Can't research element. Element is at max level.")

		return

	var can_afford_research: bool = local_player.can_afford_research(element)

	if !can_afford_research:
		Messages.add_error("Can't research element. You do not have enough tomes.")

		return

	var cost: int = local_player.get_research_cost(element)
	local_player.spend_tomes(cost)
	local_player.increment_element_level(element)

	var new_element_levels: Dictionary = local_player.get_element_level_map()
	_hud.update_element_level(new_element_levels)


func _on_player_requested_to_build_tower(tower_id: int):
	var local_player: Player = _player_container.get_local_player()
	_build_tower.start(tower_id, local_player)


func _on_player_requested_to_upgrade_tower(tower: Tower):
	var prev_id: int = tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(tower.get_id())

	if upgrade_id == -1:
		print_debug("Failed to find upgrade id")

		return

	var local_player: Player = _player_container.get_local_player()

	var enough_gold: bool = local_player.enough_gold_for_tower(upgrade_id)

	if !enough_gold:
		Messages.add_error("Not enough gold.")

		return

	var upgrade_tower: Tower = TowerManager.get_tower(upgrade_id, local_player)
	upgrade_tower.position = tower.position
	upgrade_tower._temp_preceding_tower = tower
	Utils.add_object_to_world(upgrade_tower)
	tower.queue_free()

	_select_unit.set_selected_unit(upgrade_tower)

	var refund_for_prev_tier: float = TowerProperties.get_cost(prev_id)
	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	local_player.add_gold(refund_for_prev_tier)
	local_player.spend_gold(upgrade_cost)


func _on_player_requested_to_sell_tower(tower: Tower):
	_map.clear_space_occupied_by_tower(tower)

# 	Return tower items to item stash
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var tower_id: int = tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	var local_player: Player = _player_container.get_local_player()
	local_player.give_gold(sell_price, tower, false, true)
	local_player.remove_food_for_tower(tower_id)

	_map.clear_space_occupied_by_tower(tower)

	tower.queue_free()


func _on_player_requested_to_select_point_for_autocast(autocast: Autocast):
	_select_point_for_cast.start(autocast)


func _on_player_requested_to_select_target_for_autocast(autocast: Autocast):
	_select_target_for_cast.start(autocast)


func _on_selected_unit_changed(_prev_unit: Unit):
	var selected_unit: Unit = _select_unit.get_selected_unit()
	_hud.set_menu_unit(selected_unit)


func _on_player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array):
	var local_player: Player = _player_container.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	_horadric_cube.autofill(recipe, rarity_filter, item_stash, horadric_stash)


func _on_player_requested_transmute():
	var local_player: Player = _player_container.get_local_player()
	_horadric_cube.transmute(local_player)


func _on_pregame_controller_selected_host_settings():
#	NOTE: in singleplayer case, this simply sets the
#	settings locally. In multiplayer case, this will
#	cause the host to broadcast game settings to
#	peers.
	var game_length: int = _pregame_controller.get_game_length()
	var difficulty: Difficulty.enm = _pregame_controller.get_difficulty()
	var game_mode: GameMode.enm = _pregame_controller.get_game_mode()
	
#	NOTE: host randomizes their rng, other peers will
#	receive this seed from host when connecting via
#	_set_origin_rng_seed().
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var origin_seed: int = rng.seed
	print_verbose("Generated origin seed on host: ", origin_seed)

	_set_pregame_settings.rpc(game_length, game_mode, difficulty, origin_seed)
