class_name ActionDropItem extends Action


var item_uid: int:
	get:
		return _data[Action.Field.UID]


var position: Vector2:
	get:
		return _data[Action.Field.POSITION]


var src_item_container_uid: int:
	get:
		return _data[Action.Field.SRC_ITEM_CONTAINER_UID]


static func make(item_uid_arg: int, position_arg: Vector2, src_item_container_uid_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.DROP_ITEM,
		Action.Field.POSITION: position_arg,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		})

	return action
