class_name Action


# Wraps Dictionary which needs to be passed through RPC.
# Need to pass Dictionaries through RPC because Godot RPC
# doesn't support passing custom classes.
# 
# Parameters -> Action:
#     var action: Action = ActionFoo.make(bar, baz)
#
# Action -> Dictionary:
#     var serialized_action: Dictionary = action.serialize()


enum Field {
	TYPE,
	PLAYER_ID,
	CHAT_MESSAGE,
	TOWER_ID,
	POSITION,
	UID,
	UID_2,
	UID_LIST,
	BUILDER_ID,
	SRC_ITEM_CONTAINER_UID,
	DEST_ITEM_CONTAINER_UID,
	BUFFGROUP,
	BUFFGROUP_MODE,
	ELEMENT,
	WISDOM_UPGRADES,
}

enum Type {
	NONE,
	IDLE,
	CHAT,
	BUILD_TOWER,
	UPGRADE_TOWER,
	TRANSFORM_TOWER,
	SELL_TOWER,
	SELECT_BUILDER,
	SELECT_WISDOM_UPGRADES,
	TOGGLE_AUTOCAST,
	CONSUME_ITEM,
	DROP_ITEM,
	MOVE_ITEM,
	SWAP_ITEMS,
	AUTOFILL,
	TRANSMUTE,
	RESEARCH_ELEMENT,
	ROLL_TOWERS,
	START_NEXT_WAVE,
	AUTOCAST,
	FOCUS_TARGET,
	CHANGE_BUFFGROUP,
}


var _data: Dictionary


#########################
###     Built-in      ###
#########################

func _init(data: Dictionary):
	_data = data


#########################
###       Public      ###
#########################

func serialize() -> Dictionary:
	return _data
