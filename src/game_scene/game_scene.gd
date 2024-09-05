class_name GameScene extends Node


@export var _game_menu: Control
@export var _hud: HUD
@export var _map: Map
@export var _camera: Camera2D
@export var _team_container: TeamContainer
@export var _game_start_timer: ManualTimer
@export var _select_point_for_cast: SelectPointForCast
@export var _select_target_for_cast: SelectTargetForCast
@export var _move_item: MoveItem
@export var _select_unit: SelectUnit
@export var _build_tower: BuildTower
@export var _mouse_state: MouseState
@export var _ui_layer: CanvasLayer
@export var _game_client: GameClient
@export var _game_time: GameTime
@export var _pause_shadow_rect: ColorRect
@export var _object_container: Node2D
@export var _build_space: BuildSpace
@export var _tutorial_menu: TutorialMenu
@export var _tutorial_controller: TutorialController
@export var _waiting_for_players_indicator: Control


var _builder_menu: BuilderMenu = null


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("GameScene has loaded.")
	
	Globals.reset()
	PlayerManager.reset()
	GroupManager.reset()

#	NOTE: in multiplayer, we have to block UI input via the
#	"waiting for players indicator", until client receives
#	first communication from host. Firsts communication from
#	host means that all clients are ready and the game can
#	start.
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.COOP:
		_waiting_for_players_indicator.show()

	var default_update_ticks_per_physics_tick: int = Config.update_ticks_per_physics_tick()
	Globals.set_update_ticks_per_physics_tick(default_update_ticks_per_physics_tick)
	
	var buildable_cells: Array[Vector2i] = _map.get_buildable_cells()
	_build_space.set_buildable_cells(buildable_cells)

	_hud.set_game_start_timer(_game_start_timer)
	
	EventBus.player_requested_quit_to_title.connect(_on_player_requested_quit_to_title)
	EventBus.player_selected_builder.connect(_on_player_selected_builder)
	EventBus.player_requested_start_game.connect(_on_player_requested_start_game)
	EventBus.player_requested_next_wave.connect(_on_player_requested_next_wave)
	EventBus.player_requested_to_roll_towers.connect(_on_player_requested_to_roll_towers)
	EventBus.player_requested_to_research_element.connect(_on_player_requested_to_research_element)
	EventBus.player_requested_to_build_tower.connect(_on_player_requested_to_build_tower)
	EventBus.player_requested_to_upgrade_tower.connect(_on_player_requested_to_upgrade_tower)
	EventBus.player_requested_to_sell_tower.connect(_on_player_requested_to_sell_tower)
	EventBus.player_clicked_autocast.connect(_on_player_clicked_autocast)
	EventBus.player_requested_transmute.connect(_on_player_requested_transmute)
	EventBus.player_requested_return_from_horadric_cube.connect(_on_player_requested_return_from_horadric_cube)
	EventBus.player_requested_autofill.connect(_on_player_requested_autofill)
	EventBus.player_right_clicked_autocast.connect(_on_player_right_clicked_autocast)
	EventBus.player_right_clicked_item.connect(_on_player_right_clicked_item)
	EventBus.player_shift_right_clicked_item.connect(_on_player_shift_right_clicked_item)
	EventBus.player_clicked_tower_buff_group.connect(_on_player_clicked_tower_buff_group)
	
	_select_unit.selected_unit_changed.connect(_on_selected_unit_changed)

# 	NOTE: this is where normal gameplay starts
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()
	
#	NOTE: load game settings which were selected during TitleScreen. They are passed via Globals.
	var origin_seed: int = Globals.get_origin_seed()
	var game_mode: GameMode.enm = Globals.get_game_mode()

