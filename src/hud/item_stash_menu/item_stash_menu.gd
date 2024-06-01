class_name ItemStashMenu extends PanelContainer


# NOTE: these are visible counts, not total possible counts
const ITEM_STASH_ROW_COUNT: int = 4
const ITEM_STASH_COLUMN_COUNT: int = 5


# This UI element displays items which are currently in the
# item stash.
@export var _rarity_filter: RarityFilter
@export var _item_type_filter_container: VBoxContainer
@export var _background_grid: GridContainer
@export var _foreground_grid: GridContainer

@export var _backpacker_recipes: GridContainer
@export var _horadric_item_container_panel: ItemContainerPanel
@export var _transmute_button: Button


#########################
### Code starts here  ###
#########################

func _ready():
	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(recipe))
		
#		NOTE: recipe buttons start out disabled until items
#		are added to item stash
		recipe_button.disabled = true


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	_horadric_item_container_panel.set_item_container(horadric_stash)
	
	horadric_stash.items_changed.connect(_on_horadric_stash_items_changed)
	_on_horadric_stash_items_changed()

	var item_stash: ItemContainer = local_player.get_item_stash()
	item_stash.items_changed.connect(_on_item_stash_changed)

	local_player.selected_builder.connect(_on_local_player_selected_builder)


#########################
###      Private      ###
#########################

func _make_slot_button() -> EmptyUnitButton:
	var button: Button = EmptyUnitButton.make()
	button.custom_minimum_size = Vector2(88, 88)
	button.pressed.connect(_on_slot_button_pressed.bind(button))
	button.modulate = Color.TRANSPARENT
	
	return button


func _make_item_button(item: Item) -> ItemButton:
	var item_button: ItemButton = ItemButton.make(item)
	item_button.enable_horadric_lock_display()
	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))
	item_button.ctrl_right_clicked.connect(_on_item_button_ctrl_right_clicked.bind(item_button))
	
	if !item.horadric_lock_changed.is_connected(_on_item_horadric_lock_changed):
		item.horadric_lock_changed.connect(_on_item_horadric_lock_changed)

	return item_button


func _load_current_filter():
#	Show/hide item buttons depending on whether they match
#	current filter
	var rarity_filter: Array[Rarity.enm] = _rarity_filter.get_filter()
	var item_type_filter: Array = _item_type_filter_container.get_filter()
	
	var no_filter: bool = rarity_filter.size() == Rarity.get_list().size() && item_type_filter.size() == ItemType.get_list().size()

	if no_filter:
		for child in _foreground_grid.get_children():
			child.show()
		
		return
	
#	When there's a filter, hide all empty slots and show
#	item buttons which match the filter
	for child in _foreground_grid.get_children():
		if child is EmptyUnitButton:
			child.hide()
		elif child is ItemButton:
			var item_button: ItemButton = child as ItemButton
			var item: Item = item_button.get_item()
			var rarity: Rarity.enm = item.get_rarity()
			var item_type: ItemType.enm = item.get_item_type()
			var rarity_match: bool = rarity_filter.has(rarity) || rarity_filter.is_empty()
			var item_type_match: bool = item_type_filter.has(item_type) || item_type_filter.is_empty()
			var filter_match: bool = rarity_match && item_type_match

			item_button.visible = filter_match


# Enable/disable autofill buttons based on which items are
# currently available for autofill
func _update_autofill_buttons():
	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	var visible_items_in_item_stash: Array[Item] = _get_visible_item_list()
	
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var items_in_horadric_stash: Array[Item] = horadric_stash.get_item_list()

	var available_items: Array[Item] = []
	available_items.append_array(visible_items_in_item_stash)
	available_items.append_array(items_in_horadric_stash)

	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		var autofill_is_possible: bool = HoradricCube.has_recipe_ingredients(recipe, available_items)
		
		recipe_button.disabled = !autofill_is_possible


func _get_visible_item_list() -> Array[Item]:
	var list: Array[Item] = []
	
	for child_node in _foreground_grid.get_children():
		var child_is_visible_item_button: bool = child_node is ItemButton && child_node.visible
		
		if child_is_visible_item_button:
			var item_button: ItemButton = child_node as ItemButton
			var item: Item = item_button.get_item()
			
			list.append(item)

	return list


#########################
###     Callbacks     ###
#########################

