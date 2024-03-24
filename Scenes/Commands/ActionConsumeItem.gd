class_name ActionConsumeItem extends Action


var item_uid: int:
	get:
		return _data[Action.Field.UID]


static func make(item_uid_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.CONSUME_ITEM,
		Action.Field.UID: item_uid_arg,
		})

	return action
