class_name CommandBuildTower extends Command


var tower_id: int:
	get:
		return _data[Command.Field.TOWER_ID]
var position: Vector2:
	get:
		return _data[Command.Field.POSITION]


static func make(tower_id_arg: int, position_arg: Vector2):
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.BUILD_TOWER,
		Command.Field.TOWER_ID: tower_id_arg,
		Command.Field.POSITION: position_arg,
		})

	return command
