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


var current_element: int
var current_size: String


func add_item_button(item_id):
	available_item_buttons.append(item_id)
	_item_buttons[item_id].show()


func remove_item_button(item_id):
	available_item_buttons.erase(item_id)
	_item_buttons[item_id].hide()


func _ready():
	if not unlimited_items:
		item_control.connect("item_used",Callable(self,"_on_Item_used"))
		
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


func _on_RightMenuBar_element_changed(element: int):
	for item_button in _item_buttons.values():
		item_button.hide()
	
	if element != -1:
		# Towers menu bar was selected
		return
	
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
	var item = ItemManager.get_item(item_id)
	item_button.set_item(item)
	item_button.connect("pressed",Callable(item_control,"_on_ItemButton_pressed").bind(item_id))
	return item_button


func _on_ItemButton_mouse_entered(item_id):
	emit_signal("item_info_requested", item_id)


func _on_ItemButton_mouse_exited(_item_id):
	emit_signal("item_info_canceled")


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
