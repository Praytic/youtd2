class_name ActionConsumeItem


static func make(item_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CONSUME_ITEM,
		Action.Field.UID: item_uid_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var item_uid: int = action[Action.Field.UID]

	var item_node: Node = GroupManager.get_by_uid("items", item_uid)
	var item: Item = item_node as Item

	if item == null:
		Messages.add_error(player, "Failed to consume item.")

		return

	item.consume()