# 	Save the seed which host gave to this client so that rng
# 	on this game client is the same as on all other clients.
	Globals.synced_rng.set_seed(origin_seed)
	
	print_verbose("Origin seed to: ", origin_seed)

	_setup_players()
	PlayerManager.send_players_created_signal()

	var local_player: Player = PlayerManager.get_local_player()
	_tutorial_controller.connect_to_local_player(local_player)
	_hud.connect_to_local_player(local_player)
	
	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		player.voted_ready.connect(_on_player_voted_ready)
	
	if game_mode == GameMode.enm.BUILD:
		for player in player_list:
			var tower_stash: TowerStash = player.get_tower_stash()
			tower_stash.add_all_towers()
	
	for player in player_list:
		player.generate_waves()

	var test_item_list: Array = Config.test_item_list()
	for player in player_list:
		for item_id in test_item_list:
			var item: Item = Item.make(item_id, player)
			var item_stash: ItemContainer = player.get_item_stash()
			item_stash.add_item(item)

	_game_start_timer.start(Constants.TIME_BEFORE_FIRST_WAVE)
	
	_camera.position = _get_camera_origin_pos()

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

	if Config.run_test_items_tool():
		TestItemsTool.run(self, local_player)

	if Config.run_test_horadric_tool():
		TestHoradricTool.run(local_player)

	if Config.run_auto_playtest_bot():
		PlaytestBot.run(_build_space)

	if Config.run_test_tower_sprite_size():
		TestTowerSpriteSize.run()

	if Config.run_test_item_drop_chances():
		TestItemDropChances.run()


func _unhandled_input(event: InputEvent):
	var enter_pressed: bool = event.is_action_released("ui_text_newline")
	var slash_pressed: bool = event.is_action_released("forward_slash")
	var cancel_pressed: bool = event.is_action_released("ui_cancel") || event.is_action_released("pause")
	var left_click: bool = event.is_action_released("left_click")
	var right_click: bool = event.is_action_released("right_click")
	var hovered_unit: Unit = _select_unit.get_hovered_unit()
	var hovered_tower: Tower = hovered_unit as Tower
	var selected_unit: Unit = _select_unit.get_selected_unit()
	var local_player: Player = PlayerManager.get_local_player()
	var editing_chat: bool = _hud.editing_chat()
	
	if slash_pressed && !editing_chat:
#		NOTE: when "/" is pressed, automatically open chat
#		and enter the slash in chat. This makes it
#		convenient to enter chat commands.
		_start_editing_chat()
		_hud.enter_slash_into_chat()
	elif enter_pressed:
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
			_hud.close_one_window()
		elif selected_unit != null:
			_select_unit.set_selected_unit(null)
		elif !_tutorial_menu.visible:
#			NOTE: if tutorial menu is open, the game is
#			already paused so game menu should not be
#			opened. Also note that pressing Escape doesn't
#			close tutorial menu on purpose - to prevent
#			player accidentally cancelling the tutorial.
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
					_move_item.process_click_on_nothing()
			MouseState.enm.NONE:
#				NOTE: if clicked on unit, will selected that unit
#				if clicked on nothing - deselect
				_select_unit.set_selected_unit(hovered_unit)
	elif right_click:
		if _mouse_state.get_state() != MouseState.enm.NONE:
			_cancel_current_mouse_action()
		else:
			_do_focus_target()


#########################
###       Public      ###
#########################

func get_build_space() -> BuildSpace:
	return _build_space


#########################
###      Private      ###
#########################

func _save_player_exp_on_quit():
	var local_player: Player = PlayerManager.get_local_player()
	var local_team: Team = local_player.get_team()

#	NOTE: if finished the game, then don't save exp because
#	exp was already saved during win/lose process.
	var finished_the_game: bool = local_team.finished_the_game()
	if finished_the_game:
		return

	local_team.convert_local_player_score_to_exp()


func _setup_players():
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
#	TODO: create an amount of teams which is appropriate for
#	the amount of players and selected team mode
	var team: Team = Team.make(1)
	_team_container.add_team(team)

	var connection_type: Globals.ConnectionType = Globals.get_connect_type()

