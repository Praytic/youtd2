class_name ActionMoveItem


static func make(item_uid_arg: int, src_item_container_uid_arg: int, dest_item_container_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.MOVE_ITEM,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		Action.Field.DEST_ITEM_CONTAINER_UID: dest_item_container_uid_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var item_uid: int = action[Action.Field.UID]
	var src_item_container_uid: int = action[Action.Field.SRC_ITEM_CONTAINER_UID]
	var dest_item_container_uid: int = action[Action.Field.DEST_ITEM_CONTAINER_UID]

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)
	var dest_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", dest_item_container_uid)

	if item == null || src_item_container == null || dest_item_container == null:
		Messages.add_error(player, "Failed to drop item.")

		return

	if !MoveItem.verify_move(player, item, dest_item_container):
		return

	src_item_container.remove_item(item)
	dest_item_container.add_item(item)
