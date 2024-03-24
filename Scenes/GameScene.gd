class_name GameScene extends Node


@export var _game_menu: Control
@export var _hud: HUD
@export var _map: Map
@export var _ui_canvas_layer: CanvasLayer
@export var _camera: Camera2D
@export var _team_container: TeamContainer
@export var _game_start_timer: ManualTimer
@export var _object_container: Node2D
@export var _select_point_for_cast: SelectPointForCast
@export var _select_target_for_cast: SelectTargetForCast
@export var _move_item: MoveItem
@export var _select_unit: SelectUnit
@export var _build_tower: BuildTower
@export var _mouse_state: MouseState
@export var _tower_preview: TowerPreview
@export var _horadric_cube: HoradricCube
@export var _ui_layer: CanvasLayer
@export var _simulation: Simulation
@export var _game_time: GameTime


var _prev_effect_id: int = 0
var _game_over: bool = false
var _room_code: int = 0
var _pregame_controller: PregameController = null
var _pregame_hud: PregameHUD = null
var _tutorial_controller: TutorialController = null
var _tutorial_menu: TutorialMenu = null
var _completed_pregame: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("GameScene has loaded.")

	Globals.reset()
	PlayerManager.reset()

	_hud.set_game_start_timer(_game_start_timer)

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
	EventBus.player_right_clicked_autocast.connect(_on_player_right_clicked_autocast)
	EventBus.player_right_clicked_item.connect(_on_player_right_clicked_item)
	EventBus.player_shift_right_clicked_item.connect(_on_player_shift_right_clicked_item)

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
	
	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()

	if show_pregame_settings_menu:
		var pregame_hud_scene: PackedScene = preload("res://Scenes/PregameHUD/PregameHUD.tscn")
		_pregame_hud = pregame_hud_scene.instantiate()
		_ui_layer.add_child(_pregame_hud)

		_pregame_controller = PregameController.new()
		_pregame_controller.finished.connect(_on_pregame_controller_finished)
		add_child(_pregame_controller)

		_pregame_controller.start(_pregame_hud)
	else:
#		Use default setting values when skipping pregame
#		settings
		var player_mode: PlayerMode.enm = PlayerMode.enm.SINGLE
		var wave_count: int = Config.default_game_length()
		var difficulty: Difficulty.enm = Config.default_difficulty()
		var game_mode: GameMode.enm = Config.default_game_mode()
		var origin_seed: int = randi()
		print_verbose("Generated origin seed locally: ", origin_seed)
		
		_transition_from_pregame.rpc(player_mode, wave_count, game_mode, difficulty, origin_seed)


func _unhandled_input(event: InputEvent):
	if !_completed_pregame:
		return

	var enter_pressed: bool = event.is_action_released("ui_text_newline")
	var cancel_pressed: bool = event.is_action_released("ui_cancel") || event.is_action_released("pause")
	var left_click: bool = event.is_action_released("left_click")
	var right_click: bool = event.is_action_released("right_click")
	var hovered_unit: Unit = _select_unit.get_hovered_unit()
	var hovered_tower: Tower = hovered_unit as Tower
	var selected_unit: Unit = _select_unit.get_selected_unit()
	var local_player: Player = PlayerManager.get_local_player()
	var editing_chat: bool = _hud.editing_chat()
	
	if enter_pressed:
		if !editing_chat:
			_start_editing_chat()
		else:
			_submit_chat_message()
	elif cancel_pressed:
#		1. First, any ongoing actions are cancelled
#		2. Then, if there are no mouse actions, hud windows
#		   are hidden
#		3. Finally, game is paused
		if _mouse_state.get_state() != MouseState.enm.NONE:
			_cancel_current_mouse_action()
		elif editing_chat:
			_finish_editing_chat()
		elif _hud.any_window_is_open():
			_hud.hide_all_windows()
		elif selected_unit != null:
			_select_unit.set_selected_unit(null)
		else:
			_toggle_game_menu()
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

func _toggle_autocast(autocast: Autocast):
	var local_player: Player = PlayerManager.get_local_player()
	var can_use_auto: bool = autocast.can_use_auto_mode()

	if !can_use_auto:
		Messages.add_error(local_player, "This ability cannot be casted automatically")

		return

	var autocast_uid: int = autocast.get_uid()

	var action: Action = ActionToggleAutocast.make(autocast_uid)
	_simulation.add_action(action)