#	TODO: implement different team modes and assign teams
#	based on selected team mode
	for peer_id in peer_id_list:
		var player_id: int = peer_id_list.find(peer_id)
		
		var user_id: String
		match connection_type:
			Globals.ConnectionType.ENET:
				user_id = ""
			Globals.ConnectionType.NAKAMA:
				var webrtc_player: OnlineMatch.WebrtcPlayer = OnlineMatch.get_player_by_peer_id(peer_id)
				user_id = webrtc_player.user_id

		var player: Player = team.create_player(player_id, peer_id, user_id)
		PlayerManager.add_player(player)


func _start_game():
	_game_start_timer.stop()

	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.start_first_wave()
	
#	NOTE: start counting game time after first wave starts
	_game_time.set_enabled(true)


func _toggle_autocast(autocast: Autocast):
	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionToggleAutocast.verify(local_player, autocast)

	if !verify_ok:
		return

	var autocast_uid: int = autocast.get_uid()

	var action: Action = ActionToggleAutocast.make(autocast_uid)
	_game_client.add_action(action)


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
	_game_client.add_action(chat_action)


func _cancel_current_mouse_action():
	match _mouse_state.get_state():
		MouseState.enm.BUILD_TOWER: _build_tower.cancel()
		MouseState.enm.SELECT_POINT_FOR_CAST: _select_point_for_cast.cancel()
		MouseState.enm.SELECT_TARGET_FOR_CAST: _select_target_for_cast.cancel()
		MouseState.enm.MOVE_ITEM: _move_item.cancel()


# Focus targeting forces towers to attack the clicked target
# until it dies.
func _do_focus_target():
	var selected_unit: Unit = _select_unit.get_selected_unit()
	var hovered_unit: Unit = _select_unit.get_hovered_unit()

	if !hovered_unit is Creep:
		return

	var hovered_creep: Creep = hovered_unit as Creep
	var target_uid: int = hovered_creep.get_uid()

	var selected_tower: Tower = selected_unit as Tower
	var selected_tower_uid: int
	if selected_tower != null && selected_tower.belongs_to_local_player():
		selected_tower_uid = selected_tower.get_uid()
	else:
		selected_tower_uid = 0

	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionFocusTarget.verify(local_player, hovered_creep, selected_tower)
	if !verify_ok:
		return

	var action: Action = ActionFocusTarget.make(target_uid, selected_tower_uid)
	_game_client.add_action(action)


func _toggle_game_menu():
	_game_menu.visible = !_game_menu.visible

	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode == PlayerMode.enm.SINGLE:
		var toggled_paused_value: bool = !get_tree().paused
		_set_game_paused(toggled_paused_value)


func _set_game_paused(value: bool):
	var tree: SceneTree = get_tree()
	tree.paused = value
	_pause_shadow_rect.visible = value


func _show_tutorial(tutorial_id: TutorialProperties.TutorialId):
	var game_is_paused: bool = get_tree().paused
	if game_is_paused:
		push_error("A tutorial was triggered while game is paused. This should not happen")
		
		return
	
	_set_game_paused(true)
	_tutorial_menu.set_tutorial_id(tutorial_id)
	_tutorial_menu.show()


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


# NOTE: need to remove objects from tree before quitting or
# restarting. Otherwise, creeps will emit tree_exited()
# signals, then WaveSpawner will react to those signals and
# access tree nodes while it's in the process of deletion.
# 
# NOTE: need to remove objects inside while loop because
# some abilities may add new objects when another object is
# removed.
func _cleanup_all_objects():
	while _object_container.get_child_count() > 0:
		var child_list: Array[Node] = _object_container.get_children()

		for child in child_list:
#			NOTE: need to check if child is inside tree
#			because when objects are deleted they can delete
#			other objects.
			if !child.is_inside_tree():
				continue
			
			_object_container.remove_child(child)
			child.queue_free()


