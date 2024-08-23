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


var _tick_delta: float
var _current_tick: int = 0
var _current_turn_length: int = 0

# A map of timeslots. Need to keep a map in case we receive
# future timeslots before we processed current one.
# {tick -> timeslot}
var _timeslot_map: Dictionary = {}
var _timeslot_tick_queue: Array = [0]
var _time_when_sent_ping: int = 0


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
	var socket: NakamaSocket = NakamaConnection.get_socket()
	socket.received_match_state.connect(_on_nakama_received_match_state)

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

func send_message_PLAYER_LOADED_GAME_SCENE():
	var op_code: int = NakamaOpCode.enm.PLAYER_LOADED_GAME_SCENE
	var data: Dictionary = {}
	_send_message_to_host(op_code, data)


@rpc("authority", "call_local", "reliable")
func receive_enet_message(op_code: NakamaOpCode.enm, data: Dictionary):
	_process_message_generic(op_code, data)


# Send action from client to host
func add_action(action: Action):
	var serialized_action: Dictionary = action.serialize()

	var op_code: int = NakamaOpCode.enm.PLAYER_ACTION
	var data: Dictionary = {"action": serialized_action}
	_send_message_to_host(op_code, data)


@rpc("authority", "call_local", "reliable")
func receive_pong():
	var time_when_received_pong: int = Time.get_ticks_msec()
	var ping_time: int = time_when_received_pong - _time_when_sent_ping
	_hud.set_ping_time(ping_time)

	_game_host.receive_ping_time_for_player.rpc_id(1, ping_time)


# NOTE: arg must be Array instead of Array[String]. RPC
# calls have typing issues
@rpc("authority", "call_local", "reliable")
func enter_waiting_for_lagging_players_state(lagging_player_list: Array):
	_hud.set_waiting_for_lagging_players_indicator_player_list(lagging_player_list)
	_hud.set_waiting_for_lagging_players_indicator_visible(true)


@rpc("authority", "call_local", "reliable")
func exit_waiting_for_lagging_players_state():
	_hud.set_waiting_for_lagging_players_indicator_visible(false)


#########################
###      Private      ###
#########################

# This f-n handles messages sent both through Enet and
# Nakama connections.
func _process_message_generic(op_code: int, data: Dictionary):
	match op_code:
		NakamaOpCode.enm.TIMESLOT: _process_message_TIMESLOT(data)
		_: pass


# Receive timeslot sent by host to this client and receive
# turn length
func _process_message_TIMESLOT(data: Dictionary):
	var timeslot: Array = data.get("timeslot", [])
	var current_turn_length: int = data.get("current_turn_length", 0)

	var tick_for_this_timeslot: int = _timeslot_tick_queue.back()
	_timeslot_map[tick_for_this_timeslot] = timeslot
	var tick_for_next_timeslot: int = tick_for_this_timeslot + current_turn_length
	_timeslot_tick_queue.append(tick_for_next_timeslot)
	_current_turn_length = current_turn_length



# NOTE: data dict must be serializable to JSON. It must
# contain only built-in Godot types, no custom
# types/classes.
func _send_message_to_host(op_code: NakamaOpCode.enm, data: Dictionary):
	var connection_type: Globals.ConnectionType = Globals.get_connect_type()

	match connection_type:
		Globals.ConnectionType.NAKAMA:
			var data_string: String = JSON.stringify(data)
			var socket: NakamaSocket = NakamaConnection.get_socket()
			var match_id: String = NakamaConnection.get_match_id()
			var host_presence: NakamaRTAPI.UserPresence = NakamaConnection.get_host_presence()
			var send_match_state_result: NakamaAsyncResult = await socket.send_match_state_async(match_id, op_code, data_string, [host_presence])

			if send_match_state_result.is_exception():
				push_error("_send_message_to_host() failed. Error: %s" % send_match_state_result)
		Globals.ConnectionType.ENET:
			_game_host.receive_enet_message.rpc_id(1, op_code, data)


func _should_tick(ticks_during_this_process: int) -> bool:
# 	NOTE: need to limit ticks per process to not disrupt
# 	timing of _physics_process() too much
	var too_many_ticks: bool = ticks_during_this_process > Constants.MAX_UPDATE_TICKS_PER_PHYSICS_TICK
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
	var need_to_fast_forward: bool = latest_timeslot_tick - _current_tick > 2 * _current_turn_length
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

#		TODO: disabled call to receive_timeslot_ack() while
#		integrating nakama. Make this work with nakama or
#		get rid of this.

#		Tell host that this client has processed this
#		timeslot. Send checksum to check for desyncs.
		# var checksum: PackedByteArray = _calculate_game_state_checksum()
		# _game_host.receive_timeslot_ack.rpc_id(1, checksum)

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
		Action.Type.SET_PLAYER_NAME: ActionSetPlayerName.execute(action, player)
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


#########################
###     Callbacks     ###
#########################

func _on_ping_timer_timeout():
	_time_when_sent_ping = Time.get_ticks_msec()
	# TODO: disabled this while integrating nakama
	# _game_host.receive_ping.rpc_id(1)


# TODO: remove duplication of code here and same f-n in
# GameHost.
func _on_nakama_received_match_state(message: NakamaRTAPI.MatchData):
	var sender_is_valid: bool = NakamaOpCode.validate_message_sender(message)
	if !sender_is_valid:
		return

	var op_code: int = message.op_code

	var data_dict: Dictionary
	var data_string: String = message.data
	var parse_result = JSON.parse_string(data_string)
	var parse_success: bool = parse_result != null
	if parse_success:
		data_dict = parse_result
	else:
		data_dict = {}

	_process_message_generic(op_code, data_dict)