func _on_local_player_selected_builder():
	var local_player: Player = PlayerManager.get_local_player()
	var builder: Builder = local_player.get_builder()
	var builder_adds_extra_recipes: bool = builder.get_adds_extra_recipes()
	
	if builder_adds_extra_recipes:
		_backpacker_recipes.show()


func _on_slot_button_pressed(button: EmptyUnitButton):
	var index: int = button.get_index()
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	
	EventBus.player_clicked_in_item_container.emit(item_stash, index)


func _on_transmute_button_pressed():
	EventBus.player_requested_transmute.emit()


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_index: int = item_stash.get_item_index(item)
	EventBus.player_clicked_in_item_container.emit(item_stash, item_index)


func _on_item_button_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	EventBus.player_right_clicked_item.emit(item)


func _on_item_button_ctrl_right_clicked(item_button: ItemButton):
	var item: Item = item_button.get_item()
	item.toggle_horadric_lock()


func _on_recipe_button_pressed(recipe: HoradricCube.Recipe):
	var rarity_filter: Array = _rarity_filter.get_filter()
	EventBus.player_requested_autofill.emit(recipe, rarity_filter)


func _on_close_button_pressed():
	hide()


func _on_rarity_filter_filter_changed():
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


func _on_return_button_pressed():
	EventBus.player_requested_return_from_horadric_cube.emit()


# NOTE: need to update buttons selectively to minimize the
# amount of times buttons are created/destroyed and avoid
# perfomance issues for large item counts. A simpler
# approach would be to remove all buttons and then go
# through the item list and add new buttons but that causes
# perfomance issues.
func _on_item_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var highest_index: int = item_stash.get_highest_index()
	
#	Add new rows of slots to have enough space if the item
#	count increased
	var current_slot_count: int = _foreground_grid.get_child_count()
	var need_more_slots: bool = highest_index + 1 > current_slot_count || current_slot_count < (5 * 4)

	if need_more_slots:
		var new_slot_count: int = ceili((highest_index + 1) / float(ITEM_STASH_COLUMN_COUNT)) * ITEM_STASH_COLUMN_COUNT
		var min_slot_count: int = ITEM_STASH_ROW_COUNT * ITEM_STASH_COLUMN_COUNT
		new_slot_count = max(new_slot_count, min_slot_count)
		
#		NOTE: need two separate while loops because
#		background grid contains an initial set of slot
#		buttons
		while _background_grid.get_child_count() < new_slot_count:
			var button_for_background: EmptyUnitButton = _make_slot_button()
			button_for_background.modulate = Color.WHITE
			_background_grid.add_child(button_for_background)
		
		while _foreground_grid.get_child_count() < new_slot_count:
			var button_for_foreround: EmptyUnitButton = _make_slot_button()
			_foreground_grid.add_child(button_for_foreround)
		
	for i in range(0, highest_index + 1):
		var item: Item = item_stash.get_item_at_index(i)
		var current_button: Button = _foreground_grid.get_child(i)
		var item_button: ItemButton = current_button as ItemButton
		
		var remove_item_button: bool = item == null && item_button != null
		var item_mismatch: bool = item_button != null && item_button.get_item() != item
		var change_button: bool = item != null && (item_button == null || item_mismatch)
		
		if remove_item_button:
			item_button.get_item().horadric_lock_changed.disconnect(_on_item_horadric_lock_changed)
			_foreground_grid.remove_child(item_button)
			item_button.queue_free()
			
			var slot_button: EmptyUnitButton = _make_slot_button()
			_foreground_grid.add_child(slot_button)
			_foreground_grid.move_child(slot_button, i)
		elif change_button:
			if item_button != null:
				item_button.get_item().horadric_lock_changed.disconnect(_on_item_horadric_lock_changed)
			
			_foreground_grid.remove_child(current_button)
			current_button.queue_free()
			
			var new_item_button: ItemButton = _make_item_button(item)
			_foreground_grid.add_child(new_item_button)
			_foreground_grid.move_child(new_item_button, i)
	
	_load_current_filter()
	_update_autofill_buttons()


func _on_horadric_stash_items_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var item_list: Array[Item] = horadric_stash.get_item_list()
	
	var can_transmute: bool = HoradricCube.can_transmute(local_player, item_list)
	_transmute_button.set_disabled(!can_transmute)

#	NOTE: need to update autofill buttons both after changes
#	in item stash and horadric stash. If an item is moved
#	from item stash to horadric stash, then it will
#	temporarily be unavailable during the move process, so
#	updating only after item stash change is not enough.
	_update_autofill_buttons()
