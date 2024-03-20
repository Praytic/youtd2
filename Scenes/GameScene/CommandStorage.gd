class_name CommandStorage extends Node


# Stores commands to be executed in the future, for the
# purposes of multiplayer. Commands can come both from local
# player as well as other clients via RPC.


# NOTE: 6 ticks at 30ticks/second = 200ms.
# This amount needs to be big enough to account for latency.
const MULTIPLAYER_COMMAND_DELAY: int = 6
const SINGLEPLAYER_COMMAND_DELAY: int = 1


# List of commands requested by local player during current
# tick.
var _commands_for_current_tick: Array = []
# A map of [tick => [player_id => [list of commands]]]
# Extends into the future, ticks older than current are
# cleaned up.
var _all_commands: Dictionary = {}
var _command_delay: int = MULTIPLAYER_COMMAND_DELAY


@export var _player_container: PlayerContainer
@export var _execute_command: ExecuteCommand



#########################
###       Public      ###
#########################

func set_delay(delay: int):
	_command_delay = delay


# Adds a command for local player for current tick. This
# command will be broadcasted to other players and executed
# at some future tick.
func add_command(command: Command):
	var serialized_command: Dictionary = command.serialize()
	_commands_for_current_tick.append(serialized_command)


func broadcast_commands(tick: int):
#	If player didn't request any commands during this tick,
#	broadcast an "idle command" to let other players know
#	that we're still connected. If other players arrive at
#	execution frame without an idle command from us, they
#	will wait for us to catch up.
	if _commands_for_current_tick.is_empty():
		var idle_command: Command = CommandIdle.make()
		add_command(idle_command)
	
	var execute_tick: int = tick + _command_delay

#	NOTE: need to duplicate array because in case of self
#	rpc call, we want to save a copy, not a reference.
#	Reference is cleared at the end of this function.
	var commands_to_broadcast: Array = _commands_for_current_tick.duplicate()
	_receive_broadcasted_commands.rpc(execute_tick, commands_to_broadcast)
	_commands_for_current_tick.clear()


func execute_commands(tick: int):
#	NOTE: skip executing commands at the start because
#	during the initial delay period, there are no commands
#	from players, not even idle.
	if tick <= _command_delay:
		return
		
	var commands_for_current_tick: Dictionary = _all_commands[tick]

	var player_id_list: Array[int] = _player_container.get_player_id_list()
	for player_id in player_id_list:
		var player_commands: Array = commands_for_current_tick[player_id]
		
		for command in player_commands:
			_execute_command.execute(player_id, command)

	_all_commands.erase(tick)


func check_if_received_commands_from_all_players(tick: int) -> bool:
#	NOTE: at the start of the game, we do not have a history
#	of old commands to process, so do not process commands
#	until we get to point where we have commands from other
#	players.
	if tick <= _command_delay:
		return true
	
	var commands_for_current_tick: Dictionary = _all_commands[tick]
	
	var received_commands_from_all_players: bool = true
	var player_id_list: Array[int] = _player_container.get_player_id_list()
	for player_id in player_id_list:
		if !commands_for_current_tick.has(player_id):
			print("no commands from player %d" % player_id)
			received_commands_from_all_players = false
	
	return received_commands_from_all_players


#########################
###      Private      ###
#########################

@rpc("any_peer", "call_local", "reliable")
func _receive_broadcasted_commands(execute_tick: int, command_list: Array):
	if !_all_commands.has(execute_tick):
		_all_commands[execute_tick] = {}

	var player_id: int = multiplayer.get_remote_sender_id()

	_all_commands[execute_tick][player_id] = command_list
