class_name TowerStashMenu extends PanelContainer


enum FilterType {
	RARITY,
	ELEMENT
}


@export var _tower_buttons_container: UnitButtonsContainer
@export var _rarity_filter: TowerRarityFilter
@export var _element_filter: ElementsContainer

var _button_list: Array[TowerButton] = []
var _prev_tower_list: Array = []
var _filter_type: FilterType = FilterType.RARITY


#########################
###       Public      ###
#########################

func set_filter_type(filter_type: TowerStashMenu.FilterType):
	_filter_type = filter_type
	
	_rarity_filter.visible = filter_type == FilterType.RARITY
	_element_filter.visible = filter_type == FilterType.ELEMENT
	
	_update_button_visibility()


func set_towers(towers: Dictionary):
	var tower_list: Array = towers.keys()

	tower_list.sort_custom(
		func(a, b) -> bool:
			var rarity_a: Rarity.enm = TowerProperties.get_rarity(a)
			var rarity_b: Rarity.enm = TowerProperties.get_rarity(b)
			var cost_a: int = TowerProperties.get_cost(a)
			var cost_b: int = TowerProperties.get_cost(b)
			
			if rarity_a == rarity_b:
				return cost_a < cost_b
			else:
				return rarity_a < rarity_b
	)

# 	Remove buttons for towers which were removed from stash
	var removed_button_list: Array[TowerButton] = []

	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_was_removed: bool = !towers.has(tower_id)

		if tower_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		_tower_buttons_container.remove_child(button)
		button.queue_free()
		_button_list.erase(button)

# 	Add buttons for towers which were added to stash
#	NOTE: preserve order
	for i in range(0, tower_list.size()):
		var tower_id: int = tower_list[i]
		var tower_was_added: bool = !_prev_tower_list.has(tower_id)
		
		if tower_was_added:
			_add_tower_button(tower_id, i)
	
	_prev_tower_list = tower_list.duplicate()

# 	Update tower counts
	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_count: int = towers[tower_id]
		button.set_count(tower_count)

	_unlock_tower_buttons_if_possible()
	_update_button_visibility()


func update_level(_level: int):
	_unlock_tower_buttons_if_possible()

	
func update_element_level(_element_levels: Dictionary):
	_unlock_tower_buttons_if_possible()


#########################
###      Private      ###
#########################

func _add_tower_button(tower_id: int, index: int):
	var tower_button: TowerButton = TowerButton.make()
	_button_list.append(tower_button)
	_tower_buttons_container.add_child(tower_button)
	_tower_buttons_container.move_child(tower_button, index)
	HighlightUI.register_target("tower_button", tower_button)
	tower_button.pressed.connect(_on_tower_button_pressed.bind(tower_id))

	tower_button.set_tower_id(tower_id)
	tower_button.set_locked(true)

	if Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM:
		tower_button.set_tier_visible(true)


func _unlock_tower_buttons_if_possible():
	for button in _button_list:
		if !button.disabled:
			continue

		var tower_id: int = button.get_tower_id()
		var local_player: Player = PlayerManager.get_local_player()
		var can_build_tower: bool = TowerProperties.requirements_are_satisfied(tower_id, local_player)

		if can_build_tower:
			button.set_locked(false)


func _update_button_visibility():
	var selected_rarity_list: Array[Rarity.enm] = _rarity_filter.get_rarity_list()
	var selected_element: Element.enm = _element_filter.get_element()
	
	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		var element: Element.enm = TowerProperties.get_element(tower_id)
		
		var filter_match: bool
		match _filter_type:
			FilterType.RARITY: filter_match = selected_rarity_list.has(rarity)
			FilterType.ELEMENT: filter_match = selected_element == element
		
		button.visible = filter_match
		
	var visible_count: int = 0
	for button in _button_list:
		if button.visible:
			visible_count += 1

	_tower_buttons_container.update_empty_slots(visible_count)


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed():
	hide()


func _on_tower_button_pressed(tower_id: int):
	EventBus.player_requested_to_build_tower.emit(tower_id)
	EventBus.player_performed_tutorial_advance_action.emit("press_tower_button")


func _on_rarity_filter_container_filter_changed():
	_update_button_visibility()


func _on_element_filter_element_changed():
	_update_button_visibility()
