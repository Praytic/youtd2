extends PanelContainer


# Menu for the Horadric Cube. Contains items inside it.
@export var _slots_container: HBoxContainer
@export var _items_container: HBoxContainer
@export var _transmute_button: Button


func _ready():
	for i in range(0, HoradricCube.CAPACITY):
		var empty_slot_button: EmptySlotButton = EmptySlotButton.make()
		empty_slot_button.theme_type_variation = "SmallButton"
		_slots_container.add_child(empty_slot_button)

	HoradricCube.items_changed.connect(_on_items_changed)
	_on_items_changed()


func _on_items_changed():
#	Clear current buttons
	var old_button_list: Array = _items_container.get_children()
	for old_button in old_button_list:
		old_button.queue_free()

#	Create buttons for new list
	var item_list: Array[Item] = HoradricCube.get_items()
	for item in item_list:
		var item_button: ItemButton = ItemButton.make(item)
		item_button.theme_type_variation = "SmallButton"
		var button_container: UnitButtonContainer = UnitButtonContainer.make()
		button_container.add_child(item_button)
		_items_container.add_child(button_container)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	
	var can_transmute: bool = HoradricCube.can_transmute()
	_transmute_button.set_disabled(!can_transmute)


func _on_item_button_pressed(item_button: ItemButton):
	var shift_pressed: bool = Input.is_action_pressed("shift")
	var item: Item = item_button.get_item()

	if shift_pressed:
		HoradricCube.remove_item(item)


func _on_transmute_button_pressed():
	HoradricCube.transmute()


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.horadric_menu_was_clicked()
