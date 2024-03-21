class_name ActionStorage extends Node


# Stores actions to be executed in the future, for the
# purposes of multiplayer. Actions can come both from local
# player as well as other clients via RPC.


# NOTE: 6 ticks at 30ticks/second = 200ms.
# This amount needs to be big enough to account for latency.
const MULTIPLAYER_ACTION_DELAY: int = 6
const SINGLEPLAYER_ACTION_DELAY: int = 1


# This variable stores the action which was requested by
# local player during current tick.
var _local_action_for_current_tick: Action = null
# A map of {tick => {player_id => action}}
# Extends into the future, ticks older than current are
# cleaned up.
var _action_map: Dictionary = {}
var _action_delay: int = MULTIPLAYER_ACTION_DELAY


@export var _player_container: PlayerContainer
@export var _action_processor: ActionProcessor



#########################
###       Public      ###
#########################

func set_delay(delay: int):
	_action_delay = delay


# Adds an action for local player for current tick. This
# action will be broadcasted to other players and executed
# at some future tick. Note that only one action is allowed
# per tick. Any extra actions are discarded.
func add_action(action: Action):
	if _local_action_for_current_tick != null:
		return

	_local_action_for_current_tick = action


func broadcast_actions(tick: int):
#	If player didn't request a action during this tick,
#	broadcast an "idle action" to let other players know
#	that we're still connected. If other players arrive at
#	execution frame without an idle action from us, they
#	will wait for us to catch up.
	if _local_action_for_current_tick == null:
		var idle_action: Action = ActionIdle.make()
		add_action(idle_action)

	var execute_tick: int = tick + _action_delay

	var serialized_action: Dictionary = _local_action_for_current_tick.serialize()
	_save_action.rpc(execute_tick, serialized_action)
	_local_action_for_current_tick = null


func execute_actions(tick: int):
#	NOTE: skip executing actions at the start because
#	during the initial delay period, there are no actions
#	from players, not even idle.
	if tick <= _action_delay:
		return
		
	var actions_for_current_tick: Dictionary = _action_map[tick]

	var player_id_list: Array[int] = _player_container.get_player_id_list()
	for player_id in player_id_list:
		var serialized_action: Dictionary = actions_for_current_tick[player_id]
		_action_processor.execute(player_id, serialized_action)

	_action_map.erase(tick)


func check_if_received_actions_from_all_players(tick: int) -> bool:
#	NOTE: at the start of the game, we do not have a history
#	of old actions to process, so do not process actions
#	until we get to point where we have actions from other
#	players.
	if tick <= _action_delay:
		return true
	
	var actions_for_current_tick: Dictionary = _action_map[tick]
	
	var received_actions_from_all_players: bool = true
	var player_id_list: Array[int] = _player_container.get_player_id_list()
	for player_id in player_id_list:
		if !actions_for_current_tick.has(player_id):
			print("no actions from player %d" % player_id)
			received_actions_from_all_players = false
	
	return received_actions_from_all_players


#########################
###      Private      ###
#########################

@rpc("any_peer", "call_local", "reliable")
func _save_action(execute_tick: int, action: Dictionary):
	if !_action_map.has(execute_tick):
		_action_map[execute_tick] = {}
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
#	NOTE: if we receive more than one action from a player for same tick, then we consider 
#	the sender to be misbehaving. Ignore such broadcasts.
	var player_already_has_action_for_tick: bool = _action_map[execute_tick].has(player_id)
	if player_already_has_action_for_tick:
		return

	_action_map[execute_tick][player_id] = action
