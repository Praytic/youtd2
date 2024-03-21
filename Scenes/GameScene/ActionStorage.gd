class_name ActionStorage extends Node


# Stores actions to be processed in the future, for the
# purposes of multiplayer. Actions can come both from local
# player as well as other clients via RPC.


# This variable stores the action which was requested by
# local player during current tick.
var _local_action_for_current_tick: Action = null
# A map of {tick => {player_id => action}}
# Extends into the future, ticks older than current are
# cleaned up.
var _action_map: Dictionary = {}


#########################
###       Public      ###
#########################

# Adds an action for local player for current tick. This
# action will be broadcasted to other players and processed
# at some future tick. Note that only one action is allowed
# per tick. Any extra actions are discarded.
func add_action(action: Action):
	if _local_action_for_current_tick != null:
		return

	_local_action_for_current_tick = action


func get_actions(tick: int) -> Dictionary:
	var actions: Dictionary = _action_map[tick]
	
	return actions


func clear_actions_for_tick(tick: int):
	_action_map.erase(tick)


func broadcast_local_action(tick: int):
#	NOTE: broadcast an "idle action to let other players
#	know that we're still connected. If other players reach
#	a tick where they didn't receive an action from us, they
#	will wait for us to catch up.
	if _local_action_for_current_tick == null:
		var idle_action: Action = ActionIdle.make()
		add_action(idle_action)

	var serialized_action: Dictionary = _local_action_for_current_tick.serialize()
	_save_action.rpc(tick, serialized_action)
	_local_action_for_current_tick = null


#########################
###      Private      ###
#########################

@rpc("any_peer", "call_local", "reliable")
func _save_action(tick: int, action: Dictionary):
	if !_action_map.has(tick):
		_action_map[tick] = {}
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
#	NOTE: it's possible to receive an action broadcast
#	multiple times for same tick if the network is waiting
#	for the lagging player. In such cases, keep the first
#	broadcast and ignore duplicates.
	var player_already_has_action_for_tick: bool = _action_map[tick].has(player_id)
	if player_already_has_action_for_tick:
		return

	_action_map[tick][player_id] = action
