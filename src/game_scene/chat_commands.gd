class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const GAMESPEED_MIN: int = 1
const GAMESPEED_MAX: int = 30
const DAMAGE_METERS_TOWER_COUNT: int = 5


const HELP: Array[String] = ["/help"]
const READY: Array[String] = ["/ready"]
const AUTOSPAWN: Array[String] = ["/autospawn", "/as"]
const AUTOOIL: Array[String] = ["/autooil", "/ao"]
const GAMESPEED: Array[String] = ["/gamespeed", "/gs"]
const DAMAGE_METERS: Array[String] = ["/damage-meters", "/dm"]
const DAMAGE_METERS_RECENT: Array[String] = ["/damage-meters-recent", "/dmr"]
const IGNORE: Array[String] = ["/ignore"]
const UNIGNORE: Array[String] = ["/unignore"]
const PING: Array[String] = ["/ping"]
const PAUSE: Array[String] = ["/pause"]
const UNPAUSE: Array[String] = ["/unpause"]
const CHECK_RANGE_FRIENDLY: Array[String] = ["/check-range-friendly", "/crf"]
const CHECK_RANGE_ATTACK: Array[String] = ["/check-range-attack", "/cra"]
const PRINT_RANGES_TO_TOWERS: Array[String] = ["/print-ranges-to-towers", "/prtt"]
const ALLOW_ALL: Array[String] = ["/allow-all"]

const CREATE_ITEM: Array[String] = ["/createitem", "/ci"]
const PAUSE_WAVES: Array[String] = ["/pause-waves", "/pw"]
const UNPAUSE_WAVES: Array[String] = ["/unpause-waves", "/upw"]
const ADD_EXP: Array[String] = ["/add-exp", "/ae"]
const ADD_TEST_OILS: Array[String] = ["/add-test-oils", "/ato"]
const SPAWN_CHALLENGE: Array[String] = ["/spawn-challenge", "/sc"]
const SETUP_TEST_TOWER: Array[String] = ["/setup-test-tower", "/stt"]
const FULL_MANA: Array[String] = ["/full-mana", "/fm"]

const HOST_COMMAND_LIST_OF_LISTS: Array = [
	PAUSE,
	UNPAUSE,
	GAMESPEED,
]

const DEV_COMMAND_LIST_OF_LISTS: Array = [
	CREATE_ITEM,
	PAUSE_WAVES,
	UNPAUSE_WAVES,
	ADD_EXP,
	ADD_TEST_OILS,
	SPAWN_CHALLENGE,
	SETUP_TEST_TOWER,
	FULL_MANA,
]

# Comamnds in this list will be executed only for the player
# which typed them.
# NOTE: care must be taken to avoid desyncs for such commands
const LOCAL_ONLY_COMMANDS_LIST_OF_LISTS: Array = [
	HELP,
	DAMAGE_METERS,
	DAMAGE_METERS_RECENT,
	IGNORE,
	UNIGNORE,
	PING,
	CHECK_RANGE_FRIENDLY,
	CHECK_RANGE_ATTACK,
	PRINT_RANGES_TO_TOWERS,
]

var not_allowed_in_multiplayer: Array = []
var dev_command_list: Array = []
var local_only_command_list: Array = []
var host_command_list: Array = []

@export var _team_container: TeamContainer
@export var _hud: HUD
@export var _game_client: GameClient
@export var _range_checker: TowerPreview


#########################
###     Built-in      ###
#########################

# NOTE: need to convert list of lists into list of strings
# for easy "has()" calls
func _ready():
	for list in HOST_COMMAND_LIST_OF_LISTS:
		host_command_list.append_array(list)

	for list in DEV_COMMAND_LIST_OF_LISTS:
		dev_command_list.append_array(list)

	for list in LOCAL_ONLY_COMMANDS_LIST_OF_LISTS:
		local_only_command_list.append_array(list)


#########################
###       Public      ###
#########################

