class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start with "/" are treated as commands.


const READY: String = "/ready"
const START_NEXT_WAVE: String = "/startnextwave"

@export var _hud: HUD


func process_chat_message(player: Player, message: String):
	match message:
		ChatCommands.READY: _command_ready(player)
		ChatCommands.START_NEXT_WAVE: _command_start_next_wave(player)


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