func _get_camera_origin_pos() -> Vector2:
	var local_player: Player = PlayerManager.get_local_player()
	var local_player_id: int = local_player.get_id()
	
	var local_camera_origin: CameraOrigin = null
	
	var camera_origin_list: Array[Node] = get_tree().get_nodes_in_group("camera_origins")
	
	for node in camera_origin_list:
		if !node is CameraOrigin:
			push_error("Incorrect type in camera_origins group")
			
			continue
		
		var camera_origin: CameraOrigin = node as CameraOrigin
		var player_id: int = camera_origin.player_id
		var player_match: bool = player_id == local_player_id
		
		if player_match:
			local_camera_origin = camera_origin
			
			break
	
	if local_camera_origin == null:
		push_error("Failed to find local camera origin")
		
		return Vector2.ZERO
	
	var camera_origin_pos: Vector2 = local_camera_origin.position

	return camera_origin_pos
	

func _start_editing_chat():
	_hud.start_editing_chat()
	_camera.set_keyboard_enabled(false)


func _finish_editing_chat():
	_hud.finish_editing_chat()
	_camera.set_keyboard_enabled(true)


func _submit_chat_message():
	var chat_message: String = _hud.get_chat_edit_text()
	_finish_editing_chat()

	var chat_action: Action = ActionChat.make(chat_message)
	_simulation.add_action(chat_action)


func _set_builder_for_local_player(builder_id: int):
	var action: Action = ActionSelectBuilder.make(builder_id)
	_simulation.add_action(action)


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


func _toggle_game_menu():
	if !_completed_pregame:
		return
	
	_game_menu.visible = !_game_menu.visible

	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.SINGLE:
		var tree: SceneTree = get_tree()
		tree.paused = !tree.paused


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
#	NOTE: in singleplayer case, this simply sets the
#	settings locally. In multiplayer case, this will
#	cause the host to broadcast game settings to
#	peers.
	var player_mode: PlayerMode.enm = _pregame_controller.get_player_mode()
	var wave_count: int = _pregame_controller.get_game_length()
	var difficulty: Difficulty.enm = _pregame_controller.get_difficulty()
	var game_mode: GameMode.enm = _pregame_controller.get_game_mode()
	
#	NOTE: host randomizes their rng, other peers will
#	receive this seed from host when connecting via
#	_set_origin_rng_seed().
	var origin_seed: int = randi()
	print_verbose("Generated origin seed on host: ", origin_seed)

	_transition_from_pregame.rpc(player_mode, wave_count, game_mode, difficulty, origin_seed)


# This is called when host is finished selecting all of the
# pregame settings.
@rpc("any_peer", "call_local", "reliable")
func _transition_from_pregame(player_mode: PlayerMode.enm, wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm, origin_seed: int):
	_pregame_hud.queue_free()
	_pregame_controller.queue_free()
	
	Globals._player_mode = player_mode
	Globals._wave_count = wave_count
	Globals._game_mode = game_mode
	Globals._difficulty = difficulty
	
# 	Set the global seed so that rng on this game client is
# 	the same as on all other clients.
	seed(origin_seed)
	
	if multiplayer.is_server():
		print_verbose("Host set origin seed to: ", origin_seed)
	else:
		print_verbose("Peer received origin seed from host: ", origin_seed)
	
#	Create local player and remote players
	var peer_id_list: Array[int] = []
	var local_peer_id: int = multiplayer.get_unique_id()
	peer_id_list.append(local_peer_id)
	var remote_peer_id_list: PackedInt32Array = multiplayer.get_peers()
	for peer_id in remote_peer_id_list:
		peer_id_list.append(peer_id)

#	NOTE: create players in the order of peer id's to ensure determinism
	peer_id_list.sort()
	
	if peer_id_list.size() > 2:
		push_error("Too many players. Game supports at most 2.")

		return
	
#	Create teams
#	TODO: create an amount of teams which is appropriate for the amount of players and selected team mode
	var team_count: int = peer_id_list.size()
	for i in range(0, team_count):
		var team: Team = Team.make(i)
		_team_container.add_team(team)

