extends PanelContainer


# Menu for the Horadric Cube. Contains items inside it.
@export var _items_container: GridContainer
@export var _transmute_button: Button
@export var _main_container: VBoxContainer


func _ready():
	HoradricCube.items_changed.connect(_on_items_changed)
	_items_container.gui_input.connect(_on_items_container_gui_input)
	
	_on_items_changed()


func _on_items_changed():
#	Clear current buttons
	var unit_button_containers = get_tree().get_nodes_in_group("item_button_container")
	for unit_button_container in unit_button_containers:
		for unit_button in unit_button_container.get_children():
			unit_button.queue_free()
	
#	Create buttons for new list
	var horadric_cube_container: ItemContainer = HoradricCube.get_item_container()
	var item_list: Array[Item] = horadric_cube_container.get_item_list()
	
	for i in len(unit_button_containers):
		var unit_button_container = unit_button_containers[i]
		if item_list.size() > i:
			var item_button: ItemButton = ItemButton.make(item_list[i])
			unit_button_container.add_child(item_button)
			item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
		else:
			unit_button_container.add_child(EmptyUnitButton.make())
	
	var can_transmute: bool = HoradricCube.can_transmute()
	_transmute_button.set_disabled(!can_transmute)


func _on_transmute_button_pressed():
	HoradricCube.transmute()


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_horadric_cube(item)


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.horadric_menu_was_clicked()
