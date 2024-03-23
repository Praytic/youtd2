class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start with "/" are treated as commands.


const READY: String = "/ready"



func process_chat_message(player: Player, message: String):
	match message:
		ChatCommands.READY: _command_ready(player)


func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()
