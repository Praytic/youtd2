class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start with "/" are treated as commands.


const READY: String = "/ready"
const START_NEXT_WAVE: String = "/startnextwave"
const ROLL_TOWERS: String = "/rolltowers"

@export var _hud: HUD


#########################
###       Public      ###
#########################

func process_chat_message(player: Player, message: String):
	match message:
		ChatCommands.READY: _command_ready(player)
		ChatCommands.START_NEXT_WAVE: _command_start_next_wave(player)
		ChatCommands.ROLL_TOWERS: _command_roll_towers(player)


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
	
	var local_player: Player = Globals.get_local_player()
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
