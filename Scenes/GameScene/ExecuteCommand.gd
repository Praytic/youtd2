class_name ExecuteCommand extends Node


# Contains functions which execute Commands. Used by Simulation.


@export var _player_container: PlayerContainer
@export var _hud: HUD


func execute(player_id: int, serialized_command: Dictionary):
	var command: Command = Command.new(serialized_command)
	
	var command_type: Command.Type = command.type

	match command_type:
		Command.Type.IDLE: return
		Command.Type.RESEARCH_ELEMENT: _research_element(player_id, serialized_command)
		Command.Type.ROLL_TOWERS: _roll_towers(player_id)


#########################
###       Public      ###
#########################

func _research_element(player_id: int, serialized_command: Dictionary):
	var command: Command.ResearchElement = Command.ResearchElement.new(serialized_command)
	var element: Element.enm = command.element

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
