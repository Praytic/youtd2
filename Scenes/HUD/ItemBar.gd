extends GridContainer


# This UI element displays items which are currently in the
# item stash. Note that adding/removing items from stash is
# implemented by ItemStash class.


# TODO: reimplement movement between item stash and horadric
# cube


func _add_item_button(item: Item):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.hide_cooldown_indicator()

	var button_container = UnitButtonContainer.make()
	button_container.add_child(item_button)

	add_child(button_container)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _ready():
	HoradricCube.item_was_removed.connect(_on_horadric_cube_item_was_removed)

	ItemStash.changed.connect(_on_item_stash_changed)
	_on_item_stash_changed()


func _on_item_stash_changed():
	for child in get_children():
		remove_child(child)

	var item_list: Array[Item] = ItemStash.get_item_list()

	for item in item_list:
		_add_item_button(item)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_item_stash(item)


func _on_horadric_cube_item_was_removed(item: Item):
	_add_item_button(item)
