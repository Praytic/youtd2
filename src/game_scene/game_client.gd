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


signal received_first_timeslot()


# NOTE: this value determines how fast timeslot buffer
# lowers when ping decreases. Higher value = faster
# lowering.
const TIMESLOT_BUFFER_SIZE_LOWERING_FACTOR: float = 0.4
const PING_HISTORY_SIZE: int = 10
const CHECKSUM_PERIOD_TICKS: int = 30 * GameHost.MULTIPLAYER_TURN_LENGTH


var _tick_delta: float
var _current_tick: int = 0
var _turn_length: int
# Timeslot buffer determines how many timeslots to keep in
# buffer. Turns are buffered to avoid getting into
# situations where client runs out of timeslots and has to
# stall until next one arrives.
var _timeslot_buffer_size: float

# A map of timeslots. Need to keep a map in case we receive
# future timeslots before we processed current one.
# {tick -> timeslot}
var _timeslot_map: Dictionary = {}
var _time_when_sent_ping: int = 0
var _ping_history: Array = [0]
var _received_any_timeslots: bool = false


@export var _game_host: GameHost
@export var _game_time: GameTime
@export var _hud: HUD
@export var _build_space: BuildSpace
@export var _chat_commands: ChatCommands
@export var _select_unit: SelectUnit


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

	_turn_length = Utils.get_turn_length()
	_timeslot_buffer_size = _turn_length


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


@rpc("authority", "call_local", "reliable")
func receive_alive_check():
	_game_host.receive_alive_check_response.rpc_id(1)


# Receive timeslot sent by host to this client and receive
# turn length
# 
# NOTE: this f-n needs to handle cases where timeslots
# are received out of order.
@rpc("authority", "call_local", "reliable")
func receive_timeslots(timeslot_list: Dictionary):
	if !_received_any_timeslots:
		_received_any_timeslots = true
		received_first_timeslot.emit()
	
	for tick in timeslot_list.keys():
		_timeslot_map[tick] = timeslot_list[tick]

	var tick_list: Array = timeslot_list.keys()
	_game_host.receive_timeslots_ack.rpc_id(1, tick_list)


@rpc("authority", "call_local", "reliable")
func receive_pong():
	var time_when_received_pong: int = Time.get_ticks_msec()
	var ping_time: int = time_when_received_pong - _time_when_sent_ping

	_ping_history.append(ping_time)
	if _ping_history.size() > PING_HISTORY_SIZE:
		_ping_history.pop_front()

	var ping_average: float = _get_ping_average()
	_hud.set_ping_time(ping_average)

	var ping_max: float = _get_ping_max()
	_update_timeslot_buffer_size(ping_max)

	_game_host.receive_ping_time_for_player.rpc_id(1, ping_time)


# NOTE: buffer value rises instantly but lowers gradually.
# This is to prevent abrupt changes in input latency.
func _update_timeslot_buffer_size(ping_time_ms: float):
	var ping_time_sec: float = ping_time_ms / 1000.0
	var new_size: float = ping_time_sec / _tick_delta

	if new_size < _timeslot_buffer_size:
		_timeslot_buffer_size = lerp(_timeslot_buffer_size, new_size, TIMESLOT_BUFFER_SIZE_LOWERING_FACTOR)
	else:
		_timeslot_buffer_size = new_size

	if _timeslot_buffer_size < _turn_length:
		_timeslot_buffer_size = _turn_length


# NOTE: arg must be Array instead of Array[String]. RPC
# calls have typing issues
@rpc("authority", "call_local", "reliable")
func set_lagging_players(lagging_player_list: Array):
	var players_are_lagging: bool = lagging_player_list.size() > 0

	_hud.set_waiting_for_lagging_players_indicator_player_list(lagging_player_list)
	_hud.set_waiting_for_lagging_players_indicator_visible(players_are_lagging)


#########################
###      Private      ###
#########################

func _should_tick(ticks_during_this_process: int) -> bool:
# 	NOTE: need to limit ticks per process to not disrupt
# 	timing of _physics_process() too much
	var too_many_ticks: bool = ticks_during_this_process > Constants.MAX_UPDATE_TICKS_PER_PHYSICS_TICK
	if too_many_ticks:
		return false
	
#	If current tick needs a timeslot and client hasn't
#	received timeslot from host yet, client has to wait
	var need_timeslot: bool = _current_tick % _turn_length == 0
	var have_timeslot: bool = _timeslot_map.has(_current_tick)
	if need_timeslot && !have_timeslot:
		return false

#	NOTE: keep size of timeslot buffer within certain value.
#	If too many timeslots are buffered, client fast forward
#	to catch up to host.
	if !_timeslot_map.is_empty():
		var timeslot_ticks: Array = _timeslot_map.keys()
		timeslot_ticks.sort()
		var latest_timeslot_tick: int = timeslot_ticks.back()
		var ticks_to_latest_timeslot: int = latest_timeslot_tick - _current_tick
		var buffer_is_too_big: bool = ticks_to_latest_timeslot > _timeslot_buffer_size
		
		if buffer_is_too_big:
			return true

