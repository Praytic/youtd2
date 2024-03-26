class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const READY: String = "/ready"
const PAUSE: String = "/pause"
const UNPAUSE: String = "/unpause"

@export var _team_container: TeamContainer


#########################
###       Public      ###
#########################

func process_command(player: Player, command: String):
	var command_split: Array = command.split(" ")
	var command_main: String = command_split[0]

	match command_main:
		ChatCommands.READY: _command_ready(player)
		ChatCommands.PAUSE: _command_pause(player)
		ChatCommands.UNPAUSE: _command_unpause(player)


#########################
###      Private      ###
#########################

func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()


func _command_pause(player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(true)

	Messages.add_normal(null, "Paused the waves. Unpause by typing /unpause.")


func _command_unpause(player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(false)

	Messages.add_normal(null, "Unpaused the waves.")
