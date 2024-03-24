class_name Simulation extends Node


# Simulation for the game ticks, synchronized with other
# players. 
# 
# Simulation ticks 30 times per second (based on
# physics_ticks_per_second config value).
# 
# Peers send actions requested by local player to host.
# Host combines all actions into timeslots and sends
# timeslots to all peers.
# 
# Stops ticking if a timeslot is not ready for current tick.
# 
# The end result is that simulations for all players are
# synchronized.


# TODO: process all timers here. Buff periodic timers, tower
# attack timers, unit regen timers, "await" timers called in
# tower scripts.

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
var _action_delay: int
var _sent_action_for_current_tick: bool = false

# Map of timeslots which were received from host. This data
# is discarded after being processed.
# {tick -> timeslot}
# timeslot = {player_id -> serialized action}
var _timeslot_map: Dictionary = {}


@export var _game_host: GameHost
@export var _game_time: GameTime
@export var _hud: HUD
@export var _map: Map
@export var _chat_commands: ChatCommands


#########################
###     Built-in      ###
#########################

func _ready():
	set_delay(MULTIPLAYER_ACTION_DELAY)
	
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
	var process_tick: int = _current_tick + _action_delay
	var local_player: Player = PlayerManager.get_local_player()
	var local_player_id: int = local_player.get_id()
	var serialized_action: Dictionary = action.serialize()
	_game_host.save_action.rpc_id(1, process_tick, local_player_id, serialized_action)

	_sent_action_for_current_tick = true


func set_delay(delay: int):
	_action_delay = delay

# 	Add dummy timeslots for initial ticks before the action
# 	delay is reached. Need to do this to have valid data before real
# 	actions from players start getting scheduled.
	_timeslot_map.clear()
	
	for tick in range(0, delay):
		_timeslot_map[tick] = {}


@rpc("authority", "call_local", "reliable")
func save_timeslot(tick: int, timeslot: Dictionary):
	_timeslot_map[tick] = timeslot


#########################
###      Private      ###
#########################

func _do_tick():
#	NOTE: if local player didn't do any action for current tick, send an idle action to the server for synchronization purposes.
	if !_sent_action_for_current_tick:
		var idle_action: Action = ActionIdle.make()
		add_action(idle_action)
	
	var timeslot_is_ready: bool = _timeslot_map.has(_current_tick)

	if !timeslot_is_ready:
		print("waiting for player actions")

		return

	var timeslot: Dictionary = _timeslot_map[_current_tick]

	_process_actions(timeslot)
	_update_state()
	_sent_action_for_current_tick = false
	_timeslot_map.erase(_current_tick)

	_current_tick += 1


func _process_actions(timeslot: Dictionary):
	var player_id_list: Array = timeslot.keys()
	
#	NOTE: need to sort id list to ensure determinism
	player_id_list.sort()
	
	for player_id in player_id_list:
		var action: Dictionary = timeslot[player_id]
		_process_action(player_id, action)


func _process_action(player_id: int, action: Dictionary):
	var player: Player = PlayerManager.get_player(player_id)

	if player == null:
		push_error("player is null")
		
		return

	var action_type: Action.Type = action[Action.Field.TYPE]

	match action_type:
		Action.Type.IDLE: return
		Action.Type.CHAT: ActionChat.execute(action, player, _hud, _chat_commands)
		Action.Type.BUILD_TOWER: ActionBuildTower.execute(action, player, _map)
		Action.Type.TRANSFORM_TOWER: ActionTransformTower.execute(action, player, _map)
		Action.Type.SELL_TOWER: ActionSellTower.execute(action, player, _map)
		Action.Type.SELECT_BUILDER: ActionSelectBuilder.execute(action, player, _hud)
		Action.Type.TOGGLE_AUTOCAST: ActionToggleAutocast.execute(action, player)
		Action.Type.CONSUME_ITEM: ActionConsumeItem.execute(action, player)
		Action.Type.DROP_ITEM: ActionDropItem.execute(action, player)
		Action.Type.MOVE_ITEM: ActionMoveItem.execute(action, player)
		Action.Type.AUTOFILL: ActionAutofill.execute(action, player)
		Action.Type.TRANSMUTE: ActionTransmute.execute(action, player)
		Action.Type.RESEARCH_ELEMENT: ActionResearchElement.execute(action, player, _hud)
		Action.Type.ROLL_TOWERS: ActionRollTowers.execute(action, player)
		Action.Type.START_NEXT_WAVE: ActionStartNextWave.execute(action, player, _hud)
		Action.Type.AUTOCAST: ActionAutocast.execute(action, player)
		Action.Type.FOCUS_TARGET: ActionFocusTarget.execute(action, player)


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
