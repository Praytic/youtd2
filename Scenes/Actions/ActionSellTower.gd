class_name ActionSellTower extends Action


var tower_unit_id: int:
	get:
		return _data[Action.Field.UID]


static func make(tower_unit_id_arg: int):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELL_TOWER,
		Action.Field.UID: tower_unit_id_arg,
		})

	return action
