class_name ElementTowersTab extends VBoxContainer


# Tab used inside ElementTowersMenu. Each tab is assigned to
# one element and displays towers available for that
# element. Tabs also contain a button to research elements.
# Note that tabs load texts/icons for their assigned
# elements automatically in _ready().

const _element_icons: Dictionary = {
	Element.enm.ICE: preload("res://Resources/Textures/UI/Icons/ice_icon.tres"),
	Element.enm.NATURE: preload("res://Resources/Textures/UI/Icons/nature_icon.tres"),
	Element.enm.ASTRAL: preload("res://Resources/Textures/UI/Icons/astral_icon.tres"),
	Element.enm.DARKNESS: preload("res://Resources/Textures/UI/Icons/darkness_icon.tres"),
	Element.enm.FIRE: preload("res://Resources/Textures/UI/Icons/fire_icon.tres"),
	Element.enm.IRON: preload("res://Resources/Textures/UI/Icons/iron_icon.tres"),
	Element.enm.STORM: preload("res://Resources/Textures/UI/Icons/storm_icon.tres"),
}


@export var _element: Element.enm
@export var _title_label: Label
@export var _element_level_label: Label
@export var _upgrade_button: Button
@export var _roll_button: Button
@export var _element_icon: TextureRect
@export var _tower_buttons_container: UnitButtonsContainer
@export var _info_label: RichTextLabel

var _button_list: Array[TowerButton] = []
var _prev_tower_list: Array = []
var _player: Player = null


#########################
###     Built-in      ###
#########################

func _ready():
	var element_name: String = Element.convert_to_string(_element)
	_title_label.text = element_name.to_upper()

	var element_icon: Texture2D = _element_icons[_element]
	_element_icon.texture = element_icon

	_info_label.text = _get_element_info_text()


#########################
###       Public      ###
#########################

func hide_roll_towers_button():
	_roll_button.hide()


func set_player(player: Player):
	_player = player


func get_element() -> Element.enm:
	return _element


func set_element_level(level: int):
	_element_level_label.text = str(level)

#	Hide and show button to refresh button tooltip if the
#	button is hovered.
	_upgrade_button.hide()
	_upgrade_button.show()

	_unlock_tower_buttons_if_possible()


func update_level(_level: int):
	_unlock_tower_buttons_if_possible()


func set_towers(towers: Dictionary):
	var tower_list: Array = towers.keys()

# 	Filter out towers which do not have matching element
	tower_list = tower_list.filter(
		func(tower_id: int) -> bool:
			var tower_element: Element.enm = TowerProperties.get_element(tower_id)
			var element_match: bool = tower_element == _element

			return element_match
	)

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

	_tower_buttons_container.update_empty_slots(_button_list.size())

	_unlock_tower_buttons_if_possible()


#########################
###      Private      ###
#########################

func _unlock_tower_buttons_if_possible():
	for button in _button_list:
		if !button.disabled:
			continue

		var tower_id: int = button.get_tower_id()
		var can_build_tower: bool = TowerProperties.requirements_are_satisfied(tower_id, _player) || Config.ignore_requirements()

		if can_build_tower:
			button.unlock()

			if Globals.get_game_state() == Globals.GameState.TUTORIAL:
				HighlightUI.register_target("tower_stash_unlocked", self, true)
				HighlightUI.register_target("tower_placed_on_map", self, true)
				button.pressed.connect(func(): HighlightUI.highlight_target_ack.emit("tower_stash_unlocked"))


func _get_element_info_text() -> String:
	var text: String = ""

	var flavor_text: String = Element.get_flavor_text(_element)
	var main_attack_types: String = Element.get_main_attack_types(_element)
	text += "[color=LIGHTBLUE]%s[/color]\n" % flavor_text
	text += " \n"
	text += "[color=GOLD]Main attack types:[/color] %s\n" % main_attack_types

	return text


func _add_tower_button(tower_id: int, index: int):
	var tower_button: TowerButton = TowerButton.make(tower_id)
	tower_button.set_player(_player)
	_button_list.append(tower_button)
	_tower_buttons_container.add_child(tower_button)
	_tower_buttons_container.move_child(tower_button, index)


#########################
###     Callbacks     ###
#########################

func _on_upgrade_element_button_mouse_entered():
	var tooltip: String = RichTexts.get_research_text(_element, _player)
	ButtonTooltip.show_tooltip(_upgrade_button, tooltip)


func _on_upgrade_element_button_pressed():
	EventBus.player_requested_to_research_element.emit(_element)


func _on_roll_towers_button_pressed():
	EventBus.player_requested_to_roll_towers.emit()
