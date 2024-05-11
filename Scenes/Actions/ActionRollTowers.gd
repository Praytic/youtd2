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

	var tower_stash: TowerStash = player.get_tower_stash()
	tower_stash.clear()

	var tower_count_for_roll: int = player.get_tower_count_for_starting_roll()
	var rolled_towers: Array[int] = TowerDistribution.generate_random_towers_with_count(player, tower_count_for_roll)
	tower_stash.add_towers(rolled_towers)
	player.decrement_tower_count_for_starting_roll()

	player.add_message_about_rolled_towers(rolled_towers)
	
	var remaining_roll_count: int = player.get_tower_count_for_starting_roll()
	Messages.add_normal(player, "You have [color=GOLD]%d[/color] rerolls remaining." % remaining_roll_count)

	EventBus.local_player_rolled_towers.emit()


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