#	TODO: implement different team modes and assign teams based on selected team mode
	for peer_id in peer_id_list:
		var player_id: int = peer_id_list.find(peer_id)
		var team_for_player: Team = _team_container.get_team(player_id)
		var player: Player = team_for_player.create_player(player_id, peer_id)
		PlayerManager.add_player(player)

	var local_player: Player = PlayerManager.get_local_player()
	var local_team: Team = local_player.get_team()
	local_team.game_over.connect(_on_local_team_game_over)
	
	local_player.item_stash_changed.connect(_on_local_player_item_stash_changed)
	local_player.horadric_stash_changed.connect(_on_local_player_horadric_stash_changed)
	local_player.tower_stash_changed.connect(_on_local_player_tower_stash_changed)
	_hud.set_player(local_player)
	_move_item.set_player(local_player)
	_tower_preview.set_player(local_player)
	
	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		player.voted_ready.connect(_on_player_voted_ready)
	
	if game_mode == GameMode.enm.BUILD:
		for player in player_list:
			var tower_stash: TowerStash = player.get_tower_stash()
			tower_stash.add_all_towers()
	
	var difficulty_string: String = Difficulty.convert_to_string(Globals.get_difficulty())
	var game_mode_string: String = GameMode.convert_to_string(game_mode)

	Messages.add_normal(local_player, "Welcome to You TD 2!")
	Messages.add_normal(local_player, "Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, game_mode_string])
	Messages.add_normal(local_player, "You can pause the game by pressing [color=GOLD]Esc[/color]")

	for player in player_list:
		player.generate_waves()

	var next_waves: Array[Wave] = local_player.get_next_5_waves()
	_hud.show_wave_details(next_waves)

	if Globals.get_game_mode() == GameMode.enm.BUILD:
		_hud.hide_roll_towers_button()

	var test_item_list: Array = Config.test_item_list()
	for item_id in test_item_list:
		var item: Item = Item.make(item_id, local_player)
		var item_stash: ItemContainer = local_player.get_item_stash()
		item_stash.add_item(item)

	var skip_builder_menu: bool = !Config.show_pregame_settings_menu()
	if skip_builder_menu:
		var builder_id: int = Config.default_builder_id()
		_set_builder_for_local_player(builder_id)
	else:
		var builder_menu: BuilderMenu = preload("res://Scenes/PregameHUD/BuilderMenu.tscn").instantiate()
		builder_menu.finished.connect(_on_builder_menu_finished.bind(builder_menu))
		
#		NOTE: add builder menu below game menu so that game
#		can show the game menu on top of tutorial
		_ui_layer.add_child(builder_menu)
		var game_menu_index: int = _game_menu.get_index()
		_ui_layer.move_child(builder_menu, game_menu_index)
	
	Messages.add_normal(local_player, "The first wave will spawn in 3 minutes.")
	Messages.add_normal(local_player, "You can start the first wave early by pressing on [color=GOLD]Start next wave[/color].")
	
	_game_start_timer.start(Constants.TIME_BEFORE_FIRST_WAVE)
	
#	NOTE: reduce action delay for singleplayer
#	TODO: should really make the perceived latency good
#	enough for both singleplayer and multiplayer to use the
#	same delay.
	if player_mode == PlayerMode.enm.SINGLE:
		_simulation.set_delay(Simulation.SINGLEPLAYER_ACTION_DELAY)
	
	_camera.position = _get_camera_origin_pos()

	get_tree().set_pause(false)
	_completed_pregame = true

#	NOTE: below are special tools which are not run during
#	normal gameplay.
	if Config.run_save_tooltips_tool():
		SaveTooltipsTool.run(local_player)
	
	if Config.run_save_ranges_tool():
		SaveTowerRangesTool.run(local_player)

#	NOTE: tower tests need to run after everything else has
#	been initialized
	if Config.run_test_towers_tool():
		TestTowersTool.run(self, local_player)

	if Config.run_test_horadric_tool():
		TestHoradricTool.run(local_player)


func _start_tutorial(game_mode: GameMode.enm):
#	Add items for tutorial, to allow player to practice moving them.
	var local_player: Player = PlayerManager.get_local_player()
	var tutorial_item: Item = Item.make(80, local_player)
	var tutorial_oil: Item = Item.make(1001, local_player)
	var item_stash: ItemContainer = local_player.get_item_stash()
	item_stash.add_item(tutorial_item)
	item_stash.add_item(tutorial_oil)
		
	var tutorial_menu_scene: PackedScene = preload("res://Scenes/HUD/TutorialMenu.tscn")
	_tutorial_menu = tutorial_menu_scene.instantiate()
	
#	NOTE: add tutorial below game menu so that game can show the game menu on top of tutorial
	_ui_layer.add_child(_tutorial_menu)
	var game_menu_index: int = _game_menu.get_index()
	_ui_layer.move_child(_tutorial_menu, game_menu_index)
	
	_tutorial_controller = TutorialController.new()
	_tutorial_controller.finished.connect(_on_tutorial_controller_finished)
	add_child(_tutorial_controller)
	_tutorial_controller.start(_tutorial_menu, game_mode)


#########################
###     Callbacks     ###
#########################

func _on_game_menu_close_pressed():
	_toggle_game_menu()


func _on_tutorial_controller_finished():
#	NOTE: after player finishes the tutorial, we stop
#	showing it on next game starts. Player can turn it back
#	on in settings.
	Settings.set_setting(Settings.SHOW_TUTORIAL_ON_START, false)
	Settings.flush()

	_tutorial_controller.queue_free()
	_tutorial_menu.queue_free()


func _on_settings_changed():
	var interface_size: float = Settings.get_interface_size()
	get_tree().root.content_scale_factor = interface_size

#	NOTE: need to call update_zoom() to update camera zoom
#	when interface size is changed in settings menu. Calling
#	update_zoom() inside Camera script via callback does not
#	work because the game is paused while the settings menu
#	is open.
	_camera.update_zoom()


func _on_game_menu_restart_pressed():
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
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_list: Array[Item] = item_stash.get_item_list()
	_hud.set_items(item_list)


func _on_local_player_horadric_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	_hud.set_items_for_horadric_cube(item_list)


func _on_local_player_tower_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var tower_stash: TowerStash = local_player.get_tower_stash()
	var towers: Dictionary = tower_stash.get_towers()
	_hud.set_towers(towers)


func _on_player_requested_start_game():
	var local_player_has_towers: bool = false
	var local_player: Player = PlayerManager.get_local_player()
	var tower_list: Array[Tower] = Utils.get_tower_list()
	for tower in tower_list:
		if tower.get_player() == local_player:
			local_player_has_towers = true

	if !local_player_has_towers:
		Messages.add_error(local_player, "You have to build some towers before you can start the game!")

		return

	var action: Action = ActionChat.make(ChatCommands.READY)
	_simulation.add_action(action)


func _on_game_start_timer_timeout():
	_start_game()


func _on_player_requested_next_wave():
	var local_player: Player = PlayerManager.get_local_player()

	if _game_over:
		Messages.add_error(local_player, "Can't start next wave because the game is over.")

		return
	
	var wave_is_in_progress: bool = local_player.wave_is_in_progress()
	if wave_is_in_progress:
		Messages.add_error(local_player, "Can't start next wave because a wave is in progress.")
		
		return
	
	var action: Action = ActionChat.make(ChatCommands.START_NEXT_WAVE)
	_simulation.add_action(action)


func _on_player_requested_to_roll_towers():
	var researched_any_elements: bool = false
	
	var local_player: Player = PlayerManager.get_local_player()
	
	for element in Element.get_list():
		var researched_element: bool = local_player.get_element_level(element)
		if researched_element:
			researched_any_elements = true
	
	if !researched_any_elements:
		Messages.add_error(local_player, "Cannot roll towers yet! You need to research at least one element.")
	
		return

	var tower_count_for_roll: int = local_player.get_tower_count_for_starting_roll()

	if tower_count_for_roll == 0:
		Messages.add_error(local_player, "You cannot reroll towers anymore.")
	
		return

	var action: Action = ActionChat.make(ChatCommands.ROLL_TOWERS)
	_simulation.add_action(action)


func _on_player_requested_to_research_element(element: Element.enm):
	var local_player: Player = PlayerManager.get_local_player()
	var can_request: bool = ChatCommands.verify_research_element(local_player, element)

	if !can_request:
		return

	var action: Action = ChatCommands.make_action_research_element(element)
	_simulation.add_action(action)


func _on_player_requested_to_build_tower(tower_id: int):
	var local_player: Player = PlayerManager.get_local_player()
	_build_tower.start(tower_id, local_player)


func _on_player_requested_to_upgrade_tower(tower: Tower):
	var prev_id: int = tower.get_id()
	var upgrade_id: int = TowerProperties.get_upgrade_id_for_tower(tower.get_id())

	if upgrade_id == -1:
		print_debug("Failed to find upgrade id")

		return

	var local_player: Player = PlayerManager.get_local_player()

	var enough_gold: bool = local_player.enough_gold_for_tower(upgrade_id)

	if !enough_gold:
		Messages.add_error(local_player, "Not enough gold.")

		return

	var upgrade_tower: Tower = Tower.make(upgrade_id, local_player)
	upgrade_tower.position = tower.position
	upgrade_tower._temp_preceding_tower = tower
	Utils.add_object_to_world(upgrade_tower)
	tower.remove_from_game()

	_select_unit.set_selected_unit(upgrade_tower)

	var refund_for_prev_tier: float = TowerProperties.get_cost(prev_id)
	var upgrade_cost: float = TowerProperties.get_cost(upgrade_id)
	local_player.add_gold(refund_for_prev_tier)
	local_player.spend_gold(upgrade_cost)


func _on_player_requested_to_sell_tower(tower: Tower):
	var tower_unit_id: int = tower.get_uid()
	var action: Action = ActionSellTower.make(tower_unit_id)
	_simulation.add_action(action)


func _on_player_requested_to_select_point_for_autocast(autocast: Autocast):
	_select_point_for_cast.start(autocast)


func _on_player_requested_to_select_target_for_autocast(autocast: Autocast):
	_select_target_for_cast.start(autocast)


func _on_selected_unit_changed(_prev_unit: Unit):
	var selected_unit: Unit = _select_unit.get_selected_unit()
	_hud.set_menu_unit(selected_unit)


func _on_player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array):
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	_horadric_cube.autofill(local_player, recipe, rarity_filter, item_stash, horadric_stash)


