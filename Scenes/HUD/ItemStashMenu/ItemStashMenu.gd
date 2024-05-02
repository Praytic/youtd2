class_name ItemStashMenu extends PanelContainer



# This UI element displays items which are currently in the
# item stash.
@export var _rarity_filter_container: VBoxContainer
@export var _item_type_filter_container: VBoxContainer
@export var _item_buttons_container: UnitButtonsContainer

@export var _backpacker_recipes: GridContainer
@export var _horadric_menu: HoradricMenu

var _prev_item_list: Array[Item] = []
var _item_button_list: Array[ItemButton] = []


#########################
### Code starts here  ###
#########################

func _ready():
	HighlightUI.register_target("item_stash", _item_buttons_container)
	HighlightUI.register_target("item_placed_inside_tower", _item_buttons_container)
	_item_buttons_container.mouse_entered.connect(func(): EventBus.player_performed_tutorial_advance_action.emit("mouse_over_item_stash"))

	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(recipe))


#########################
###       Public      ###
#########################

# NOTE: need to update buttons selectively to minimuze the
# amount of times buttons are created/destroyed and avoid
# perfomance issues for large item counts. A simpler
# approach would be to remove all buttons and then go
# through the item list and add new buttons but that causes
# perfomance issues.
func set_items(item_list: Array[Item]):
# 	Remove buttons for items which were removed from stash
	var removed_button_list: Array[ItemButton] = []

	for button in _item_button_list:
		var item: Item = button.get_item()
		var item_was_removed: bool = !item_list.has(item)

		if item_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		var item: Item = button.get_item()
		item.horadric_lock_changed.disconnect(_on_item_horadric_lock_changed)

		_item_buttons_container.remove_child(button)
		button.queue_free()
		_item_button_list.erase(button)

# 	Add buttons for items which were added to stash
#	NOTE: preserve the same order as in the stash
	for i in range(0, item_list.size()):
		var item: Item = item_list[i]
		var item_was_added: bool = !_prev_item_list.has(item)

		if item_was_added:
			_add_item_button(item, i)
			item.horadric_lock_changed.connect(_on_item_horadric_lock_changed)

	_prev_item_list = item_list.duplicate()
	
	_load_current_filter()
	_update_autofill_buttons()


func set_items_for_horadric_cube(item_list: Array[Item]):
	_horadric_menu.set_items(item_list)


#########################
###      Private      ###
#########################

func _add_item_button(item: Item, index: int):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.enable_horadric_lock_display()
	_item_button_list.append(item_button)
	_item_buttons_container.add_child(item_button)
	_item_buttons_container.move_child(item_button, index)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))
	item_button.ctrl_right_clicked.connect(_on_item_button_ctrl_right_clicked.bind(item_button))


func _load_current_filter():
#	Show/hide item buttons depending on whether they match
#	current filter
	var rarity_filter: Array = _rarity_filter_container.get_filter()
	var item_type_filter: Array = _item_type_filter_container.get_filter()

	for item_button in _item_button_list:
		var item: Item = item_button.get_item()
		var rarity: Rarity.enm = item.get_rarity()
		var item_type: ItemType.enm = item.get_item_type()
		var rarity_match: bool = rarity_filter.has(rarity) || rarity_filter.is_empty()
		var item_type_match: bool = item_type_filter.has(item_type) || item_type_filter.is_empty()
		var filter_match: bool = rarity_match && item_type_match
		
		item_button.visible = filter_match

	var visible_item_list: Array[Item] = _get_visible_item_list()
	var visible_count: int = visible_item_list.size()
	_item_buttons_container.update_empty_slots(visible_count)


# Enable/disable autofill buttons based on which items are
# currently available for autofill
func _update_autofill_buttons():
	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	var visible_item_list: Array[Item] = _get_visible_item_list()
	
	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		var autofill_is_possible: bool = HoradricCube.has_recipe_ingredients(recipe, visible_item_list)
		
		recipe_button.disabled = !autofill_is_possible


func _get_visible_item_list() -> Array[Item]:
	var list: Array[Item] = []

	for item_button in _item_button_list:
		if item_button.visible:
			var item: Item = item_button.get_item()
			list.append(item)

	return list


#########################
###     Callbacks     ###
#########################

func _on_item_buttons_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		EventBus.player_clicked_main_stash.emit()


func _on_transmute_button_pressed():
	EventBus.player_requested_transmute.emit()


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_clicked_item_in_main_stash.emit(item)


func _on_item_button_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_right_clicked_item_in_item_stash.emit(item)


func _on_item_button_ctrl_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	item.toggle_horadric_lock()


func _on_recipe_button_pressed(recipe: HoradricCube.Recipe):
	var rarity_filter: Array = _rarity_filter_container.get_filter()
	EventBus.player_requested_autofill.emit(recipe, rarity_filter)


func enable_extra_recipes():
	_backpacker_recipes.show()


func _on_close_button_pressed():
	hide()


func _on_rarity_filter_container_filter_changed():
	_load_current_filter()
	_update_autofill_buttons()


func _on_item_type_filter_container_filter_changed():
	_load_current_filter()
	_update_autofill_buttons()


# NOTE: need to update recipe buttons when an item locked
# state changes because that changes the item list for
# autofill
func _on_item_horadric_lock_changed():
	_update_autofill_buttons()
