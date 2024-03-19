class_name Simulation extends Node


# Simulation for the game ticks, synchronized with other
# players. 
# 
# Simulation ticks 30 times per second (based on
# physics_ticks_per_second config value).
# 
# Sends commands requested by local player to other players.
# Receives commands requested by other players.
# Executes commands at a delayed future tick.
# 
# Stops ticking if it detects that some player has
# disconnected or is lagging.
# 
# The end result is that simulations for all players are
# synchronized.


# TODO: process all timers here. Buff periodic timers, tower
# attack timers, unit regen timers, "await" timers called in
# tower scripts.

# TODO: convert all player inputs which affect world state
# to Commands.

# TODO: adjust command delay dynamically based on observed
# latency. Do not adjust it constantly. A value should be
# picked once and retained for the whole game duration.
# Maybe increase it permanently if it's detected that
# current value is consistently too small. Changing this
# value too often will be disruptive to the player.

# TODO: remove print() calls or change to print_verbose()


var _current_tick: int = 0
var _broadcasted_commands_for_current_tick: bool = false

@export var _command_storage: CommandStorage


#########################
###     Built-in      ###
#########################

# NOTE: using _physics_process() because it provides a
# built-in way to do consistent tickrate, independent of
# framerate.
func _physics_process(_delta: float):
#	NOTE: need to broadcast commands from local player only
#	once per tick. Note that _physics_process() may be
#	called multiple times without advancing current tick if
#	some player is lagging.
	if !_broadcasted_commands_for_current_tick:
		_command_storage.broadcast_commands(_current_tick)
		_broadcasted_commands_for_current_tick = true

	var received_commands_from_all_players: bool = _command_storage.check_if_received_commands_from_all_players(_current_tick)

	if received_commands_from_all_players:
		_do_tick()
		_broadcasted_commands_for_current_tick = false
	else:
		print("waiting for player commands")


#########################
###      Private      ###
#########################

func _do_tick():
	_command_storage.execute_commands(_current_tick)
	_update_state()
	_current_tick += 1


# Send commands requested by local player during current
# tick to other players

func _update_state():
	pass
