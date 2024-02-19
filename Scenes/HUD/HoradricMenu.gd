extends PanelContainer


const ITEMS_CONTAINER_BUTTON_SIZE = 100


# Menu for the Horadric Cube. Contains items inside it.
@export var _items_container: GridContainer
@export var _transmute_button: Button


#########################
###     Built-in      ###
#########################

func _ready():
	HoradricCube.items_changed.connect(_on_items_changed)
	_items_container.gui_input.connect(_on_items_container_gui_input)
	_items_container.child_entered_tree.connect(_on_items_container_child_entered_tree)
	
	HighlightUI.register_target("horadric_cube", self)
	self.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("horadric_cube"))
	
	_on_items_changed()


#########################
###     Callbacks     ###
#########################

func _on_items_container_child_entered_tree(node):
	node.custom_minimum_size = Vector2(ITEMS_CONTAINER_BUTTON_SIZE, ITEMS_CONTAINER_BUTTON_SIZE)


func _on_items_changed():
#	Clear current buttons
	for item_button in _items_container.get_children():
		item_button.queue_free()
	
#	Create buttons for new list
	var horadric_cube_container: ItemContainer = HoradricCube.get_item_container()
	var item_list: Array[Item] = horadric_cube_container.get_item_list()
	
	for item in item_list:
		var item_button: ItemButton = ItemButton.make(item)
		_items_container.add_child(item_button)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	
	var can_transmute: bool = HoradricCube.can_transmute()
	_transmute_button.set_disabled(!can_transmute)


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_horadric_cube(item)


func _on_items_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.horadric_menu_was_clicked()
