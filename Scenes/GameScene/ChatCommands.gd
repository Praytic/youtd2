class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const READY: String = "/ready"


#########################
###       Public      ###
#########################

func process_command(player: Player, command: String):
	var command_split: Array = command.split(" ")
	var command_main: String = command_split[0]

	match command_main:
		ChatCommands.READY: _command_ready(player)


#########################
###      Private      ###
#########################

func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()
