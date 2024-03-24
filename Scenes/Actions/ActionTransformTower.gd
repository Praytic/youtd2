class_name ActionTransformTower extends Action


var tower_id: int:
	get:
		return _data[Action.Field.TOWER_ID]
var global_pos: Vector2:
	get:
		return _data[Action.Field.POSITION]


static func make(tower_id_arg: int, global_pos_arg: Vector2):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.TRANSFORM_TOWER,
		Action.Field.TOWER_ID: tower_id_arg,
		Action.Field.POSITION: global_pos_arg,
		})

	return action
