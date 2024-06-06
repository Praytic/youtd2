class_name ActionRollTowers


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.ROLL_TOWERS,
		})

	return action


static func execute(_action: Dictionary, player: Player):
	var verify_ok: bool = ActionRollTowers.verify(player)

	if !verify_ok:
		return

	player.roll_starting_towers()


static func verify(player: Player) -> bool:
	var researched_any_elements: bool = false
	for element in Element.get_list():
		var researched_element: bool = player.get_element_level(element)
		if researched_element:
			researched_any_elements = true
	
	if !researched_any_elements:
		Messages.add_error(player, "Cannot roll towers yet! You need to research at least one element.")
	
		return false

	var tower_count_for_roll: int = player.get_tower_count_for_starting_roll()

	if tower_count_for_roll <= 0:
		Messages.add_error(player, "Can't roll anymore.")

		return false

	return true