func process_command(player: Player, command: String):
	var command_split: Array = command.split(" ")
	var command_main: String = command_split[0]
	var command_args: Array = command_split.slice(1)

	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	var is_multiplayer: bool = player_mode == PlayerMode.enm.MULTIPLAYER
	var command_not_allowed_in_multiplayer: bool = not_allowed_in_multiplayer.has(command_main)
	if is_multiplayer && command_not_allowed_in_multiplayer:
		_add_error(player, tr("COMMAND_NOT_ALLOWED_IN_MULTIPLAYER"))

		return

	var command_is_dev: bool = dev_command_list.has(command_main)
	var enable_dev_commands: bool = Config.enable_dev_commands()
	if command_is_dev && !enable_dev_commands:
		_add_error(player, tr("COMMAND_ONLY_DEV_MODE"))
		
		return

	var command_is_local_only: bool = local_only_command_list.has(command_main)
	var player_is_local: bool = player == PlayerManager.get_local_player()
	if command_is_local_only && !player_is_local:
		print_verbose("Skipping command %s because it's local only and was requested by another player." % command)
		
		return

	var command_is_host_only: bool = host_command_list.has(command_main)
	var player_is_host: bool = player.get_peer_id() == 1
	if command_is_host_only && !player_is_host:
		_add_error(player, tr("COMMAND_ONLY_HOST"))
		
		return

	if HELP.has(command_main):
		_command_help(player)
	elif READY.has(command_main):
		_command_ready(player)
	elif AUTOSPAWN.has(command_main):
		_command_autospawn(player, command_args)
	elif AUTOOIL.has(command_main):
		_command_autooil(player, command_args)
	elif GAMESPEED.has(command_main):
		_command_gamespeed(player, command_args)
	elif CREATE_ITEM.has(command_main):
		_command_create_item(player, command_args)
	elif PAUSE_WAVES.has(command_main):
		_command_pause_waves(player)
	elif UNPAUSE_WAVES.has(command_main):
		_command_unpause_waves(player)
	elif ADD_EXP.has(command_main):
		_command_add_exp(player, command_args)
	elif ADD_TEST_OILS.has(command_main):
		_command_add_test_oils(player, command_args)
	elif SPAWN_CHALLENGE.has(command_main):
		_command_spawn_challenge(player, command_args)
	elif SETUP_TEST_TOWER.has(command_main):
		_command_setup_test_tower(player, command_args)
	elif FULL_MANA.has(command_main):
		_command_full_mana(player, command_args)
	elif DAMAGE_METERS.has(command_main):
		_command_damage_meters(player, command_args)
	elif DAMAGE_METERS_RECENT.has(command_main):
		_command_damage_meters_recent(player, command_args)
	elif IGNORE.has(command_main):
		_command_ignore(player, command_args)
	elif UNIGNORE.has(command_main):
		_command_unignore(player, command_args)
	elif PING.has(command_main):
		_command_ping()
	elif PAUSE.has(command_main):
		_command_pause()
	elif UNPAUSE.has(command_main):
		_command_unpause()
	elif CHECK_RANGE_FRIENDLY.has(command_main):
		_command_check_range_friendly(player, command_args)
	elif CHECK_RANGE_ATTACK.has(command_main):
		_command_check_range_attack(player, command_args)
	elif PRINT_RANGES_TO_TOWERS.has(command_main):
		_command_print_ranges_to_towers(player)
	elif ALLOW_ALL.has(command_main):
		_command_allow_all(player)
	else:
		_add_error(player, tr("COMMAND_UNKNOWN").format({COMMAND = command_main}))


#########################
###      Private      ###
#########################

func _command_help(_player: Player):
	EventBus.player_requested_help.emit()


func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()


func _command_gamespeed(player: Player, args: Array):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	var value: int = args[0].to_int()

	if GAMESPEED_MIN > value || value > GAMESPEED_MAX:
		_add_error(player, tr("COMMAND_GAMESPEED_OUT_OF_RANGE").format({MIN = GAMESPEED_MIN, MAX = GAMESPEED_MAX}))

		return

	Globals.set_update_ticks_per_physics_tick(value)

	_add_status(player, tr("COMMAND_GAMESPEED_SUCCESS").format({GAMESPEED = value}))


func _command_pause_waves(_player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(true)

	_add_status(null, tr("COMMAND_PAUSE_WAVES"))


func _command_unpause_waves(_player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(false)

	_add_status(null, tr("COMMAND_UNPAUSE_WAVES"))


func _command_create_item(player: Player, args: Array):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	var item_id: int = args[0].to_int()
	var item: Item = Item.create(player, item_id, Vector3(0, 0, 0))
	item.fly_to_stash(0.0)

	_add_status(player, tr("COMMAND_CREATED_ITEM").format({ITEM_ID = item_id}))


func _command_autospawn(player: Player, args: Array):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	var team: Team = player.get_team()

	var option: String = args[0]
	var disable_autospawn: bool = option == "off"

	if disable_autospawn:
		team.set_autospawn_time(-1)
		_add_status_for_team(team, tr("COMMAND_AUTOSPAWN_DISABLE"))

		return

	var autospawn_time: int = option.to_int()

	if 1.0 > autospawn_time || autospawn_time > 100:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	team.set_autospawn_time(autospawn_time)

	_add_status_for_team(team, tr("COMMAND_AUTOSPAWN_SET").format({TIME = roundi(autospawn_time)}))

func _is_tower(unit: Unit) -> bool:
	# return false if non-tower is selected or unit is null
	return unit != null and unit is Tower

func _require_tower(unit: Unit, player: Player) -> bool:
	if not unit is Tower:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))
		return false
	return true

