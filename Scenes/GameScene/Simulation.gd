class_name Simulation extends Node


# Simulation for the game ticks, synchronized with other
# players. 
# 
# Simulation ticks 30 times per second (based on
# physics_ticks_per_second config value).
# 
# Sends actions requested by local player to other players.
# Receives actions requested by other players.
# Executes actions at a delayed future tick.
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
# to Actions.

# TODO: adjust action delay dynamically based on observed
# latency. Do not adjust it constantly. A value should be
# picked once and retained for the whole game duration.
# Maybe increase it permanently if it's detected that
# current value is consistently too small. Changing this
# value too often will be disruptive to the player.

# TODO: remove print() calls or change to print_verbose()


var _tick_delta: float
var _current_tick: int = 0
var _broadcasted_actions_for_current_tick: bool = false

@export var _command_storage: CommandStorage
@export var _game_time: GameTime


#########################
###     Built-in      ###
#########################

func _ready():
	var tick_rate: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

	if tick_rate != 30:
		push_error("Physics tick rate got changed by accident. Must be 30 for multiplayer purposes.")

#	NOTE: save this delta and use it instead of the one we
#	get in _physics_process because we need all clients to
#	use the same delta value.
	_tick_delta = 1.0 / tick_rate


# NOTE: using _physics_process() because it provides a
# built-in way to do consistent tickrate, independent of
# framerate.
func _physics_process(_delta: float):
#	NOTE: need to broadcast actions from local player only
#	once per tick. Note that _physics_process() may be
#	called multiple times without advancing current tick if
#	some player is lagging.
	if !_broadcasted_actions_for_current_tick:
		_command_storage.broadcast_actions(_current_tick)
		_broadcasted_actions_for_current_tick = true

	var received_actions_from_all_players: bool = _command_storage.check_if_received_actions_from_all_players(_current_tick)

	if received_actions_from_all_players:
		_do_tick()
		_broadcasted_actions_for_current_tick = false
	else:
		print("waiting for player actions")


#########################
###      Private      ###
#########################

func _do_tick():
	_command_storage.execute_actions(_current_tick)
	_update_state()
	_current_tick += 1


# Send actions requested by local player during current
# tick to other players

func _update_state():
	_game_time.update(_tick_delta)

	var timer_list: Array = get_tree().get_nodes_in_group("manual_timers")
	for timer in timer_list:
		timer.update(_tick_delta)
	
	var creep_list: Array[Creep] = Utils.get_creep_list()
	for creep in creep_list:
		creep.update(_tick_delta)

	var projectile_list: Array = get_tree().get_nodes_in_group("projectiles")
	for projectile in projectile_list:
		projectile.update(_tick_delta)

	var tower_list: Array[Tower] = Utils.get_tower_list()
	for tower in tower_list:
		tower.update(_tick_delta)
