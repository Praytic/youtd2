class_name ItemContainerPanel extends MarginContainer


# Displays contents of an item container and allows moving items within container.
# Intended for item containers with limited capacity (tower inventory, horadric cube). Should not be used for item stash because it is
# scrollable and infinite.


var _item_container: ItemContainer = null


@export var _button_tooltip_location: ButtonTooltip.Location = ButtonTooltip.Location.BOTTOM
@export var show_slot_borders: bool = true
@export var _show_horadric_lock: bool = true
@export var _background_grid: GridContainer
@export var _slot_grid: GridContainer
@export var _item_grid: GridContainer


#########################
###     Built-in      ###
#########################

func _ready():
	var item_button_list: Array[Node] = _item_grid.get_children()
	for button in item_button_list:
#		NOTE: show button, it's hidden in scene so that it doesn't animate in editor
		button.show()
		
		button.set_tooltip_location(_button_tooltip_location)
		button.set_horadric_lock_visible(_show_horadric_lock)
		button.pressed.connect(_on_item_button_pressed.bind(button))
		button.shift_right_clicked.connect(_on_item_button_shift_right_clicked.bind(button))
		button.right_clicked.connect(_on_item_button_right_clicked.bind(button))
		var item_button = button as ItemButton
		item_button.ctrl_right_clicked.connect(_on_item_button_ctrl_right_clicked.bind(item_button))

	var slot_button_list: Array[Node] = _slot_grid.get_children()
	for button in slot_button_list:
		if !show_slot_borders:
			button.modulate = Color.TRANSPARENT

	_update_buttons()


#########################
###       Public      ###
#########################

func set_item_container(item_container: ItemContainer):
	var prev_item_container: ItemContainer = _item_container
	_item_container = item_container
	
	var item_container_is_tower_inventory: bool = _item_container != null && _item_container is TowerItemContainer
	
	var item_button_list: Array = _item_grid.get_children()
	for button in item_button_list:
		button.set_cooldown_indicator_visible(true)
		button.set_auto_mode_indicator_visible(item_container_is_tower_inventory)
		button.set_charges_visible(true)
	
	if prev_item_container != null:
		prev_item_container.items_changed.disconnect(_on_items_changed)

	if _item_container != null:
		item_container.items_changed.connect(_on_items_changed)
	
	_update_buttons()


#########################
###      Private      ###
#########################

func _on_item_button_ctrl_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	item.toggle_horadric_lock()


func _update_buttons():
	var inventory_capacity: int
	if _item_container != null:
		inventory_capacity = _item_container.get_capacity()
	else:
		inventory_capacity = 0

#	Update color of background cells based on capacity
	var background_button_list: Array[Node] = _background_grid.get_children()
	for background_button in background_button_list:
		var index: int = background_button.get_index()
		var within_capacity: bool = index < inventory_capacity
	
		var background_color: Color
		if within_capacity:
			background_color = Color.WHITE
		else:
			background_color = Color.WHITE.darkened(0.6)
		
		background_button.modulate = background_color

	var slot_button_list: Array[Node] = _slot_grid.get_children()
	for slot_button in slot_button_list:
		var slot_is_within_capacity: bool = slot_button.get_index() < inventory_capacity
		slot_button.visible = slot_is_within_capacity

	var item_button_list: Array[Node] = _item_grid.get_children()
	for item_button in item_button_list:
		var index: int = item_button.get_index()

		var item: Item
		if _item_container != null:
			item = _item_container.get_item_at_index(index)
		else:
			item = null

		item_button.set_item(item)
	

func _process_click_on_generic_button(button: Button):
	var clicked_index: int = button.get_index()
	EventBus.player_clicked_in_item_container.emit(_item_container, clicked_index)


#########################
###     Callbacks     ###
#########################

func _on_items_changed():
	_update_buttons()


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
