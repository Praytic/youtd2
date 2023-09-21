extends PanelContainer


# Menu for the Horadric Cube. Contains items inside it.
@export var _items_container: GridContainer
@export var _transmute_button: Button
# TODO: Current implementation doesn't allow to easily add resulted
# transmutation to any EmptySlotButton.
@export var _result_slot: EmptySlotButton
# Shows the status of transmutation. E.g. ("Transmute was unlucky: -16 levels")
@export var _transmute_result_label: RichTextLabel : get = get_transmute_result_label
@export var _main_container: VBoxContainer
@export var _title_button: Button


func _ready():
	HoradricCube.items_changed.connect(_on_items_changed)
	_main_container.visibility_changed.connect(_on_visibility_changed)
	_title_button.toggled.connect(_on_title_button_toggled)
	
	_on_items_changed()
	_main_container.hide()


func is_visibility_mode_expanded() -> bool:
	return _main_container.visible


func get_transmute_result_label() -> RichTextLabel:
	return _transmute_result_label


func _on_visibility_changed():
	if not visible:
		_transmute_result_label.text = "[center][color=GRAY]Place ingridients here[/color][/center]"


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
			var empty_button: EmptySlotButton = EmptySlotButton.make()
			unit_button_container.add_child(empty_button)
			empty_button.pressed.connect(_on_empty_button_pressed.bind(i))
	
	var can_transmute: bool = HoradricCube.can_transmute()
	_transmute_button.set_disabled(!can_transmute)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_horadric_cube(item)


func _on_transmute_button_pressed():
	_transmute_result_label.text = HoradricCube.transmute()


func _on_empty_button_pressed(add_index: int):
	ItemMovement.horadric_menu_was_clicked(add_index)


func _on_title_button_toggled(toggle: bool):
	if toggle:
		_main_container.show()
		_title_button.get_parent().set_h_size_flags(SIZE_SHRINK_CENTER)
	else:
		_main_container.hide()
		_title_button.get_parent().set_h_size_flags(SIZE_SHRINK_END)
	
	if toggle:
		for button in _title_button.button_group.get_buttons():
			button.hide()
		_title_button.show()
	else:
		for button in _title_button.button_group.get_buttons():
			button.show()
