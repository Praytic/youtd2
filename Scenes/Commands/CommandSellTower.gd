class_name CommandSellTower extends Command


var tower_unit_id: int:
	get:
		return _data[Command.Field.TOWER_UNIT_ID]


static func make(tower_unit_id_arg: int):
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.SELL_TOWER,
		Command.Field.TOWER_UNIT_ID: tower_unit_id_arg,
		})

	return command