#########################
###     Callbacks     ###
#########################

func _on_game_menu_continue_pressed():
	_toggle_game_menu()


func _on_settings_changed():
#	NOTE: need to call update_zoom() to update camera zoom
#	when interface size is changed in settings menu. Calling
#	update_zoom() inside Camera script via callback does not
#	work because the game is paused while the settings menu
#	is open.
	_camera.update_zoom()


func _on_player_requested_start_game():
	var local_player_has_towers: bool = false
	var local_player: Player = PlayerManager.get_local_player()
	var tower_list: Array[Tower] = Utils.get_tower_list()
	for tower in tower_list:
		if tower.get_player() == local_player:
			local_player_has_towers = true

	if !local_player_has_towers:
		Utils.add_ui_error(local_player, "You have to build some towers before you can start the game!")

		return

	var action: Action = ActionChat.make(ChatCommands.READY[0])
	_game_client.add_action(action)


func _on_game_start_timer_timeout():
	_start_game()


func _on_player_requested_next_wave():
	var local_player: Player = PlayerManager.get_local_player()

	var verify_ok: bool = ActionStartNextWave.verify(local_player)

	if !verify_ok:
		return

	var action: Action = ActionStartNextWave.make()
	_game_client.add_action(action)


func _on_player_requested_to_roll_towers():
	var local_player: Player = PlayerManager.get_local_player()
	
	var verify_ok: bool = ActionRollTowers.verify(local_player)

	if !verify_ok:
		return

	var action: Action = ActionRollTowers.make()
	_game_client.add_action(action)


func _on_player_requested_to_research_element(element: Element.enm):
	var local_player: Player = PlayerManager.get_local_player()
	
	var verify_ok: bool = ActionResearchElement.verify(local_player, element)

	if !verify_ok:
		return

	var action: Action = ActionResearchElement.make(element)
	_game_client.add_action(action)


func _on_player_requested_to_build_tower(tower_id: int):
	var local_player: Player = PlayerManager.get_local_player()
	_build_tower.start(tower_id, local_player)


func _on_player_requested_to_upgrade_tower(preceding_tower: Tower):
	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionUpgradeTower.verify(local_player, preceding_tower)
	if !verify_ok:
		return

	var preceding_tower_uid: int = preceding_tower.get_uid()
	var action: Action = ActionUpgradeTower.make(preceding_tower_uid)
	_game_client.add_action(action)


func _on_player_requested_to_sell_tower(tower: Tower):
	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionSellTower.verify(local_player, tower)
	if !verify_ok:
		return

	SFX.play_sfx(SfxPaths.PICKUP_GOLD)

	var tower_unit_id: int = tower.get_uid()
	var action: Action = ActionSellTower.make(tower_unit_id)
	_game_client.add_action(action)


func _on_player_clicked_autocast(autocast: Autocast):
	if !autocast.can_cast():
		autocast.add_cast_error_message()

		return

	var autocast_uid: int = autocast.get_uid()

#	NOTE: immediate autocasts do not have targets. For other
#	autocast types we switch to selecting the target. The
#	cast will finish when player selects a target and
#	SelectTargetForCast.finish() or
#	SelectPointForCast.finish() gets called.
	if autocast.type_is_immediate():
		var target_uid: int = 0
		var target_pos: Vector2 = Vector2.ZERO
		var action: Action = ActionAutocast.make(autocast_uid, target_uid, target_pos)
		_game_client.add_action(action)
	elif autocast.type_is_point():
		_select_point_for_cast.start(autocast)
	else:
		_select_target_for_cast.start(autocast)


func _on_selected_unit_changed(_prev_unit: Unit):
	var selected_unit: Unit = _select_unit.get_selected_unit()
	_hud.set_menu_unit(selected_unit)


func _on_player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array):
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.play_sfx(SfxPaths.PICKUP_ITEM, 0.0, random_pitch)
	
	var local_player: Player = PlayerManager.get_local_player()
	
	var item_stash: ItemContainer = local_player.get_item_stash()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()

