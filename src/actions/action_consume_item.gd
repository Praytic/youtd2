class_name ActionConsumeItem


static func make(item_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CONSUME_ITEM,
		Action.Field.UID: item_uid_arg,
		})

	return action


static func verify(player: Player, item: Item) -> bool:
	if item == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_CONSUME_ITEM"))

		return false

	var player_match: bool = item.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_ITEM"))

		return false

	return true


static func execute(action: Dictionary, player: Player):
	var item_uid: int = action[Action.Field.UID]

	var item_node: Node = GroupManager.get_by_uid("items", item_uid)
	var item: Item = item_node as Item

	var verify_ok: bool = ActionConsumeItem.verify(player, item)
	if !verify_ok:
		return

	item.consume()
