class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const READY: String = "/ready"
const START_NEXT_WAVE: String = "/startnextwave"
const ROLL_TOWERS: String = "/rolltowers"
const RESEARCH_ELEMENT: String = "/research"

@export var _hud: HUD


#########################
###       Public      ###
#########################

func process_command(player: Player, command: String):
	var command_split: Array = command.split(" ")
	var command_main: String = command_split[0]
	var args: Array = command_split.slice(1)

	match command_main:
		ChatCommands.READY: _command_ready(player)
		ChatCommands.START_NEXT_WAVE: _command_start_next_wave(player)
		ChatCommands.ROLL_TOWERS: _command_roll_towers(player)
		ChatCommands.RESEARCH_ELEMENT: _command_research_element(player, args)


static func verify_research_element(player: Player, element) -> bool:
	var current_level: int = player.get_element_level(element)
	var element_at_max: bool = current_level == Constants.MAX_ELEMENT_LEVEL

	if element_at_max:
		Messages.add_error(player, "Can't research element. Element is at max level.")

		return false

	var can_afford_research: bool = player.can_afford_research(element)

	if !can_afford_research:
		Messages.add_error(player, "Can't research element. You do not have enough tomes.")

		return false

	return true


static func make_action_research_element(element: Element.enm) -> Action:
	var element_string: String = Element.convert_to_string(element)
	var message: String = "%s %s" % [RESEARCH_ELEMENT, element_string]
	var action: Action = ActionChat.make(message)

	return action


#########################
###      Private      ###
#########################

func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()


# TODO: reject action if reached last level
func _command_start_next_wave(player: Player):
	var team: Team = player.get_team()
	team.start_next_wave()
	
	var local_player: Player = PlayerManager.get_local_player()
	var local_level: int = local_player.get_team().get_level()
	_hud.update_level(local_level)
	var next_waves: Array[Wave] = local_player.get_next_5_waves()
	_hud.show_wave_details(next_waves)


func _command_roll_towers(player: Player):
	var tower_stash: TowerStash = player.get_tower_stash()
	tower_stash.clear()
	
	var tower_count_for_roll: int = player.get_tower_count_for_starting_roll()
	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(player, tower_count_for_roll)
	tower_stash.add_towers(rolled_towers)
	player.decrement_tower_count_for_starting_roll()


func _command_research_element(player: Player, args: Array):
	if args.size() < 1:
		Messages.add_error(player, "Missing element argument")

		return

	var element_string: String = args[0]

	var element_is_valid: bool = Element.is_valid_string(element_string)

	if !element_is_valid:
		Messages.add_error(player, "Invalid element")

		return

	var element: Element.enm = Element.from_string(element_string)

	var command_ok: bool = ChatCommands.verify_research_element(player, element)

	if !command_ok:
		return

	var cost: int = player.get_research_cost(element)
	player.spend_tomes(cost)
	player.increment_element_level(element)
	
	var local_player: Player = PlayerManager.get_local_player()
	if player == local_player:
		var new_element_levels: Dictionary = local_player.get_element_level_map()
		_hud.update_element_level(new_element_levels)
