extends GridContainer


# Dictionary of buttons that are currently on the item bar
# Buttons should be always created inside a dedicated container,
# which means you should call the parent of a button
# if you want to change the visual part of it.
@onready var _item_buttons: Dictionary = {}


var _moved_item_button: ItemButton = null


func add_item_button(item: Item):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.hide_cooldown_indicator()

	var button_container = UnitButtonContainer.make()
	button_container.add_child(item_button)

#	NOTE: Parent item to ItemBar because while the item is
#	not on a tower it still needs to be in the scene tree.
#	This is so that it's cooldown timer is running.
	add_child(item)
		
	add_child(button_container)
	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	_item_buttons[item] = item_button


func remove_item_button(item: Item):
	var item_button: ItemButton = _item_buttons[item]
	_item_buttons.erase(item)
	item_button.get_parent().queue_free()


func _ready():
	if Config.add_test_item():
		var test_item_list: Array[int] = [285, 77, 78, 79, 99, 105, 108, 155, 158, 159, 218, 231, 244, 249, 268, 274, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1022, 1023, 1024]

		for item_id in test_item_list:
			var item: Item = Item.make(item_id)
			add_item_button(item)

	ItemMovement.item_move_from_itembar_done.connect(on_item_move_from_itembar_done)
	EventBus.item_drop_picked_up.connect(_on_item_drop_picked_up)
	EventBus.consumable_item_was_consumed.connect(_on_consumable_item_was_consumed)


func on_item_move_from_itembar_done(move_success: bool):
	if _moved_item_button == null:
		return

	if move_success:
		var item: Item = _moved_item_button.get_item()
		_item_buttons.erase(item)
		_moved_item_button.queue_free()
	else:
#		Disable button to gray it out to indicate that it's
#		getting moved
		_moved_item_button.set_disabled(false)

	_moved_item_button = null


func _on_item_drop_picked_up(item: Item):
	add_item_button(item)


func _on_consumable_item_was_consumed(item: Item):
	remove_item_button(item)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()

	var item_type: ItemType.enm = ItemProperties.get_type(item.get_id())
	var can_move: bool = item_type != ItemType.enm.CONSUMABLE

	if !can_move:
		Messages.add_error("Can't add consumable items to towers.")

		return

	var started_move: bool = ItemMovement.start_move_from_itembar(item)

	if !started_move:
		return

	_moved_item_button = item_button
	item_button.set_disabled(true)
	item_button.set_pressed_no_signal(true)


func get_item_count() -> int:
	return _item_buttons.size()
