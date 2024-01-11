extends Node


# This class represents the item stash. It stores items and
# allows adding/removing items.


signal items_changed()


var _item_container: ItemContainer


#########################
###     Built-in      ###
#########################

func _ready():
	_item_container = ItemContainer.new(10000)
	add_child(_item_container)
	_item_container.items_changed.connect(_on_item_container_items_changed)
	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)

	var test_item_list: Array = Config.test_item_list()

	for item_id in test_item_list:
		var item: Item = Item.make(item_id)
		_item_container.add_item(item)
	
	items_changed.emit()


#########################
###       Public      ###
#########################

func get_item_container() -> ItemContainer:
	return _item_container


#########################
###     Callbacks     ###
#########################

func _on_item_container_items_changed():
	items_changed.emit()


func _on_game_mode_was_chosen():
	# Adds two common items to player's inventory during the tutorial section
	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		var item: Item = Item.make(80)
		var oil: Item = Item.make(1001)
		_item_container.add_item(item)
		_item_container.add_item(oil)