#	NOTE: need to also include items which are currently in
#	horadric cube because ignoring them would be an annoying
#	behavior for player. Player would need to manually move
#	all items back to item stash for them to be included in
#	autofill item pool.
	var full_item_list: Array[Item] = []
	var item_stash_item_list: Array[Item] = item_stash.get_item_list()
	var horadric_stash_item_list: Array[Item] = horadric_stash.get_item_list()
	full_item_list.append_array(item_stash_item_list)
	full_item_list.append_array(horadric_stash_item_list)

	var filtered_item_list: Array[Item] = Utils.filter_item_list(full_item_list, rarity_filter)
	var autofill_list: Array[Item] = HoradricCube.get_item_list_for_autofill(recipe, filtered_item_list)

	var can_autofill: bool = !autofill_list.is_empty()
	
	if !can_autofill:
		Utils.add_ui_error(local_player, "Not enough items for recipe!")
		
		return

	var autofill_uid_list: Array[int] = []
	for item in autofill_list:
		var item_uid: int = item.get_uid()
		autofill_uid_list.append(item_uid)

	var action: Action = ActionAutofill.make(autofill_uid_list)
	_game_client.add_action(action)


func _on_player_requested_transmute():
	var random_pitch: float = Globals.local_rng.randf_range(1.0, 1.1)
	SFX.play_sfx(SfxPaths.PICKUP_ITEM, 0.0, random_pitch)
	
	var action: Action = ActionTransmute.make()
	_game_client.add_action(action)


func _on_player_requested_return_from_horadric_cube():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var items_in_horadric_stash: Array[Item] = horadric_stash.get_item_list()

	var src_container_uid: int = horadric_stash.get_uid()
	var dest_container_uid: int = item_stash.get_uid()

	for item in items_in_horadric_stash:
		var item_uid: int = item.get_uid()
		var action: Action = ActionMoveItem.make(item_uid, src_container_uid, dest_container_uid)
		
		_game_client.add_action(action)


func _on_builder_menu_finished():
	var builder_id: int = _builder_menu.get_builder_id()

	var action: Action = ActionSelectBuilder.make(builder_id)
	_game_client.add_action(action)


# NOTE: need to do action for wisdom upgrades after setting
# builders because some builders affect wisdom upgrades.
func _on_player_selected_builder():
	_builder_menu.queue_free()
	_builder_menu = null
	
	var wisdom_upgrades: Dictionary = Settings.get_wisdom_upgrades()
	var action: Action = ActionSelectWisdomUpgrades.make(wisdom_upgrades)
	_game_client.add_action(action)

	var wave_count: int = Globals.get_wave_count()
	var difficulty: Difficulty.enm = Globals.get_difficulty()
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var difficulty_string: String = Difficulty.convert_to_colored_string(difficulty)
	var game_mode_string: String = GameMode.convert_to_display_string(game_mode).capitalize()
	var local_player: Player = PlayerManager.get_local_player()

	Messages.add_normal(local_player, "Welcome to You TD 2!")
	Messages.add_normal(local_player, "Game settings: [color=GOLD]%d[/color] waves, [color=GOLD]%s[/color] difficulty, [color=GOLD]%s[/color] mode." % [wave_count, difficulty_string, game_mode_string])
	Messages.add_normal(local_player, "You can pause the game by pressing [color=GOLD]Esc[/color]")
	Messages.add_normal(local_player, "The first wave will spawn in 3 minutes.")
	Messages.add_normal(local_player, "You can start the first wave early by pressing on [color=GOLD]Start game[/color].")


