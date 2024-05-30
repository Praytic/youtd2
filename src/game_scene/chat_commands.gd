class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const HELP: String = "/help"
const READY: String = "/ready"
const AUTOSPAWN: String = "/autospawn"

const CREATE_ITEM: String = "/createitem"
const PAUSE: String = "/pause"
const UNPAUSE: String = "/unpause"

const NOT_ALLOWED_IN_MULTIPLAYER_LIST: Array[String] = [
	AUTOSPAWN,
]

const DEV_COMMAND_LIST: Array[String] = [
	CREATE_ITEM,
	PAUSE,
	UNPAUSE,
]

@export var _team_container: TeamContainer


#########################
###       Public      ###
#########################

func process_command(player: Player, command: String):
	var command_split: Array = command.split(" ")
	var command_main: String = command_split[0]
	var command_args: Array = command_split.slice(1)

	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	var is_multiplayer: bool = player_mode == PlayerMode.enm.COOP
	var command_not_allowed_in_multiplayer: bool = NOT_ALLOWED_IN_MULTIPLAYER_LIST.has(command_main)
	if is_multiplayer && command_not_allowed_in_multiplayer:
		Messages.add_error(player, "This command is not allowed in multiplayer.")

		return

	var command_is_dev: bool = DEV_COMMAND_LIST.has(command_main)
	var enable_dev_commands: bool = Config.enable_dev_commands()
	if command_is_dev && !enable_dev_commands:
		Messages.add_error(player, "This command is only available in dev mode.")
		
		return

	match command_main:
		ChatCommands.HELP: _command_help(player)
		ChatCommands.READY: _command_ready(player)
		ChatCommands.PAUSE: _command_pause(player)
		ChatCommands.UNPAUSE: _command_unpause(player)
		ChatCommands.CREATE_ITEM: _command_create_item(player, command_args)
		ChatCommands.AUTOSPAWN: _command_autospawn(player, command_args)


#########################
###      Private      ###
#########################

func _command_help(player: Player):
	Messages.add_normal(player, "You can read about chat commands in the [color=GOLD]Advanced[/color] tab of the [color=GOLD]Hints[/color] menu.")


func _command_ready(player: Player):
	if !player.is_ready():
		player.vote_ready()


func _command_pause(_player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(true)

	Messages.add_normal(null, "Paused the waves. Unpause by typing /unpause.")


func _command_unpause(_player: Player):
	var team_list: Array[Team] = _team_container.get_team_list()
	for team in team_list:
		team.set_waves_paused(false)

	Messages.add_normal(null, "Unpaused the waves.")


func _command_create_item(player: Player, args: Array):
	if args.size() != 1:
		Messages.add_error(player, "Invalid command args.")

		return

	var item_id: int = args[0].to_int()
	var item: Item = Item.create(player, item_id, Vector3(0, 0, 0))
	item.fly_to_stash(0.0)

	Messages.add_normal(player, "Created item %d" % item_id)


# TODO: in multiplayer, it should not be possible for one
# player to change autospawn for whole team. Both players
# need to input same value to agree?
func _command_autospawn(player: Player, args: Array):
	if args.size() != 1:
		Messages.add_error(player, "Invalid command args.")

		return

	var autospawn_time: int = args[0].to_int()

	if 1.0 > autospawn_time || autospawn_time > 100:
		Messages.add_error(player, "Invalid time argument.")

		return

	var team: Team = player.get_team()
	team.set_autospawn_time(autospawn_time)

	Messages.add_normal(player, "Set autospawn time to [color=GOLD]%d[/color]." % roundi(autospawn_time))
