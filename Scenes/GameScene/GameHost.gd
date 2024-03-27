class_name GameHost extends Node


# Host receives actions from peers, combines them into
# "timeslots" and sends timeslots back to the peers. A
# "timeslot" is a group of actions for a given tick. A host
# has it's own tick, independent of the Simulation on the
# host's client. Host sends timeslots periodically with an
# interval equal to current "latency" value.
# 
# Note that server peer acts as a host and a peer at the
# same time.

# NOTE: GameHost node needs to be positioned before
# Simulation node in the tree, so that it is processed
# first.


# MULTIPLAYER_ACTION_LATENCY needs to be big enough to
# account for latency.
# NOTE: 6 ticks at 30ticks/second = 200ms.
const MULTIPLAYER_ACTION_LATENCY: int = 6
const SINGLEPLAYER_ACTION_LATENCY: int = 1
# MAX_LAG_AMOUNT is the max difference in timeslots between
# host and client. A client is considered to be lagging if
# it falls behind by more timeslots than this value.
const MAX_LAG_AMOUNT: int = 50

@export var _simulation: Simulation


var _setup_done: bool = false
var _current_tick: int = 0
var _current_latency: int = -1
var _in_progress_timeslot: Array = []
var _last_sent_timeslot_tick: int = 0


#########################
###     Built-in      ###
#########################

func _physics_process(_delta: float):
	if !multiplayer.is_server():
		return

	_current_tick += 1

	var need_to_send_timeslot: bool = _current_tick - _last_sent_timeslot_tick == _current_latency

	if need_to_send_timeslot:
		_send_timeslot()


#########################
###       Public      ###
#########################

func setup(latency: int):
	if _setup_done:
		push_error("GameHost.setup() was called multiple times.")

		return

	_current_latency = latency

#	Send timeslot for 0 tick
	_send_timeslot()

	_setup_done = true


# Receive action sent from client to host. Actions are
# compiled into timeslots - a group of actions from all
# clients.
@rpc("any_peer", "call_local", "reliable")
func receive_action(action: Dictionary):
#	NOTE: need to attach player id to action in this host
#	function to ensure safety. If we were to let clients
#	attach player_id to actions, then clients could attach
#	any value.
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = PlayerManager.get_player_by_peer_id(peer_id)
	var player_id: int = player.get_id()
	action[Action.Field.PLAYER_ID] = player_id

	_in_progress_timeslot.append(action)


#########################
###      Private      ###
#########################

func _send_timeslot():
	var timeslot: Array = _in_progress_timeslot.duplicate()
	_in_progress_timeslot.clear()
	_simulation.receive_timeslot.rpc(timeslot, _current_latency)
	_last_sent_timeslot_tick = _current_tick
