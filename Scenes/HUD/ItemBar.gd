extends GridContainer


# Dictionary of buttons that are currently on the item bar
@onready var _item_buttons: Dictionary = {}


var _moved_item_button: ItemButton = null


func add_item_button(item: Item):
	var item_button: ItemButton = _create_ItemButton(item)
	add_child(item_button)
	_item_buttons[item] = item_button


func remove_item_button(item: Item):
	var item_button: ItemButton = _item_buttons[item]
	_item_buttons.erase(item)
	item_button.queue_free()


func _ready():
	if Config.add_test_item():
		var test_item_list: Array[int] = [77, 78, 79, 99, 105, 108, 155, 158, 159, 218, 231, 244, 249, 268, 274, 1001]

		for item_id in test_item_list:
			var item: Item = Item.make(item_id)
			add_item_button(item)

	ItemMovement.item_move_from_itembar_done.connect(on_item_move_from_itembar_done)
	ItemMovement.item_moved_to_itembar.connect(on_item_moved_to_itembar)
	EventBus.item_drop_picked_up.connect(_on_item_drop_picked_up)


func on_item_moved_to_itembar(item: Item):
	add_item_button(item)


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


func _create_ItemButton(item: Item) -> ItemButton:
	var item_button = ItemButton.new()
	item_button.set_item(item)
#	NOTE: attach item to button while item is stored in item
#	bar.
	item_button.add_child(item)
	item_button.button_down.connect(_on_item_button_pressed.bind(item_button))
	return item_button


func _on_item_drop_picked_up(item: Item):
	add_item_button(item)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.start_move_from_itembar(item)
	_moved_item_button = item_button
	item_button.set_disabled(true)
	item_button.set_pressed_no_signal(true)
