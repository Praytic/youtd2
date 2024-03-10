class_name ItemStash extends Node


# Container for managing items in main stash and horadric
# stash.

signal main_stash_changed()
signal horadric_stash_changed()

@export var _main_stash: ItemContainer
@export var _horadric_stash: ItemContainer


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.player_requested_transmute.connect(_on_player_requested_transmute)
	EventBus.player_requested_autofill.connect(_on_player_requested_autofill)
	PregameSettings.finalized.connect(_on_pregame_settings_finalized)
	
	var test_item_list: Array = Config.test_item_list()

	for item_id in test_item_list:
		var item: Item = Item.make(item_id)
		_main_stash.add_item(item)


#########################
###       Public      ###
#########################

func get_items_in_main_stash() -> Array[Item]:
	return _main_stash.get_item_list()


func get_items_in_horadric_stash() -> Array[Item]:
	return _horadric_stash.get_item_list()


func get_main_stash_container() -> ItemContainer:
	return _main_stash


func get_horadric_stash_container() -> ItemContainer:
	return _horadric_stash


#########################
###     Callbacks     ###
#########################

func _on_pregame_settings_finalized():
	var tutorial_enabled: bool = PregameSettings.get_tutorial_enabled()
		
	if tutorial_enabled:
		var item: Item = Item.make(80)
		var oil: Item = Item.make(1001)
		_main_stash.add_item(item)
		_main_stash.add_item(oil)


func _on_player_requested_autofill(recipe: HoradricCube.Recipe, rarity_filter: Array):
# 	Return current cube contents to item stash. Need to do this first in all cases, doesn't matter if autofill suceeeds or fails later.
	var horadric_items_initial: Array[Item] = _horadric_stash.get_item_list()
	for item in horadric_items_initial:
		_horadric_stash.remove_item(item)
		_main_stash.add_item(item)

#	Move items from item stash to cube, if there are enough
#	items for the recipe
	var item_list: Array[Item] = _main_stash.get_item_list()
	var autofill_list: Array[Item] = HoradricCube.autofill_recipe(item_list, recipe, rarity_filter)
	
	var can_autofill: bool = !autofill_list.is_empty()
	
	if !can_autofill:
		Messages.add_error("Not enough items for recipe!")
		
		return

#	Move autofill items from item stash to horadric stash
	for item in autofill_list:
		_main_stash.remove_item(item)
		_horadric_stash.add_item(item)


func _on_player_requested_transmute():
	var item_list: Array[Item] = _horadric_stash.get_item_list()
	var result_list: Array[Item] = HoradricCube.transmute(item_list)
	
	for item in item_list:
		_horadric_stash.remove_item(item)
	
	for item in result_list:
		_horadric_stash.add_item(item)


func _on_main_stash_items_changed():
	main_stash_changed.emit()


func _on_horadric_stash_items_changed():
	horadric_stash_changed.emit()