func _on_player_requested_transmute():
	var local_player: Player = PlayerManager.get_local_player()
	_horadric_cube.transmute(local_player)


func _on_builder_menu_finished(builder_menu: BuilderMenu):
	var builder_id: int = builder_menu.get_builder_id()
	builder_menu.queue_free()
	_set_builder_for_local_player(builder_id)

	var show_tutorial_on_start: bool = Settings.get_bool_setting(Settings.SHOW_TUTORIAL_ON_START)
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var always_show_tutorial: bool = Config.always_show_tutorial()
	
	if (show_tutorial_on_start && player_mode == PlayerMode.enm.SINGLE) || always_show_tutorial:
		_start_tutorial(game_mode)


func _on_local_team_game_over():
	Messages.add_normal(PlayerManager.get_local_player(), "[color=RED]The portal has been destroyed! The game is over.[/color]")
	_hud.show_game_over()


func _on_player_voted_ready():
	var player_list: Array[Player] = PlayerManager.get_player_list()
	
	var not_ready_count: int = 0
	for player in player_list:
		if !player.is_ready():
			not_ready_count += 1
	
	var all_players_are_ready: bool = not_ready_count == 0

	if all_players_are_ready:
		Messages.add_normal(null, "All players are ready, starting game.")
		_start_game()
	else:
		Messages.add_normal(null, "Waiting for %d players to be ready." % not_ready_count)


func _on_player_right_clicked_autocast(autocast: Autocast):
	_toggle_autocast(autocast)


func _on_player_right_clicked_item(item: Item):
	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		autocast.do_cast_manually()
	elif item.is_consumable():
		item.consume()


func _on_player_shift_right_clicked_item(item: Item):
	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		_toggle_autocast(autocast)


func _start_game():
	_game_start_timer.stop()
	_hud.show_next_wave_button()
	_hud.hide_roll_towers_button()
	
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.start_first_wave()
	
#	NOTE: start counting game time after first wave starts
	_game_time.set_enabled(true)
