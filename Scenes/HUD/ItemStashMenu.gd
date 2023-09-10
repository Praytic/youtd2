extends GridContainer


# This UI element displays items which are currently in the
# item stash. Note that adding/removing items from stash is
# implemented by ItemStash class.


func _ready():
	ItemStash.items_changed.connect(_on_item_stash_changed)
	_on_item_stash_changed()


func _on_item_stash_changed():
	for child in get_children():
		remove_child(child)

	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	var item_list: Array[Item] = item_stash_container.get_item_list()

	for item in item_list:
		_add_item_button(item)


func _add_item_button(item: Item):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.hide_cooldown_indicator()
	item_button.hide_auto_mode_indicator()
	item_button.hide_charges()

	var button_container = UnitButtonContainer.make()
	button_container.add_child(item_button)

	add_child(button_container)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_item_stash(item)
