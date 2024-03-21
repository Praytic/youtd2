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


# NOTE: 6 ticks at 30ticks/second = 200ms.
# This amount needs to be big enough to account for latency.
const MULTIPLAYER_ACTION_DELAY: int = 6
const SINGLEPLAYER_ACTION_DELAY: int = 1


var _tick_delta: float
var _current_tick: int = 0
var _action_delay: int = MULTIPLAYER_ACTION_DELAY
var _action_storage: ActionStorage

@export var _game_time: GameTime
@export var _action_processor: ActionProcessor
@export var _player_container: PlayerContainer


#########################
###     Built-in      ###
#########################

func _ready():
	_action_storage = ActionStorage.new()
	add_child(_action_storage)
	
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
	_do_tick()


#########################
###       Public      ###
#########################

func add_action(action: Action):
	_action_storage.add_action(action)


func set_delay(delay: int):
	_action_delay = delay


#########################
###      Private      ###
#########################

func _do_tick():
#	NOTE: continue broadcasting actions even if the tick is
#	not advancing. The tick stops advancing if some player
#	lags or disconnects so we need to keep broadcasting to
#	ensure that players receive our actions when they
#	reconnect.
	var tick_for_broadcast: int = _current_tick + _action_delay
	_action_storage.broadcast_local_action(tick_for_broadcast)

	var received_actions_from_all_players: bool = check_if_received_actions_from_all_players()

	if !received_actions_from_all_players:
		print("waiting for player actions")

		return

	_process_actions()
	_update_state()
	_current_tick += 1


func _process_actions():
#	NOTE: skip process actions at the start because
#	during the initial delay period, there are no actions
#	from players, not even idle.
	if _current_tick <= _action_delay:
		return
	
	var actions_for_current_tick: Dictionary = _action_storage.get_actions(_current_tick)

	var player_list: Array[Player] = _player_container.get_player_list()
	for player in player_list:
		var player_id: int = player.get_id()
		var serialized_action: Dictionary = actions_for_current_tick[player_id]
		_action_processor.process_action(player_id, serialized_action)

	_action_storage.clear_actions_for_tick(_current_tick)


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


func check_if_received_actions_from_all_players() -> bool:
#	NOTE: need to skip checking for actions during the first
#	ticks when the game just started. During this period,
#	players could not have sent actions because of the
#	action delay.
	if _current_tick <= _action_delay:
		return true
	
	var actions_for_current_tick: Dictionary = _action_storage.get_actions(_current_tick)
	
	var received_actions_from_all_players: bool = true
	var player_list: Array[Player] = _player_container.get_player_list()
	for player in player_list:
		var player_id: int = player.get_id()
		
		if !actions_for_current_tick.has(player_id):
			print("no actions from player %d" % player_id)
			received_actions_from_all_players = false
	
	return received_actions_from_all_players
