class_name ActionMoveItem extends Action


var item_uid: int:
	get:
		return _data[Action.Field.UID]


var src_item_container_uid: int:
	get:
		return _data[Action.Field.SRC_ITEM_CONTAINER_UID]


var dest_item_container_uid: int:
	get:
		return _data[Action.Field.DEST_ITEM_CONTAINER_UID]


static func make(item_uid_arg: int, src_item_container_uid_arg: int, dest_item_container_uid_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.MOVE_ITEM,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		Action.Field.DEST_ITEM_CONTAINER_UID: dest_item_container_uid_arg,
		})

	return action