func _require_owner(tower: Tower, player: Player) -> bool:
	# other player case
	if tower.get_player() != player:
		_add_error(player, tr("MESSAGE_DONT_OWN_TOWER"))
		return false
	return true

func _resolve_autooil_arg(player: Player, option: String):
	var unit: Unit = player.get_selected_unit()
	
	var tower: Tower = null
	var tower_name: String = ""
	var is_tower: bool = _is_tower(unit)
	if is_tower:
		tower = unit as Tower
		tower_name = tower.get_display_name()
		
	var matched: bool = true
	
	match option:
		"list":
			var oil_type_list: Array = AutoOil.get_oil_type_list()
			var text: String = ", ".join(oil_type_list)
			_add_status(player, tr("COMMAND_AVAILABLE_OILS"))
			_add_status(player, text)
		"show":
			var status_text: String = player.get_autooil_status()
			_add_status(player, tr("COMMAND_AUTOOIL_STATUS"))
			Messages.add_normal(player, status_text)
		"clear":
			if not is_tower:
				player.clear_all_autooil()
				_add_status(player, tr("COMMAND_AUTOOIL_CLEAR_ALL"))
			else:
				if _require_owner(tower, player):
					player.clear_autooil_for_tower(tower)
					_add_status(player, tr("COMMAND_AUTOOIL_CLEAR_FOR_TOWER").format({TOWER = tower_name}))
				else:
					return
		_:
			matched = false
	
	if matched:
		return
	
	if _require_tower(unit, player) and _require_owner(tower, player):
		var oil_type: String = option
		var oil_type_is_valid: bool = AutoOil.get_oil_type_is_valid(oil_type)
		
		if not oil_type_is_valid:
			_add_error(player, tr("COMMAND_INVALID_OIL_TYPE").format({OIL = oil_type}))
			return
		
		var full_oil_type: String = AutoOil.convert_short_type_to_full(oil_type)
		player.set_autooil_for_tower(full_oil_type, tower)
		_add_status(player, tr("COMMAND_AUTOOIL_SET").format({TOWER = tower_name, OIL_TYPE = full_oil_type}))

		return
	else:
		return


func _command_autooil(player: Player, args: Array):
	for option in args:
		_resolve_autooil_arg(player, option)
	

func _command_add_exp(player: Player, args: Array):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	var selected_tower: Unit = player.get_selected_unit()

	if selected_tower == null:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))

		return

	var exp_amount: int = args[0].to_int()
	selected_tower.add_exp(exp_amount)

	_add_status(player, tr("COMMAND_ADD_EXP").format({EXP_AMOUNT = exp_amount}))


func _command_add_test_oils(player: Player, _args: Array):
	var selected_tower: Unit = player.get_selected_unit()

	if selected_tower == null:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))

		return

	_add_test_oils(player, selected_tower)
	_add_status(player, tr("COMMAND_ADD_TEST_OILS"))


func _command_spawn_challenge(player: Player, args: Array):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS"))

		return

	var creep_level: int = args[0].to_int()
	var armor_type: ArmorType.enm = ArmorType.enm.ZOD
	var difficulty: Difficulty.enm = Globals.get_difficulty()
	var creep_health: float = Wave._calculate_base_hp(creep_level, difficulty, armor_type)
	var creep_armor: float = Wave._calculate_base_armor(creep_level, difficulty)
	var creep_path: Path2D = Utils.find_creep_path(player, false)

	var creep_scene: PackedScene = Preloads.creep_scenes["ChallengeBoss"]
	var creep: Creep = creep_scene.instantiate()
	creep.set_properties(creep_path, player, CreepSize.enm.CHALLENGE_BOSS, armor_type, CreepCategory.enm.CHALLENGE, creep_health, creep_armor, creep_level)

	var first_path_point: Vector2 = Utils.get_path_point_wc3(creep_path, 0)
	creep.set_position_wc3_2d(first_path_point)

	Utils.add_object_to_world(creep)

	_add_status(player, tr("COMMAND_SPAWN_CHALLENGE").format({LEVEL = creep_level}))


