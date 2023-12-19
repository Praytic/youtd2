# ItemStashMenu
extends PanelContainer


# This UI element displays items which are currently in the
# item stash. Note that adding/removing items from stash is
# implemented by ItemStash class.
@export var _rarity_filter_container: VBoxContainer
@export var _item_type_filter_container: VBoxContainer
@export var _item_buttons_container: GridContainer

@onready var _empty_slots: Array = _item_buttons_container.get_children()

var _prev_item_list: Array[Item] = []
var _item_button_list: Array[ItemButton] = []


#########################
### Code starts here  ###
#########################

func _ready():
	_rarity_filter_container.filter_changed.connect(_on_item_stash_changed)
	_item_type_filter_container.filter_changed.connect(_on_item_stash_changed)
	ItemStash.items_changed.connect(_on_item_stash_changed)
	_on_item_stash_changed()


#########################
###       Public      ###
#########################


#########################
###      Private      ###
#########################

func _add_item_button(item: Item, index: int):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.add_to_group("item_button")

	_item_button_list.append(item_button)
	_item_buttons_container.add_child(item_button)
	_item_buttons_container.move_child(item_button, index)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _fill_item_buttons_container_with_empty_slots():
	var columns = _item_buttons_container.columns
	var items = _item_button_list.size()
	var rows = ceil((items * 1.0) / columns)
	
	for empty_slot_idx in range(_empty_slots.size()):
		var current_slot: EmptyUnitButton = _empty_slots[empty_slot_idx]
		var slot_visibility = empty_slot_idx < max(columns * rows, _empty_slots.size()) - items
		current_slot.visible = slot_visibility

#########################
###     Callbacks     ###
#########################

# NOTE: need to update buttons selectively to minimuze the
# amount of times buttons are created/destroyed and avoid
# perfomance issues for large item counts. A simpler
# approach would be to remove all buttons and then go
# through the item list and add new buttons but that causes
# perfomance issues.
func _on_item_stash_changed():
	var rarity_filter = _rarity_filter_container.get_filter()
	var item_type_filter = _item_type_filter_container.get_filter()
	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	var item_list: Array[Item] = item_stash_container.get_item_list(rarity_filter, item_type_filter)

# 	Remove buttons for items which were removed from stash
	var removed_button_list: Array[ItemButton] = []

	for button in _item_button_list:
		var item: Item = button.get_item()
		var item_was_removed: bool = !item_list.has(item)

		if item_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		_item_buttons_container.remove_child(button)
		button.queue_free()
		_item_button_list.erase(button)

# 	Add buttons for items which were added to stash
#	NOTE: preserve the same order as in the stash
	for i in range(0, item_list.size()):
		var item: Item = item_list[i]
		var item_was_added: bool = !_prev_item_list.has(item)

		if item_was_added:
			_add_item_button(item, i)

	_prev_item_list = item_list.duplicate()
	
	_fill_item_buttons_container_with_empty_slots()


func _on_item_buttons_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.item_stash_was_clicked()


func _on_transmute_button_pressed():
	HoradricCube.transmute()


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_item_stash(item)


func _on_rebrew_button_pressed():
	HoradricCube.autofill_recipe(HoradricCube.Recipe.TWO_OILS_OR_CONSUMABLES)


func _on_distill_button_pressed():
	HoradricCube.autofill_recipe(HoradricCube.Recipe.FOUR_OILS_OR_CONSUMABLES)


func _on_reassemble_button_pressed():
	HoradricCube.autofill_recipe(HoradricCube.Recipe.THREE_ITEMS)


func _on_perfect_button_pressed():
	HoradricCube.autofill_recipe(HoradricCube.Recipe.FIVE_ITEMS)


func _on_close_button_pressed():
	hide()


#########################
### Setters / Getters ###
#########################
