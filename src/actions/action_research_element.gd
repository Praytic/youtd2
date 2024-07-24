class_name ActionResearchElement


static func make(element_arg: Element.enm) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.RESEARCH_ELEMENT,
		Action.Field.ELEMENT: element_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var element: Element.enm = action[Action.Field.ELEMENT]

	var verify_ok: bool = ActionResearchElement.verify(player, element)

	if !verify_ok:
		return

	player.research_element(element)


static func verify(player: Player, element: Element.enm) -> bool:
	var current_level: int = player.get_element_level(element)
	var element_at_max: bool = current_level == Constants.MAX_ELEMENT_LEVEL

	if element_at_max:
		Utils.add_ui_error(player, "Can't research element. Element is at max level.")

		return false

	var can_afford_research: bool = player.can_afford_research(element)

	if !can_afford_research:
		Utils.add_ui_error(player, "Can't research element. You do not have enough tomes.")

		return false

	return true
