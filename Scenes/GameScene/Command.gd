class_name Command


# Wraps Dictionaries which need to be passed through RPC.
# Need to pass Dictionaries through RPC because Godot RPC
# doesn't support passing custom classes. Need to wrap
# Dictionaries because handling Dictionaries directly is
# more error-prone. This wrapping method doesn't eliminate
# all errors - it is still possible to get errors about
# accessing invalid key of Dictionary if you pass a
# Dictionary to Command constructor with mismatched type.
# 
# Parameters -> Command:
#     var command: Command = CommandFoo.make(bar, baz)
#
# Command -> Dictionary:
#     var serialized_command: Dictionary = command.serialize()
# 
# Dictionary -> Command:
#     var command: CommandFoo = CommandFoo.new(serialized_command)
#     var bar: Bar = command.bar
#     var baz: Bar = command.baz


enum Field {
	TYPE,
	ELEMENT,
}

enum Type {
	NONE,
	IDLE,
	RESEARCH_ELEMENT,
}


var _data: Dictionary
var type: Command.Type:
	get:
		return _data[Command.Field.TYPE]


func _init(data: Dictionary):
	_data = data


func serialize() -> Dictionary:
	return _data


class Idle extends Command:
	static func make():
		var command: Command = Command.new({
			Command.Field.TYPE: Command.Type.IDLE,
			})

		return command


class ResearchElement extends Command:
	var element: Element.enm:
		get:
			return _data[Command.Field.ELEMENT]

	static func make(element_arg: Element.enm):
		var command: Command = Command.new({
			Command.Field.TYPE: Command.Type.RESEARCH_ELEMENT,
			Command.Field.ELEMENT: element_arg,
			})

		return command