func _on_player_voted_ready():
	var player_list: Array[Player] = PlayerManager.get_player_list()

	var not_ready_player_list: Array[Player] = []
	
	for player in player_list:
		if !player.is_ready():
			not_ready_player_list.append(player)
	
	var all_players_are_ready: bool = not_ready_player_list.is_empty()

	if all_players_are_ready:
		Messages.add_normal(null, "All players are ready, starting game.")
		_start_game()
	else:
		for player in not_ready_player_list:
			var player_name: String = player.get_player_name_with_color()
			Messages.add_normal(null, "Waiting for %s to ready up." % player_name)


func _on_player_right_clicked_autocast(autocast: Autocast):
	_toggle_autocast(autocast)


func _on_player_right_clicked_item(item: Item):
	var clicked_on_consumable: bool = item.is_consumable()
	var autocast: Autocast = item.get_autocast()
	var carrier: Unit = item.get_carrier()
	var clicked_on_item_with_autocast: bool = autocast != null && carrier != null

	if clicked_on_consumable:
		var local_player: Player = PlayerManager.get_local_player()
		var verify_ok: bool = ActionConsumeItem.verify(local_player, item)
		if !verify_ok:
			return

		var item_uid: int = item.get_uid()
		var action: Action = ActionConsumeItem.make(item_uid)
		_game_client.add_action(action)
	elif clicked_on_item_with_autocast:
		_on_player_clicked_autocast(autocast)


func _on_player_shift_right_clicked_item(item: Item):
	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		_toggle_autocast(autocast)


func _on_player_clicked_tower_buff_group(tower: Tower, buff_group: int):
	var tower_uid: int = tower.get_uid()
	var current_mode: BuffGroupMode.enm = tower.get_buff_group_mode(buff_group)
	var new_mode: BuffGroupMode.enm = wrapi(current_mode + 1, BuffGroupMode.enm.NONE, BuffGroupMode.enm.BOTH + 1) as BuffGroupMode.enm

	var local_player: Player = PlayerManager.get_local_player()
	var verify_ok: bool = ActionChangeBuffgroup.verify(local_player, tower)
	if !verify_ok:
		return
	
	var action: Action = ActionChangeBuffgroup.make(tower_uid, buff_group, new_mode)
	_game_client.add_action(action)


func _on_game_menu_quit_pressed():
	_quit_to_title()


func _on_player_requested_quit_to_title():
	_quit_to_title()


func _quit_to_title():
	_save_player_exp_on_quit()
	_cleanup_all_objects()
	OnlineMatch.leave()
	get_tree().set_pause(false)
	get_tree().change_scene_to_packed(Preloads.title_screen_scene)


func _on_tutorial_controller_tutorial_triggered(tutorial_id):
#	NOTE: ignore tutorial triggers in build mode because
#	tutorial is written for random mode and shouldn't show
#	up in build mode. Don't ignore the trigger for intro
#	because it's necessary to show it.
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var game_mode_is_build: bool = game_mode == GameMode.enm.BUILD
	if game_mode_is_build && tutorial_id != TutorialProperties.TutorialId.INTRO_FOR_BUILD_MODE:
		return
	
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	var player_mode_is_single: bool = player_mode == PlayerMode.enm.SINGLE
	if !player_mode_is_single:
		return

	var tutorial_is_enabled_in_settings: bool = Settings.get_bool_setting(Settings.SHOW_TUTORIAL_ON_START)
	if !tutorial_is_enabled_in_settings:
		return
	
	_show_tutorial(tutorial_id)


func _on_tutorial_menu_hidden():
	_set_game_paused(false)


func _on_game_client_received_first_timeslot():
	_waiting_for_players_indicator.hide()

	_builder_menu = preload("res://src/hud/builder_menu.tscn").instantiate()
	_builder_menu.finished.connect(_on_builder_menu_finished)
		
#	NOTE: add builder menu below game menu so that game
#	can show the game menu on top of tutorial
	_ui_layer.add_child(_builder_menu)
	var game_menu_index: int = _game_menu.get_index()
	_ui_layer.move_child(_builder_menu, game_menu_index)