#	Tick once per process if don't need to fast forward
	var is_first_tick_during_process: bool = ticks_during_this_process == 0

	return is_first_tick_during_process


func _do_tick():
	var need_timeslot: bool = _current_tick % _turn_length == 0
	var have_timeslot: bool = _timeslot_map.has(_current_tick)
	
	if need_timeslot && !have_timeslot:
		return

	if need_timeslot:
		var timeslot: Array = _timeslot_map[_current_tick]
		_timeslot_map.erase(_current_tick)

		for action in timeslot:
			_execute_action(action)

		var time_to_send_checksum: bool = _current_tick % CHECKSUM_PERIOD_TICKS == 0
		if time_to_send_checksum:
			var checksum: PackedByteArray = _calculate_game_state_checksum()
			_game_host.receive_timeslot_checksum.rpc_id(1, _current_tick, checksum)

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


# NOTE: need to implement this with a match statement
# because action is a plain Dictionary passed via RPC. Doing
# this via dynamic dispatch is not possible because it's not
# possible to pass custom classes through RPC. Also, some
# execute()'s require extra args like "map" which is a
# further obstruction.
func _execute_action(action: Dictionary):
	var player_id: int = action[Action.Field.PLAYER_ID] as int
	var player: Player = PlayerManager.get_player(player_id)

	if player == null:
		push_error("player is null")
		
		return

	var action_type: Action.Type = action[Action.Field.TYPE]

	match action_type:
		Action.Type.IDLE: return
		Action.Type.CHAT: ActionChat.execute(action, player, _hud, _chat_commands)
		Action.Type.BUILD_TOWER: ActionBuildTower.execute(action, player, _build_space)
		Action.Type.UPGRADE_TOWER: ActionUpgradeTower.execute(action, player, _select_unit)
		Action.Type.TRANSFORM_TOWER: ActionTransformTower.execute(action, player)
		Action.Type.SELL_TOWER: ActionSellTower.execute(action, player, _build_space)
		Action.Type.SELECT_BUILDER: ActionSelectBuilder.execute(action, player)
		Action.Type.TOGGLE_AUTOCAST: ActionToggleAutocast.execute(action, player)
		Action.Type.CONSUME_ITEM: ActionConsumeItem.execute(action, player)
		Action.Type.DROP_ITEM: ActionDropItem.execute(action, player)
		Action.Type.MOVE_ITEM: ActionMoveItem.execute(action, player)
		Action.Type.SWAP_ITEMS: ActionSwapItems.execute(action, player)
		Action.Type.AUTOFILL: ActionAutofill.execute(action, player)
		Action.Type.TRANSMUTE: ActionTransmute.execute(action, player)
		Action.Type.RESEARCH_ELEMENT: ActionResearchElement.execute(action, player)
		Action.Type.ROLL_TOWERS: ActionRollTowers.execute(action, player)
		Action.Type.START_NEXT_WAVE: ActionStartNextWave.execute(action, player)
		Action.Type.AUTOCAST: ActionAutocast.execute(action, player)
		Action.Type.FOCUS_TARGET: ActionFocusTarget.execute(action, player)
		Action.Type.CHANGE_BUFFGROUP: ActionChangeBuffgroup.execute(action, player)
		Action.Type.SELECT_WISDOM_UPGRADES: ActionSelectWisdomUpgrades.execute(action, player)
		Action.Type.SELECT_UNIT: ActionSelectUnit.execute(action, player)


func _update_state():
	_game_time.update(_tick_delta)

#	NOTE: use separate groups so that update() calls are
#	ordered by type. This makes gameplay logic more
#	consistent.
	var timer_list: Array = get_tree().get_nodes_in_group("manual_timers")
	var creep_list: Array[Creep] = Utils.get_creep_list()
	var projectile_list: Array = get_tree().get_nodes_in_group("projectiles")
	var tower_list: Array[Tower] = Utils.get_tower_list()
	var node_list: Array = []
	node_list.append_array(timer_list)
	node_list.append_array(creep_list)
	node_list.append_array(projectile_list)
	node_list.append_array(tower_list)

# 	NOTE: need to check is_inside_tree() because nodes may
# 	get removed during iteration. For example, timer_list is
# 	obtained once before iteration starts. Then timer A
# 	triggers an explosion which kills a creep which carries
# 	timer B. Timer B is now outside tree but still inside
# 	timer_list!
	for node in node_list:
		var should_update: bool = node.is_inside_tree() && !node.is_queued_for_deletion()
		if !should_update:
			continue

		node.update(_tick_delta)


func _get_ping_average() -> float:
	var sum: float = 0

	for ping in _ping_history:
		sum += ping

	var ping_average: float = sum / _ping_history.size()

	return ping_average


func _get_ping_max() -> float:
	var ping_max: float = 0

	for ping in _ping_history:
		ping_max = max(ping_max, ping)

	return ping_max



#########################
###     Callbacks     ###
#########################

func _on_ping_timer_timeout():
	_time_when_sent_ping = Time.get_ticks_msec()
	_game_host.receive_ping.rpc_id(1)
