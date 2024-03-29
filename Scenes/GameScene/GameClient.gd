class_name GameClient extends Node


# GameClient for the game ticks, synchronized with the
# server.
# 
# GameClient ticks 30 times per second (based on
# physics_ticks_per_second config value).
# 
# Peers send actions requested by local player to host.
# Host combines all actions into timeslots and sends
# timeslots to all peers.
# 
# Stops ticking if a timeslot is not ready for current tick.
# 
# The end result is that clients are synchronized.


const MAX_TICKS_PER_PROCESS: int = 10

var _tick_delta: float
var _current_tick: int = 0
var _received_latency: int = 0

# A map of timeslots. Need to keep a map in case we receive
# future timeslots before we processed current one.
# {tick -> timeslot}
var _timeslot_map: Dictionary = {}
var _timeslot_tick_queue: Array = [0]


@export var _game_host: GameHost
@export var _game_time: GameTime
@export var _hud: HUD
@export var _map: Map
@export var _chat_commands: ChatCommands


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
#	NOTE: depending on _should_tick() return value, client
#	may tick 0, 1 or multiple times.
	var ticks_during_this_process: int = 0
	while _should_tick(ticks_during_this_process):
		_do_tick()
		ticks_during_this_process += 1


#########################
###       Public      ###
#########################

# Send action from client to host
func add_action(action: Action):
	var serialized_action: Dictionary = action.serialize()
	_game_host.receive_action.rpc_id(1, serialized_action)


# Receive timeslot sent by host to this client
@rpc("authority", "call_local", "reliable")
func receive_timeslot(timeslot: Array, latency: int):
	var tick_for_this_timeslot: int = _timeslot_tick_queue.back()
	_timeslot_map[tick_for_this_timeslot] = timeslot
	var tick_for_next_timeslot: int = tick_for_this_timeslot + latency
	_timeslot_tick_queue.append(tick_for_next_timeslot)
	_received_latency = latency


#########################
###      Private      ###
#########################

func _should_tick(ticks_during_this_process: int) -> bool:
# 	NOTE: need to limit ticks per process to not disrupt
# 	timing of _physics_process() too much
	var too_many_ticks: bool = ticks_during_this_process > MAX_TICKS_PER_PROCESS
	if too_many_ticks:
		return false
	
#	If current tick needs a timeslot and client hasn't
#	received timeslot from host yet, client has to wait
	var timeslot_tick: int = _timeslot_tick_queue.front()
	var need_timeslot: bool = _current_tick == timeslot_tick
	var have_timeslot: bool = _timeslot_map.has(timeslot_tick)
	if need_timeslot && !have_timeslot:
		return false
	
#	If client tick is behind host tick, catch up by fast
#	forwarding
	var latest_timeslot_tick: int = _timeslot_tick_queue.back()
	var need_to_fast_forward: bool = latest_timeslot_tick - _current_tick > _received_latency
	if need_to_fast_forward:
		return true

#	Tick once per process if don't need to fast forward
	var is_first_tick_during_process: bool = ticks_during_this_process == 0

	return is_first_tick_during_process


func _do_tick():
	var timeslot_tick: int = _timeslot_tick_queue.front()
	var need_timeslot: bool = _current_tick == timeslot_tick
	var have_timeslot: bool = _timeslot_map.has(timeslot_tick)
	
	if need_timeslot && !have_timeslot:
		return

	if need_timeslot:
		var timeslot: Array = _timeslot_map[timeslot_tick]
		_timeslot_map.erase(timeslot_tick)
		_timeslot_tick_queue.pop_front()

#		Tell host that this client has processed this
#		timeslot. Send checksum to check for desyncs.
		var checksum: PackedByteArray = _calculate_game_state_checksum()
		_game_host.receive_timeslot_ack.rpc_id(1, checksum)

		for action in timeslot:
			_execute_action(action)
	
	_update_state()
	_current_tick += 1


func _calculate_game_state_checksum():
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)

	var game_state: PackedByteArray = PackedByteArray()

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for player in player_list:
		var total_damage: int = floori(player.get_total_damage())
		var gold_farmed: int = floori(player.get_gold_farmed())
		var gold: int = floori(player.get_gold())
		var tomes: int = player.get_tomes()
		var lives: int = floori(player.get_team().get_lives_percent())
		var level: int = player.get_team().get_level()

		game_state.append(total_damage)
		game_state.append(gold_farmed)
		game_state.append(gold)
		game_state.append(tomes)
		game_state.append(lives)
		game_state.append(level)

	ctx.update(game_state)

	var checksum: PackedByteArray = ctx.finish()

	return checksum


func _execute_action(action: Dictionary):
	var player_id: int = action[Action.Field.PLAYER_ID]
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
		Action.Type.SELECT_BUILDER: ActionSelectBuilder.execute(action, player)
		Action.Type.TOGGLE_AUTOCAST: ActionToggleAutocast.execute(action, player)
		Action.Type.CONSUME_ITEM: ActionConsumeItem.execute(action, player)
		Action.Type.DROP_ITEM: ActionDropItem.execute(action, player)
		Action.Type.MOVE_ITEM: ActionMoveItem.execute(action, player)
		Action.Type.AUTOFILL: ActionAutofill.execute(action, player)
		Action.Type.TRANSMUTE: ActionTransmute.execute(action, player)
		Action.Type.RESEARCH_ELEMENT: ActionResearchElement.execute(action, player)
		Action.Type.ROLL_TOWERS: ActionRollTowers.execute(action, player)
		Action.Type.START_NEXT_WAVE: ActionStartNextWave.execute(action, player)
		Action.Type.AUTOCAST: ActionAutocast.execute(action, player)
		Action.Type.FOCUS_TARGET: ActionFocusTarget.execute(action, player)
		Action.Type.CHANGE_BUFFGROUP: ActionChangeBuffgroup.execute(action, player)


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
