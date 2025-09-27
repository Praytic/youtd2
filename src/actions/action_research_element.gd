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
	var element_at_max: bool = current_level == player.get_max_element_level()

	if element_at_max:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_ELEMENT_AT_MAX_LEVEL"))

		return false

	var can_afford_research: bool = player.can_afford_research(element)

	if !can_afford_research:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_NOT_ENOUGH_TOMES_FOR_RESEARCH"))

		return false

	return true
