extends Control


var _tower: Tower = null

@onready var _button_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer
var _moved_item_button: ItemButton = null


func _ready():
	ItemMovement.item_move_from_tower_done.connect(_on_item_move_from_tower_done)

	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)

	_on_selected_unit_changed()


func _on_selected_unit_changed():
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit != null && selected_unit is Tower:
		set_tower(selected_unit)
		show()
	else:
		hide()


func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	var new_tower: Tower = tower
	_tower = new_tower

	if prev_tower != null:
		prev_tower.items_changed.disconnect(on_tower_items_changed)

	if new_tower != null:
		new_tower.items_changed.connect(on_tower_items_changed)
		on_tower_items_changed()


func on_tower_items_changed():
	for button in _button_container.get_children():
		button.queue_free()

	var items: Array[Item] = _tower.get_items()

	for item in items:
		var item_button: ItemButton = _create_item_button(item)
		_button_container.add_child(item_button)
		var actual_button: BaseButton = item_button.get_button()
		actual_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _create_item_button(item: Item) -> ItemButton:
	var item_button = load("res://Scenes/HUD/Buttons/ItemButton.tscn").instantiate() 
	item_button.set_item(item)
	return item_button


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	var started_move: bool = ItemMovement.start_move_from_tower(item)

	if !started_move:
		return

#	Disable button to gray it out to indicate that it's
#	getting moved
	item_button.set_disabled(true)
	_moved_item_button = item_button


func _on_item_move_from_tower_done(_success: bool):
	_moved_item_button.set_disabled(false)
	_moved_item_button = null
