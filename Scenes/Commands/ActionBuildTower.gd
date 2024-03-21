class_name ActionBuildTower extends Action


var tower_id: int:
	get:
		return _data[Action.Field.TOWER_ID]
var position: Vector2:
	get:
		return _data[Action.Field.POSITION]


static func make(tower_id_arg: int, position_arg: Vector2):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.BUILD_TOWER,
		Action.Field.TOWER_ID: tower_id_arg,
		Action.Field.POSITION: position_arg,
		})

	return action
