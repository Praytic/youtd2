class_name ActionToggleAutocast


static func make(autocast_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TOGGLE_AUTOCAST,
		Action.Field.UID: autocast_uid_arg,
		})

	return action


static func verify(player: Player, autocast: Autocast) -> bool:
	if autocast == null:
		Messages.add_error(player, "Failed to toggle autocast")

		return false

	var caster: Unit = autocast.get_caster()
	if caster == null:
		Messages.add_error(player, "Can't toggle autocast right now")

		return false

	var player_match: bool = caster.get_player() == player
	if !player_match:
		Messages.add_error(player, "You don't own this tower")
		
		return false

	var can_use_auto: bool = autocast.can_use_auto_mode()
	if !can_use_auto:
		Messages.add_error(player, "This ability cannot be casted automatically")

		return false

	return true


static func execute(action: Dictionary, player: Player):
	var autocast_uid: int = action[Action.Field.UID]

	var autocast_node: Node = GroupManager.get_by_uid("autocasts", autocast_uid)
	var autocast: Autocast = autocast_node as Autocast

	var verify_ok: bool = ActionToggleAutocast.verify(player, autocast)

	if !verify_ok:
		return

	autocast.toggle_auto_mode()
