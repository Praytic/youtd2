class_name ActionToggleAutocast


static func make(autocast_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TOGGLE_AUTOCAST,
		Action.Field.UID: autocast_uid_arg,
		})

	return action


static func verify(player: Player, autocast: Autocast) -> bool:
	if autocast == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_TOGGLE_AUTOCAST"))

		return false

	var caster: Unit = autocast.get_caster()
	if caster == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_TOGGLE_AUTOCAST_RIGHT_NOW"))

		return false

	var player_match: bool = caster.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_TOWER"))
		
		return false

	var can_use_auto: bool = autocast.can_use_auto_mode()
	if !can_use_auto:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_ABILITY_NOT_AUTOMATIC"))

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
