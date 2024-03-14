class_name ItemStash extends Node


# Container for managing items in main stash and horadric
# stash.

signal main_stash_changed()
signal horadric_stash_changed()

@export var _main_stash: ItemContainer
@export var _horadric_stash: ItemContainer


#########################
###       Public      ###
#########################

func get_items_in_main_stash() -> Array[Item]:
	return _main_stash.get_item_list()


func get_items_in_horadric_stash() -> Array[Item]:
	return _horadric_stash.get_item_list()


func add_item_to_main_stash(item: Item):
	_main_stash.add_item(item)


func add_tutorial_items():
	var item: Item = Item.make(80)
	var oil: Item = Item.make(1001)
	_main_stash.add_item(item)
	_main_stash.add_item(oil)


func get_main_container() -> ItemContainer:
	return _main_stash


func get_horadric_container() -> ItemContainer:
	return _horadric_stash


#########################
###     Callbacks     ###
#########################

func _on_main_stash_items_changed():
	main_stash_changed.emit()


func _on_horadric_stash_items_changed():
	horadric_stash_changed.emit()