func _command_setup_test_tower(player: Player, _args: Array):
	var selected_tower: Unit = player.get_selected_unit()

	if selected_tower == null:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))

		return

	selected_tower.add_exp(1000)
	_add_test_oils(player, selected_tower)
	_add_status(player, tr("COMMAND_SETUP_TEST_TOWER"))


func _command_full_mana(player: Player, _args: Array):
	var selected_tower: Unit = player.get_selected_unit()

	if selected_tower == null:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))

		return

	selected_tower.add_mana_perc(1.0)


func _command_damage_meters(player: Player, _args: Array):
	var tower_list: Array[Tower] = Utils.get_tower_list()

	tower_list.sort_custom(
		func(a: Tower, b: Tower) -> bool:
			var damage_a: float = a.get_total_damage()
			var damage_b: float = b.get_total_damage()
			
			return damage_a > damage_b
			)

	_add_status(player, tr("COMMAND_TOP_TOWERS_BY_DAMAGE"))

	var count: int = 0
	for tower in tower_list:
		if count > DAMAGE_METERS_TOWER_COUNT:
			break

		var tower_name: String = tower.get_display_name()
		var damage: float = tower.get_total_damage()
		var damage_string: String = TowerDetails.int_format(damage)
		
		var damage_attack: float = tower.get_total_damage_by_type(Tower.DamageSource.Attack)
		var attack_percentage: float = Utils.divide_safe(damage_attack, damage) * 100
		var attack_percentage_string: String = Utils.format_float(attack_percentage, 1)
		
		var damage_spell: float = tower.get_total_damage_by_type(Tower.DamageSource.Spell)
		var spell_percentage: float = Utils.divide_safe(damage_spell, damage) * 100
		var spell_percentage_string: String = Utils.format_float(spell_percentage, 1)
		
		Messages.add_normal(player, "%s: [color=GOLD]%s[/color], attack:%s%%, spell: %s%%" % [tower_name, damage_string, attack_percentage_string, spell_percentage_string])

		count += 1


func _command_damage_meters_recent(player: Player, _args: Array):
	var tower_list: Array[Tower] = Utils.get_tower_list()

	tower_list.sort_custom(
		func(a: Tower, b: Tower) -> bool:
			var damage_a: float = a.get_total_damage_recent()
			var damage_b: float = b.get_total_damage_recent()
			
			return damage_a > damage_b
			)

	_add_status(player, tr("COMMAND_TOP_TOWERS_BY_RECENT_DAMAGE"))

	var count: int = 0
	for tower in tower_list:
		if count > DAMAGE_METERS_TOWER_COUNT:
			break

		var tower_name: String = tower.get_display_name()
		
		var damage: float = tower.get_total_damage_recent()
		var damage_string: String = TowerDetails.int_format(damage)
		
		var damage_attack: float = tower.get_total_damage_recent(true, Tower.DamageSource.Attack)
		var attack_percentage: float = Utils.divide_safe(damage_attack, damage) * 100
		var attack_percentage_string: String = Utils.format_float(attack_percentage, 1)

		var damage_spell: float = tower.get_total_damage_recent(true, Tower.DamageSource.Spell)
		var spell_percentage: float = Utils.divide_safe(damage_spell, damage) * 100
		var spell_percentage_string: String = Utils.format_float(spell_percentage, 1)
		
		Messages.add_normal(player, "%s: [color=GOLD]%s[/color], attack:%s%%, spell: %s%%" % [tower_name, damage_string, attack_percentage_string, spell_percentage_string])

		count += 1


func _command_ignore(player: Player, args: Array):
	_command_ignore_helper(player, args, true)


func _command_unignore(player: Player, args: Array):
	_command_ignore_helper(player, args, false)


# NOTE: ignore command has a flaw where it ingores all
# players who have the target name.
func _command_ignore_helper(player: Player, args: Array, ignored_value: bool):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS_FOR_IGNORE"))

		return

	var target_name: String = args[0]

	var player_list: Array[Player] = PlayerManager.get_player_list()

	for p in player_list:
		var this_name: String = p.get_player_name()
		var name_match: bool = this_name == target_name

		if name_match:
			p.set_chat_ignored(ignored_value)

			var player_name_with_color: String = p.get_player_name_with_color()
			var status_string: String
			if ignored_value == true:
				status_string = tr("COMMAND_IGNORE_START").format({PLAYER = player_name_with_color})
			else:
				status_string = tr("COMMAND_IGNORE_STOP").format({PLAYER = player_name_with_color})

			_add_status(player, status_string)


