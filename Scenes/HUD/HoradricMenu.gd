extends PanelContainer


# Menu for the Horadric Cube. Contains items inside it.
@export var _slots_container: GridContainer
@export var _items_container: GridContainer
@export var _transmute_button: Button


func _ready():
	HoradricCube.items_changed.connect(_on_items_changed)
	_on_items_changed()


func _on_items_changed():
#	Clear current buttons
	var old_button_list: Array = _items_container.get_children()
	for old_button in old_button_list:
		old_button.queue_free()

#	Create buttons for new list
	var horadric_cube_container: ItemContainer = HoradricCube.get_item_container()
	var item_list: Array[Item] = horadric_cube_container.get_item_list()
	for item in item_list:
		var item_button: ItemButton = ItemButton.make(item)
		var button_container: UnitButtonContainer = UnitButtonContainer.make()
		button_container.add_child(item_button)
		_items_container.add_child(button_container)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	
	var can_transmute: bool = HoradricCube.can_transmute()
	_transmute_button.set_disabled(!can_transmute)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_horadric_cube(item)


func _on_transmute_button_pressed():
	HoradricCube.transmute()


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.horadric_menu_was_clicked()
