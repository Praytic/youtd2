@tool
class_name ItemStashMenu extends PanelContainer


# NOTE: these are visible counts, not total possible counts
# NOTE: set min row count to 6 to have one row extra at
# startup. Otherwise item stash would go from having no
# scroll bar to having a scroll bar which is weird behavior.
const MIN_ROW_COUNT: int = 6
const COLUMN_COUNT: int = 6


# This UI element displays items which are currently in the
# item stash.
@export var _rarity_filter: RarityFilter
@export var _item_type_filter_container: VBoxContainer
@export var _background_grid: GridContainer
@export var _item_grid: GridContainer
@export var _item_scroll_container: ScrollContainer

@export var _backpacker_recipes: GridContainer
@export var _horadric_item_container_panel: ItemContainerPanel
@export var _transmute_button: Button

@export var _sort_button: Button
@export var _horadric_cube_avg_item_level_label: Label

#########################
### Code starts here  ###
#########################

# NOTE: the background buttons are also added while the scene is open in editor, to check how it looks visually.
func _ready():
	var min_slot_count: int = MIN_ROW_COUNT * COLUMN_COUNT
	
	for i in range(0, min_slot_count):
		var slot_button: Button = _make_slot_button()
		slot_button.modulate = Color.WHITE
		_background_grid.add_child(slot_button)
	
	if Engine.is_editor_hint():
		return
	
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
	_on_item_stash_changed()

	local_player.selected_builder.connect(_on_local_player_selected_builder)


#########################
###      Private      ###
#########################

func _make_slot_button() -> EmptyUnitButton:
	var button: Button = EmptyUnitButton.make()
	button.custom_minimum_size = Constants.ITEM_BUTTON_SIZE
	button.pressed.connect(_on_slot_button_pressed.bind(button))
	button.modulate = Color.TRANSPARENT
	
	return button


func _make_item_button(item: Item) -> ItemButton:
	var item_button: ItemButton = ItemButton.make()
	item_button.set_item(item)
	item_button.set_horadric_lock_visible(true)
	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
	item_button.right_clicked.connect(_on_item_button_right_clicked.bind(item_button))
	item_button.ctrl_right_clicked.connect(_on_item_button_ctrl_right_clicked.bind(item_button))
	item_button.horadric_lock_changed.connect(_on_item_button_horadric_lock_changed)
	
	return item_button


func _get_filter_is_none() -> bool:
	var rarity_filter: Array[Rarity.enm] = _rarity_filter.get_filter()
	var item_type_filter: Array = _item_type_filter_container.get_filter()
	
	var filter_is_none: bool = rarity_filter.size() == Rarity.get_list().size() && item_type_filter.size() == ItemType.get_list().size()

	return filter_is_none


func _load_current_filter():
	var filter_is_none: bool = _get_filter_is_none()

	if filter_is_none:
		for child in _item_grid.get_children():
			child.show()
		
		return

#	NOTE: reset scroll position when a filter is defined. If
#	this is not done, a player may scroll down, turn on a
#	filter and then see empty stash even though there are
#	items at the beginning, before visible scrolled area.
	Utils.reset_scroll_container(_item_scroll_container)

#	Show/hide item buttons depending on whether they match
#	current filter
	var rarity_filter: Array[Rarity.enm] = _rarity_filter.get_filter()
	var item_type_filter: Array = _item_type_filter_container.get_filter()
	
#	When there's a filter, hide all empty slots and show
#	item buttons which match the filter
	for child in _item_grid.get_children():
		var button: ItemButton = child as ItemButton
		var item: Item = button.get_item()

#		NOTE: item buttons become transparent if the item is
#		null but still need to hide the button to make item
#		grid contiguous
		if item == null:
			button.hide()

			continue

		var rarity: Rarity.enm = item.get_rarity()
		var item_type: ItemType.enm = item.get_item_type()
		var rarity_match: bool = rarity_filter.has(rarity) || rarity_filter.is_empty()
		var item_type_match: bool = item_type_filter.has(item_type) || item_type_filter.is_empty()
		var filter_match: bool = rarity_match && item_type_match

		button.visible = filter_match


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
	
	var item_button_list: Array = _item_grid.get_children()
	for item_button in item_button_list:
		if item_button.visible:
			var item: Item = item_button.get_item()
			
			if item != null:
				list.append(item)

	return list


func _set_horadric_cube_average_level():
	var text: String = 'Average item level: '
	
	var local_player: Player = PlayerManager.get_local_player()
	var horadric_stash: ItemContainer = local_player.get_horadric_stash()
	var items_in_horadric_stash: Array[Item] = horadric_stash.get_item_list()
	
	var avg_level: int = HoradricCube._get_average_ingredient_level(items_in_horadric_stash)
	
	text += "%s" % avg_level
	
	_horadric_cube_avg_item_level_label.text = text
	

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
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_index: int = item_button.get_index()
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
func _on_item_button_horadric_lock_changed():
	_update_autofill_buttons()


func _on_return_button_pressed():
	EventBus.player_requested_return_from_horadric_cube.emit()


func _on_item_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var highest_index: int = item_stash.get_highest_index()
	
#	Add new rows to give the player space to organize items.
#	The amount of rows depends on the highest occupied
#	index, not total item count because item stash can have
#	empty slots between items. Always add one extra empty
#	row to prevent the item stash from feeling confined.
	var required_row_count: int = ceili((highest_index + 1) / float(COLUMN_COUNT)) + 1
	required_row_count = max(required_row_count, MIN_ROW_COUNT)
	var required_slot_count: int = required_row_count * COLUMN_COUNT
	var current_slot_count: int = _item_grid.get_child_count()
	var need_more_slots: bool = required_slot_count > current_slot_count

	if need_more_slots:
		while _background_grid.get_child_count() < required_slot_count:
			var slot_button: EmptyUnitButton = _make_slot_button()
			slot_button.modulate = Color.WHITE
			_background_grid.add_child(slot_button)
		
		while _item_grid.get_child_count() < required_slot_count:
			var item_button: ItemButton = _make_item_button(null)
			_item_grid.add_child(item_button)
	
	var item_button_list: Array = _item_grid.get_children()
	for item_button in item_button_list:
		var index: int = item_button.get_index()
		var new_item: Item = item_stash.get_item_at_index(index)

		item_button.set_item(new_item)

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
	_set_horadric_cube_average_level()


# NOTE: this callback is needed to implement "move item from
# horadric cube to item stash while filtering item stash".
# Normal movement doesn't work because filtered item stash
# has no empty slots to click on and in filtered state the
# item stash is contiguous anyway. Also, this callback is a
# bit bad because it gets triggered on clicks between
# buttons, so do it only for filtered case. Otherwise, it
# would be possible for player to misclick and move item to
# wrong place.
func _on_item_grid_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")
	
	if left_click:
		var filter_is_none: bool = _get_filter_is_none()

		if filter_is_none:
			return

		var local_player: Player = PlayerManager.get_local_player()
		var item_stash: ItemContainer = local_player.get_item_stash()

		EventBus.player_clicked_in_item_container.emit(item_stash, -1)


func _on_sort_button_pressed():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	item_stash.sort_items_by_type_rarity_and_levels()
	
