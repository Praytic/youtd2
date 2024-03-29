class_name ActionDropItem


static func make(item_uid_arg: int, position_arg: Vector2, src_item_container_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.DROP_ITEM,
		Action.Field.POSITION: position_arg,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var position: Vector2 = action[Action.Field.POSITION]
	var item_uid: int = action[Action.Field.UID]
	var src_item_container_uid: int = action[Action.Field.SRC_ITEM_CONTAINER_UID]

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)

	if item == null || src_item_container == null:
		Messages.add_error(player, "Failed to drop item.")

		return

	src_item_container.remove_item(item)

	Item.make_item_drop(item, position)
	item.fly_to_stash(0.0)
