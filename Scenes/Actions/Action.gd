class_name Action


# Wraps Dictionaries which need to be passed through RPC.
# Need to pass Dictionaries through RPC because Godot RPC
# doesn't support passing custom classes. Need to wrap
# Dictionaries because handling Dictionaries directly is
# more error-prone. This wrapping method doesn't eliminate
# all errors - it is still possible to get errors about
# accessing invalid key of Dictionary if you pass a
# Dictionary to Action constructor with mismatched type.
# 
# Parameters -> Action:
#     var action: Action = ActionFoo.make(bar, baz)
#
# Action -> Dictionary:
#     var serialized_action: Dictionary = action.serialize()
# 
# Dictionary -> Action:
#     var action: ActionFoo = ActionFoo.new(serialized_action)
#     var bar: Bar = action.bar
#     var baz: Bar = action.baz


enum Field {
	TYPE,
	CHAT_MESSAGE,
	TOWER_ID,
	POSITION,
	UID,
	BUILDER_ID,
	SRC_ITEM_CONTAINER_UID,
	DEST_ITEM_CONTAINER_UID,
	AUTOFILL_RECIPE,
	AUTOFILL_RARITY_FILTER,
}

enum Type {
	NONE,
	IDLE,
	CHAT,
	BUILD_TOWER,
	TRANSFORM_TOWER,
	SELL_TOWER,
	SELECT_BUILDER,
	TOGGLE_AUTOCAST,
	CONSUME_ITEM,
	DROP_ITEM,
	MOVE_ITEM,
	AUTOFILL,
	TRANSMUTE,
}


var _data: Dictionary
var type: Action.Type:
	get:
		return _data[Action.Field.TYPE]


func _init(data: Dictionary):
	_data = data


func serialize() -> Dictionary:
	return _data
