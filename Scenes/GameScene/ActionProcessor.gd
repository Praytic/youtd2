class_name ActionProcessor extends Node


# Contains functions which processes actions. Used by Simulation.


@export var _player_container: PlayerContainer
@export var _hud: HUD
@export var _map: Map
@export var _game_start_timer: ManualTimer
@export var _next_wave_timer: ManualTimer
@export var _extreme_timer: ManualTimer
@export var _wave_spawner: WaveSpawner
@export var _game_time: GameTime


func process_action(player_id: int, serialized_action: Dictionary):
	var action: Action = Action.new(serialized_action)
	
	var action_type: Action.Type = action.type

	match action_type:
		Action.Type.IDLE: return
		Action.Type.RESEARCH_ELEMENT: _research_element(player_id, serialized_action)
		Action.Type.ROLL_TOWERS: _roll_towers(player_id)
		Action.Type.BUILD_TOWER: _build_tower(player_id, serialized_action)
		Action.Type.SELL_TOWER: _sell_tower(serialized_action)
		Action.Type.START_GAME: _start_game()
		Action.Type.START_NEXT_WAVE: start_next_wave(player_id)
		Action.Type.SELECT_BUILDER: _select_builder(player_id, serialized_action)


#########################
###       Public      ###
#########################

func _research_element(player_id: int, serialized_action: Dictionary):
	var action: ActionResearchElement = ActionResearchElement.new(serialized_action)
	var element: Element.enm = action.element

	var local_player: Player = _player_container.get_local_player()
	var player: Player = _player_container.get_player(player_id)

	var cost: int = player.get_research_cost(element)
	player.spend_tomes(cost)
	player.increment_element_level(element)

	if player == local_player:
		var new_element_levels: Dictionary = local_player.get_element_level_map()
		_hud.update_element_level(new_element_levels)


func _roll_towers(player_id: int):
	var player: Player = _player_container.get_player(player_id)
	var tower_stash: TowerStash = player.get_tower_stash()
	tower_stash.clear()
	
	var tower_count_for_roll: int = player.get_tower_count_for_starting_roll()
	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(player, tower_count_for_roll)
	tower_stash.add_towers(rolled_towers)
	player.decrement_tower_count_for_starting_roll()


# TODO: build tower action looks very bad with the delay.
# Need to add a temporary animation like a cloud of dust,
# while the tower "builds".
func _build_tower(player_id: int, serialized_action: Dictionary):
	var action: ActionBuildTower = ActionBuildTower.new(serialized_action)
	var tower_id: int = action.tower_id
	var position: Vector2 = action.position

	var player: Player = _player_container.get_player(player_id)

	player.add_food_for_tower(tower_id)
	
	var build_cost: float = TowerProperties.get_cost(tower_id)
	player.spend_gold(build_cost)
	
	var tomes_cost: int = TowerProperties.get_tome_cost(tower_id)
	player.spend_tomes(tomes_cost)

	if Globals.get_game_mode() != GameMode.enm.BUILD:
		var tower_stash: TowerStash = player.get_tower_stash()
		tower_stash.remove_tower(tower_id)

	var new_tower: Tower = TowerManager.get_tower(tower_id, player)
	new_tower.position = position
	
	_map.add_space_occupied_by_tower(new_tower)

	Utils.add_object_to_world(new_tower)


func _sell_tower(serialized_action: Dictionary):
	var action: ActionSellTower = ActionSellTower.new(serialized_action)
	var tower_unit_id: int = action.tower_unit_id

	var tower: Tower = _get_tower_by_uid(tower_unit_id)

	if tower == null:
		push_error("Sell tower action failed")

		return

# 	Return tower items to item stash
	var item_list: Array[Item] = tower.get_items()

	for item in item_list:
		item.drop()
		item.fly_to_stash(0.0)

	var tower_id: int = tower.get_id()
	var sell_price: int = TowerProperties.get_sell_price(tower_id)
	var player: Player = tower.get_player()
	player.give_gold(sell_price, tower, false, true)
	player.remove_food_for_tower(tower_id)

	_map.clear_space_occupied_by_tower(tower)

	tower.remove_from_game()


# TODO: start game only for one team
func _start_game():
	_game_start_timer.stop()
	_hud.hide_game_start_time()
	_hud.show_next_wave_button()
	_hud.hide_roll_towers_button()

	_wave_spawner.start_wave(1)
	
	if Globals.get_difficulty() == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)

#	NOTE: start counting game time after first wave starts
	_game_time.set_enabled(true)


# TODO: start next wave only for one team
func start_next_wave(player_id: int):
	_extreme_timer.stop()
	_next_wave_timer.stop()
	
	var player: Player = _player_container.get_player(player_id)
	var team: Team = player.get_team()

	team.increment_level()

	var level: int = team.get_level()

	_wave_spawner.start_wave(level)

	_hud.hide_next_wave_time()
	_hud.update_level(level)
	var next_waves: Array[Wave] = _get_next_5_waves()
	_hud.show_wave_details(next_waves)
	var started_last_wave: bool = level == Globals.get_wave_count()
	if started_last_wave:
		_hud.disable_next_wave_button()

	if !started_last_wave && Globals.get_difficulty() == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)


func _select_builder(player_id: int, serialized_action: Dictionary):
	var action: ActionSelectBuilder = ActionSelectBuilder.new(serialized_action)
	var builder_id: int = action.builder_id

	var player: Player = _player_container.get_player(player_id)
	
	if player == null:
		push_error("player is null")
		
		return
	
	player.set_builder(builder_id)

	var local_player: Player = _player_container.get_local_player()

	if player == local_player:
		var local_builder: Builder = local_player.get_builder()
		var local_builder_name: String = local_builder.get_display_name()
		_hud.set_local_builder_name(local_builder_name)

		if local_builder.get_adds_extra_recipes():
			_hud.enable_extra_recipes()


func _get_tower_by_uid(tower_unit_id: int) -> Tower:
	var tower_list: Array[Tower] = Utils.get_tower_list()

	for tower in tower_list:
		if tower.get_uid() == tower_unit_id:
			return tower

	push_error("Failled to find tower with uid: ", tower_unit_id)

	return null


# TODO: fix duplication of this function here and in GameScene.gd
func _get_next_5_waves() -> Array[Wave]:
	var wave_list: Array[Wave] = []
	var local_player: Player = _player_container.get_local_player()
	var current_level: int = local_player.get_team().get_level()
	
	for level in range(current_level, current_level + 6):
		var wave: Wave = _wave_spawner.get_wave(level)
		
		if wave != null:
			wave_list.append(wave)

	return wave_list
