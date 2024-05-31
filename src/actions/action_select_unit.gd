class_name ActionSelectUnit


static func make(unit_id: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SELECT_UNIT,
		Action.Field.UID: unit_id,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var unit_uid: int = action[Action.Field.UID]
	var unit_is_null: bool = unit_uid == -1

	var selected_unit: Unit
	if unit_is_null:
		selected_unit = null
	else:
		var unit_node: Node = GroupManager.get_by_uid("units", unit_uid)
		selected_unit = unit_node as Unit

		if selected_unit == null:
			push_error("Select unit action failed")

			return

	player.set_selected_unit(selected_unit)
