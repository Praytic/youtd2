class_name GameHost extends Node


# Host receives actions from peers, combines them into
# "timeslots" and sends timeslots back to the peers. A
# "timeslot" is a group of actions for a given tick.
# 
# Note that server peer acts as a host and a peer at the
# same time.


@export var _simulation: Simulation

# Map of timeslots, which will be sent to peers. This data
# is discarded after being sent.
# {tick -> timeslot}
# timeslot = {player_id -> serialized action}
var _timeslot_map: Dictionary = {}


#########################
###       Public      ###
#########################

@rpc("any_peer", "call_local", "reliable")
func save_action(tick: int, player_id: int, serialized_action: Dictionary):
	if !_timeslot_map.has(tick):
		_timeslot_map[tick] = {}
	
#	NOTE: it's possible to receive an action broadcast
#	multiple times for same tick if the network is waiting
#	for the lagging player. In such cases, keep the first
#	broadcast and ignore duplicates.
	var player_already_has_action_for_tick: bool = _timeslot_map[tick].has(player_id)
	if player_already_has_action_for_tick:
		return

	_timeslot_map[tick][player_id] = serialized_action
	
	var player_list: Array[Player] = Globals.get_player_list()
	var player_count: int = player_list.size()
	var timeslot_has_actions_for_all_players: bool = _timeslot_map[tick].size() == player_count
	
	if timeslot_has_actions_for_all_players:
		var timeslot: Dictionary = _timeslot_map[tick].duplicate()
		_simulation.save_timeslot.rpc(tick, timeslot)
		_timeslot_map.erase(tick)
