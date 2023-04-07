extends GridContainer


@export var unlimited_items = false

@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
# Dictionary of all in-game items with the associated buttons
@onready var _item_buttons: Dictionary = {}
# Adds every item button possible to the list.
# Although, this is a mutable list, so every time
# you use an item, the ID of the item is removed from this list.
# If you want unlimited item buttons in the panel, switch the flag
# 'unlimited items' to 'true'.
@onready var available_item_buttons: Array


var current_element: Tower.Element
var current_size: String


func add_item_button(item_id):
	available_item_buttons.append(item_id)
	_item_buttons[item_id].show()


func remove_item_button(item_id):
	available_item_buttons.erase(item_id)
	_item_buttons[item_id].hide()


func _ready():
	if not unlimited_items:
		item_control.item_used.connect(_on_Item_used)
		
	for item_id in Properties.get_item_id_list():
		var item_button = _create_ItemButton(item_id)
		if item_button:
			_item_buttons[item_id] = item_button
			item_button.hide()
			add_child(item_button)
	
	for item_id in _item_buttons.keys():
		available_item_buttons.append(item_id)
	
	_resize_icons("M")
	current_size = "M"

	if FF.add_test_item():
		add_item_button(108)


func _on_RightMenuBar_element_changed(element: Tower.Element):
	if element != Tower.Element.NONE:
		# Towers menu bar was selected
		return
	
	for item_button in _item_buttons.values():
		item_button.hide()
	
	if current_size == "M":
		if available_item_buttons.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")
	elif current_size == "S":
		if available_item_buttons.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")
	
	for item_id in available_item_buttons:
		_item_buttons[item_id].show()


func _create_ItemButton(item_id) -> ItemButton:
	var item_button = ItemButton.new()
	var item = Item.make(item_id)
	item_button.set_item(item)
	item_button.button_down.connect(Callable(item_control, "_on_ItemButton_button_down").bind(item_id))
	return item_button


func _on_Item_used(item_id):
	remove_item_button(item_id)


func _resize_icons(icon_size: String):
	current_size = icon_size
	if icon_size == "M":
		columns = 2
	else:
		columns = 4
	for item_id in _item_buttons.keys():
		_item_buttons[item_id].set_icon_size(icon_size)
