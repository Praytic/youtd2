class_name ChatCommands extends Node

# Processes chat commands. All chat messages which start
# with "/" are treated as commands.


const READY: String = "/ready"
const PAUSE: String = "/pause"
const UNPAUSE: String = "/unpause"
const CREATE_ITEM: String = "/createitem"

const ALLOWED_IN_MULTIPLAYER_LIST: Array[String] = [
	READY,
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
	if is_multiplayer:
		var command_is_allowed_in_multiplayer: bool = ALLOWED_IN_MULTIPLAYER_LIST.has(command_main)

		if !command_is_allowed_in_multiplayer:
			Messages.add_error(player, "This command is not allowed in multiplayer.")

			return

	match command_main:
		ChatCommands.READY: _command_ready(player)
		ChatCommands.PAUSE: _command_pause(player)
		ChatCommands.UNPAUSE: _command_unpause(player)
		ChatCommands.CREATE_ITEM: _command_create_item(player, command_args)


#########################
###      Private      ###
#########################

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
	var item: Item = Item.create(player, item_id, Vector2(0, 0))
	item.fly_to_stash(0.0)

	Messages.add_normal(player, "Created item %d" % item_id)
