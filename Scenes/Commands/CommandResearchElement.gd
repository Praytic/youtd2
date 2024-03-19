class_name CommandResearchElement extends Command


var element: Element.enm:
	get:
		return _data[Command.Field.ELEMENT]

static func make(element_arg: Element.enm):
	var command: Command = Command.new({
		Command.Field.TYPE: Command.Type.RESEARCH_ELEMENT,
		Command.Field.ELEMENT: element_arg,
		})

	return command
