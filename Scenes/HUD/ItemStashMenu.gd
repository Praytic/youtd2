extends GridContainer


# This UI element displays items which are currently in the
# item stash. Note that adding/removing items from stash is
# implemented by ItemStash class.


var _prev_item_list: Array[Item] = []
var _item_button_list: Array[ItemButton] = []


func _ready():
	ItemStash.items_changed.connect(_on_item_stash_changed)
	_on_item_stash_changed()


# NOTE: need to update buttons selectively to minimuze the
# amount of times buttons are created/destroyed and avoid
# perfomance issues for large item counts. A simpler
# approach would be to remove all buttons and then go
# through the item list and add new buttons but that causes
# perfomance issues.
func _on_item_stash_changed():
	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	var item_list: Array[Item] = item_stash_container.get_item_list()

# 	Remove buttons for items which were removed from stash
	var removed_button_list: Array[ItemButton] = []

	for button in _item_button_list:
		var item: Item = button.get_item()
		var item_was_removed: bool = !item_list.has(item)

		if item_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		var button_container: Node = button.get_parent()
		remove_child(button_container)
		_item_button_list.erase(button)

# 	Add buttons for items which were added to stash
#	NOTE: preserve the same order as in the stash
	for i in range(0, item_list.size()):
		var item: Item = item_list[i]
		var item_was_added: bool = !_prev_item_list.has(item)

		if item_was_added:
			_add_item_button(item, i)

	_prev_item_list = item_list.duplicate()


func _add_item_button(item: Item, index: int):
	var item_button: ItemButton = ItemButton.make(item)

	var button_container = UnitButtonContainer.make()
	button_container.add_child(item_button)
	_item_button_list.append(item_button)

	add_child(button_container)
	move_child(button_container, index)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_item_stash(item)