func _command_ping():
	_hud.toggle_ping_indicator_visibility()


func _command_pause():
	_command_pause_helper(true)


func _command_unpause():
	_command_pause_helper(false)

func _command_pause_helper(value: bool):
	_hud.set_multiplayer_pause_indicator_visible(value)
	_game_client.set_paused_by_host(value)


func _command_check_range_friendly(player: Player, args: Array):
	var friendly: bool = true
	_command_check_range_helper(player, args, friendly)


func _command_check_range_attack(player: Player, args: Array):
	var friendly: bool = false
	_command_check_range_helper(player, args, friendly)


func _command_print_ranges_to_towers(player: Player):
	var selected_unit: Unit = player.get_selected_unit()
	
	if selected_unit == null || !selected_unit is Tower:
		_add_error(player, tr("COMMAND_MUST_SELECT_TOWER"))

		return

	var tower_list: Array[Tower] = Utils.get_tower_list()

	var selected_tower_pos: Vector2 = selected_unit.get_position_wc3_2d()

	var message_list: Array[String] = []

	for other_tower in tower_list:
		var other_tower_name: String = other_tower.get_display_name()
		var other_tower_pos: Vector2 = other_tower.get_position_wc3_2d()
		var range_to_tower: float = selected_tower_pos.distance_to(other_tower_pos)
		range_to_tower -= Constants.RANGE_CHECK_BONUS_FOR_TOWERS
		range_to_tower = round(range_to_tower)
		var message: String = tr("COMMAND_RANGE_BETWEEN_TOWERS").format({TOWER = other_tower_name, RANGE = range_to_tower})
		message_list.append(message)

	for message in message_list:
		print(message)

#	NOTE: display message on screen with a delay so that all
#	of the messages can be read, in case they don't fit on
#	screen if shown at the same time.
	for message in message_list:
		_add_status(player, message)

#		NOTE: need to use create_timer() instead of
#		create_manual_timer() here because this code is
#		executed only for local player (command is local
#		only)
		await get_tree().create_timer(1.0).timeout


func _command_allow_all(player: Player):
	var team: Team = player.get_team()

	team.enable_allow_shared_build_space()

	_add_status_for_team(team, tr("COMMAND_ALLOW_SHARED_BUILDING"))


func _command_check_range_helper(player: Player, args: Array, friendly: bool):
	if args.size() != 1:
		_add_error(player, tr("COMMAND_INVALID_ARGS_FOR_RANGE_CHECK"))

		return
	
	var arg_string: String = args[0]
	
	if arg_string == "off":
		_range_checker.hide()
		_add_status(player, tr("COMMAND_RANGE_CHECK_DISABLE"))
		
		return
	
	var radius: int = arg_string.to_int()
	_range_checker.set_range_manual(radius, friendly)
	_range_checker.show()


# NOTE: oil counts are based on average oil counts obtained
# by wave 200
func _add_test_oils(player: Player, tower: Tower):
	const test_oil_map: Dictionary = {
		1001: 20, # sharpness (attack damage)
		1002: 10, # arcane sharpness (attack damage)
		1003: 3,  # divine sharpness (attack damage)

		1004: 20, # magic (mana pool and regen)
		1005: 10, # magic (mana pool and regen)
		1006: 3, # magic (mana pool and regen)

		1007: 20, # accuracy (attack crit)
		1008: 10, # accuracy (attack crit)
		1009: 3, # accuracy (attack crit)

		1010: 20, # swiftness (attack speed)
		1011: 10, # swiftness (attack speed)
		1012: 3, # swiftness (attack speed)

		1013: 20, # sorcery (spell damage and spell crit)
		1014: 10, # sorcery (spell damage and spell crit)
		1015: 3, # sorcery (spell damage and spell crit)
	}

	for oil_id in test_oil_map.keys():
		var oil_count: int = test_oil_map[oil_id]

		for i in range(0, oil_count):
			var oil_item: Item = Item.create(player, oil_id, Vector3.ZERO)
			oil_item.pickup(tower)


func _add_status(player: Player, text: String):
	Messages.add_normal(player, "[color=CYAN]%s[/color]" % text)


func _add_error(player: Player, text: String):
	Messages.add_normal(player, "[color=RED]%s[/color]" % text)


func _add_status_for_team(team: Team, text: String):
	var player_list: Array[Player] = team.get_players()

	for player in player_list:
		_add_status(player, text)
