class_name ItemContainerPanel extends MarginContainer


# Displays contents of an item container and allows moving items within container.
# Intended for item containers with limited capacity (tower inventory, horadric cube). Should not be used for item stash because it is
# scrollable and infinite.


var _item_container: ItemContainer = null


@export var _button_tooltip_location: ButtonTooltip.Location = ButtonTooltip.Location.BOTTOM
@export var show_slot_borders: bool = true
@export var _background_grid: GridContainer
@export var _foreground_grid: GridContainer


#########################
###       Public      ###
#########################

func set_item_container(item_container: ItemContainer):
	var prev_item_container: ItemContainer = _item_container
	_item_container = item_container

	if prev_item_container != null:
		prev_item_container.items_changed.disconnect(_on_items_changed)

	if _item_container != null:
		item_container.items_changed.connect(_on_items_changed)
		_load_items()
	else:
		_clear_item_buttons()


#########################
###      Private      ###
#########################

func _clear_item_buttons():
	var foreground_button_list: Array[Node] = _foreground_grid.get_children()
	for button in foreground_button_list:
		_foreground_grid.remove_child(button)
		button.queue_free()


func _load_items():
	_clear_item_buttons()
	
	if _item_container == null:
		return
	
	var inventory_capacity: int = _item_container.get_capacity()

	var item_container_is_tower_inventory: bool = _item_container is TowerItemContainer

	for index in range(0, inventory_capacity):
		var item: Item = _item_container.get_item_at_index(index)
		var slot_has_item: bool = item != null

		if slot_has_item:
			var item_button: ItemButton = ItemButton.make(item)
			if item_container_is_tower_inventory:
				item_button.show_cooldown_indicator()
				item_button.show_auto_mode_indicator()
				item_button.show_charges()
			item_button.set_tooltip_location(_button_tooltip_location)
			item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
			item_button.shift_right_clicked.connect(_on_item_button_shift_right_clicked.bind(item_button))
			item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))
		
			_foreground_grid.add_child(item_button)
		else:
			var slot_button: Button = Preloads.inventory_slot_button_scene.instantiate()
			
			var slot_button_color: Color
			if show_slot_borders:
				slot_button_color = Color.WHITE
			else:
				slot_button_color = Color.TRANSPARENT
			slot_button.modulate = slot_button_color

			slot_button.pressed.connect(_on_slot_button_pressed.bind(slot_button))
			_foreground_grid.add_child(slot_button)
	
#	Update color of background cells based on capacity
	var background_cell_list: Array[Node] = _background_grid.get_children()
	for i in range(0, background_cell_list.size()):
		var background_cell: Control = background_cell_list[i] as Control
		var within_capacity: bool = i < inventory_capacity
	
		var background_color: Color
		if within_capacity:
			background_color = Color.WHITE
		else:
			background_color = Color.WHITE.darkened(0.6)
		background_cell.modulate = background_color


func _process_click_on_generic_button(button: Button):
	var clicked_index: int = button.get_index()
	EventBus.player_clicked_in_item_container.emit(_item_container, clicked_index)


#########################
###     Callbacks     ###
#########################

func _on_items_changed():
	_load_items()


func _on_item_button_pressed(item_button: ItemButton):
	_process_click_on_generic_button(item_button)


func _on_slot_button_pressed(button: Button):
	_process_click_on_generic_button(button)


func _on_item_button_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_right_clicked_item.emit(item)


func _on_item_button_shift_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_shift_right_clicked_item.emit(item)

