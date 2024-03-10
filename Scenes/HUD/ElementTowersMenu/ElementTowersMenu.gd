# ElementTowersMenu.gd
extends PanelContainer

# Displays contents of TowerStash, separated into sections
# by elements. Also allows upgrading elements


const _element_icons: Dictionary = {
	Element.enm.ICE: preload("res://Resources/Textures/UI/Icons/ice_icon.tres"),
	Element.enm.NATURE: preload("res://Resources/Textures/UI/Icons/nature_icon.tres"),
	Element.enm.ASTRAL: preload("res://Resources/Textures/UI/Icons/astral_icon.tres"),
	Element.enm.DARKNESS: preload("res://Resources/Textures/UI/Icons/darkness_icon.tres"),
	Element.enm.FIRE: preload("res://Resources/Textures/UI/Icons/fire_icon.tres"),
	Element.enm.IRON: preload("res://Resources/Textures/UI/Icons/iron_icon.tres"),
	Element.enm.STORM: preload("res://Resources/Textures/UI/Icons/storm_icon.tres"),
}

@export var _upgrade_element_button: Button
@export var _tower_buttons_container: UnitButtonsContainer
@export var _elements_container: VBoxContainer
@export var _element_icon: TextureRect
@export var _title: Label
@export var _element_level_label: Label
@export var _element_info_label: RichTextLabel
@export var _roll_towers_button: Button

@export var _menu_card: ButtonStatusCard


var _button_list: Array[TowerButton] = []
var _prev_tower_list: Array = []


#########################
### Code starts here  ###
#########################

func _ready():
	_elements_container.element_changed.connect(_on_element_changed)
	WaveLevel.changed.connect(_on_wave_level_changed)
	BuildTower.tower_built.connect(_on_tower_built)
	PregameSettings.finalized.connect(_on_pregame_settings_finalized)
	ElementLevel.changed.connect(_on_element_level_changed)
	KnowledgeTomesManager.changed.connect(_on_knowledge_tomes_changed)
	
	HighlightUI.register_target("tower_stash", _tower_buttons_container)
	_tower_buttons_container.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("tower_stash"))
	
	_on_element_changed()


#########################
###       Public      ###
#########################

func set_towers(towers: Dictionary):
	var tower_list: Array = towers.keys()

# 	Sort towers by rarity and cost so that when tower
# 	buttons are added, they are added in this order.
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

	_update_button_visibility()


func _add_tower_button(tower_id: int, index: int):
	var tower_button: TowerButton = TowerButton.make(tower_id)
	tower_button.add_to_group("tower_button")
	_button_list.append(tower_button)
	_tower_buttons_container.add_child(tower_button)
	_tower_buttons_container.move_child(tower_button, index)


func close():
	if _menu_card.get_main_button().is_pressed():
		_menu_card.get_main_button().set_pressed(false)


#########################
###      Private      ###
#########################

func _update_button_visibility():
	var current_element = _elements_container.get_element()
	
	if current_element == Element.enm.NONE:
		for tower_button in _button_list:
			tower_button.visible = true

		_tower_buttons_container.update_empty_slots(_button_list.size())

		return

	var visible_count: int = 0

	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_element: Element.enm = TowerProperties.get_element(tower_id)
		var element_match: bool = tower_element == current_element

		button.visible = element_match

		if element_match:
			visible_count += 1

	_tower_buttons_container.update_empty_slots(visible_count)


func _update_upgrade_element_button_state():
	var current_element = _elements_container.get_element()
	_upgrade_element_button.disabled = !ElementLevel.is_able_to_research(current_element)


func _update_element_icon():
	var current_element = _elements_container.get_element()
	_element_icon.texture = _element_icons[current_element]


func _update_title():
	var current_element = _elements_container.get_element()
	_title.text = Element.enm.keys()[current_element]


func _update_element_level_label():
	var current_element = _elements_container.get_element()
	_element_level_label.text = str(ElementLevel.get_current(current_element))


func _update_info_label():
	var current_element = _elements_container.get_element()
	var flavor_text: String = Element.get_flavor_text(current_element)
	var main_attack_types: String = Element.get_main_attack_types(current_element)
	var text = ""
	text += "[color=LIGHTBLUE]%s[/color]\n" % flavor_text
	text += " \n"
	text += "[color=GOLD]Main attack types:[/color] %s\n" % main_attack_types
	_element_info_label.text = text


#########################
###     Callbacks     ###
#########################

func _on_element_changed():
	_update_button_visibility()
	_update_upgrade_element_button_state()
	_update_element_icon()
	_update_title()
	_update_element_level_label()
	_update_info_label()


func _on_tower_built(_tower_id: int):
	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		HighlightUI.highlight_target_ack.emit("tower_placed_on_map")

	if PregameSettings.game_mode_is_random():
		_roll_towers_button.disabled = true


func _on_upgrade_element_button_mouse_entered():
	var element: Element.enm = _elements_container.get_element()
	var tooltip: String = RichTexts.get_research_text(element)
	ButtonTooltip.show_tooltip(_upgrade_element_button, tooltip)


func _on_upgrade_element_button_pressed():
	var element = _elements_container.get_element()
	if ElementLevel.is_able_to_research(element):
		var cost: int = ElementLevel.get_research_cost(element)
		KnowledgeTomesManager.spend(cost)
		ElementLevel.increment(element)
		
#		Hide and show button to refresh button tooltip.
#		NOTE: can't call
#		_on_upgrade_element_button_mouse_entered() directly
#		here because it doesn't work right when button is
#		pressed via shortcut.
		_upgrade_element_button.hide()
		_upgrade_element_button.show()
	else:
#		NOTE: this case should really never happen because
#		button should be disabled (not pressable) if element
#		can't be researched.
		Messages.add_error("Can't research this element. Not enough tomes.")
		push_error("Research element button was in incorrect state. It was enabled even though current element cannot be researched - and player was able to press it.")

	_update_upgrade_element_button_state()


func _on_close_button_pressed():
	close()


func _on_pregame_settings_finalized():
	var game_mode_is_random: bool = PregameSettings.get_game_mode() != GameMode.enm.BUILD
	_roll_towers_button.visible = game_mode_is_random


func _on_element_level_changed():
	_update_element_level_label()
	_update_upgrade_element_button_state()


func _on_knowledge_tomes_changed():
	_update_upgrade_element_button_state()


func _on_wave_level_changed():
	var new_wave_level: int = WaveLevel.get_current()
	var start_first_wave: bool = new_wave_level == 1

	if start_first_wave:
		_roll_towers_button.disabled = true


func _on_roll_towers_button_pressed():
	EventBus.player_requested_to_roll_towers.emit()


#########################
### Setters / Getters ###
#########################

func _get_insert_index_for_tower(tower_id: int) -> int:
	var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
	var index: int = 0
	var tower_buttons: Array = get_tower_buttons()

	for button in tower_buttons:
		var this_tower_id: int = button.get_tower_id()
		var this_rarity: Rarity.enm = TowerProperties.get_rarity(this_tower_id)

		if this_rarity <= rarity:
			break

		index += 1

	return index


func get_tower_buttons() -> Array:
	return get_tree().get_nodes_in_group("tower_button")


func get_empty_slots() -> Array:
	return get_tree().get_nodes_in_group("empty_slot")
