class_name ActionResearchElement extends Action


var element: Element.enm:
	get:
		return _data[Action.Field.ELEMENT]

static func make(element_arg: Element.enm):
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.RESEARCH_ELEMENT,
		Action.Field.ELEMENT: element_arg,
		})

	return action
