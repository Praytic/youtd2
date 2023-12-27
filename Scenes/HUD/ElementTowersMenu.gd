# ElementTowersMenu.gd
extends PanelContainer


signal towers_changed()


# Map of tower id's => tower buttons. Tower buttons are
# "stacks" and may contain more than one tower.
@onready var _tower_buttons: Dictionary = {}
@onready var _element_icons: Dictionary = {
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

@export var _towers_status_panel: ShortResourceStatusPanel
@export var _ice_towers_status_panel: ShortResourceStatusPanel
@export var _nature_towers_status_panel: ShortResourceStatusPanel
@export var _fire_towers_status_panel: ShortResourceStatusPanel
@export var _astral_towers_status_panel: ShortResourceStatusPanel
@export var _darkness_towers_status_panel: ShortResourceStatusPanel
@export var _iron_towers_status_panel: ShortResourceStatusPanel
@export var _storm_towers_status_panel: ShortResourceStatusPanel

#########################
### Code starts here  ###
#########################

func _ready():
	_elements_container.element_changed.connect(_on_element_changed)
	WaveLevel.changed.connect(_on_wave_level_changed)
	BuildTower.tower_built.connect(_on_tower_built)
	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)
	TowerDistribution.rolling_starting_towers.connect(_on_rolling_starting_towers)
	TowerDistribution.random_tower_distributed.connect(_on_random_tower_distributed)
	ElementLevel.changed.connect(_on_element_level_changed)
	KnowledgeTomesManager.changed.connect(_on_knowledge_tomes_changed)
	towers_changed.emit()
	
	HighlightUI.register_target("tower_stash", _tower_buttons_container)
	HighlightUI.register_target("upgrade_element_button", _upgrade_element_button)
	HighlightUI.register_target("roll_towers_button", _roll_towers_button)
	HighlightUI.register_target("elements_container", _elements_container)
	
	_update_tooltip_for_roll_towers_button()


#########################
###       Public      ###
#########################

func add_tower_button(tower_id, should_emit_signal: bool = true, insert_index = null):
	if _tower_buttons.has(tower_id):
		var tower_button: TowerButton = _tower_buttons[tower_id]
		var new_count: int = tower_button.get_count() + 1
		tower_button.set_count(new_count)
		
		return
	
	var tower_button = TowerButton.make(tower_id)
	_tower_buttons[tower_id] = tower_button
	var tower_element: Element.enm = TowerProperties.get_element(tower_id)
	var tower_should_be_visible: bool = tower_element == _elements_container.get_element()
	tower_button.set_visible(tower_should_be_visible)
	tower_button.add_to_group("tower_button")
	_tower_buttons_container.add_child(tower_button)
	if insert_index != null:
		_tower_buttons_container.move_child(tower_button, insert_index)
	
	if should_emit_signal:
		towers_changed.emit()
	
	_update_empty_slots()


func remove_tower_button(tower_id, should_emit_signal: bool = true):
	var button: TowerButton = _tower_buttons[tower_id]
	
	var tower_button: TowerButton = _tower_buttons[tower_id]
	var new_count: int = tower_button.get_count() - 1
	tower_button.set_count(new_count)

	var no_more_towers_in_stack: bool = new_count == 0

	if no_more_towers_in_stack:
		_tower_buttons.erase(tower_id)
		_tower_buttons_container.remove_child(button)
		button.queue_free()
	
	if should_emit_signal:
		towers_changed.emit()
	
	_update_empty_slots()


# TODO: Can be improved by actually acknowledging each new tower
# button when it's visible to player at least once.
func ack_status_panels():
	_towers_status_panel.ack_count()
	_fire_towers_status_panel.ack_count()
	_astral_towers_status_panel.ack_count()
	_nature_towers_status_panel.ack_count()
	_ice_towers_status_panel.ack_count()
	_iron_towers_status_panel.ack_count()
	_storm_towers_status_panel.ack_count()
	_darkness_towers_status_panel.ack_count()


#########################
###      Private      ###
#########################

func _update_resource_status_panels():
	var fire_count: int = get_towers_count(Element.enm.FIRE)
	var astral_count: int = get_towers_count(Element.enm.ASTRAL)
	var nature_count: int = get_towers_count(Element.enm.NATURE)
	var ice_count: int = get_towers_count(Element.enm.ICE)
	var iron_count: int = get_towers_count(Element.enm.IRON)
	var storm_count: int = get_towers_count(Element.enm.STORM)
	var darkness_count: int = get_towers_count(Element.enm.DARKNESS)
	var towers_count: int = get_towers_count()
	
	_towers_status_panel.set_count(towers_count)
	_fire_towers_status_panel.set_count(fire_count)
	_astral_towers_status_panel.set_count(astral_count)
	_nature_towers_status_panel.set_count(nature_count)
	_ice_towers_status_panel.set_count(ice_count)
	_iron_towers_status_panel.set_count(iron_count)
	_storm_towers_status_panel.set_count(storm_count)
	_darkness_towers_status_panel.set_count(darkness_count)


func _update_tooltip_for_roll_towers_button():
	var roll_count: int = TowerDistribution.get_current_starting_tower_roll_amount()
	var tooltip: String = "Press to get a random set of starting towers.\nYou can reroll if you don't like the initial towers\nbut each time you will get less towers.\nNext roll will give you %d towers" % roll_count
	_roll_towers_button.set_tooltip_text(tooltip)


func _update_element():
	var current_element = _elements_container.get_element()
	
	if current_element == Element.enm.NONE:
		for tower_button in _tower_buttons.values():
			tower_button.show()
	else:
		for tower_button in _tower_buttons.values():
			tower_button.hide()
		
		var available_towers_for_element = _get_available_tower_buttons_for_element(current_element)
		
		for tower_id in available_towers_for_element:
			_tower_buttons[tower_id].show()


func _add_all_towers():
	print_verbose("Start adding all towers to ElementTowersMenu.")

	var first_tier_towers: Array = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.TIER, str(1))

#	Sort towers by rarity and cost
	first_tier_towers.sort_custom(
		func(a, b):
			var rarity_a: Rarity.enm = TowerProperties.get_rarity(a)
			var rarity_b: Rarity.enm = TowerProperties.get_rarity(b)
			var cost_a: int = TowerProperties.get_cost(a)
			var cost_b: int = TowerProperties.get_cost(b)
			
			if rarity_a == rarity_b:
				return cost_a < cost_b
			else:
				return rarity_a < rarity_b
				)

	for i in range(first_tier_towers.size()):
		var tower_id = first_tier_towers[i]
		var is_released: bool = TowerProperties.is_released(tower_id)
		if !is_released:
			continue

		add_tower_button(tower_id, false, i)

#	NOTE: call _update_element() to show towers for currently
#	selected element. 
	_update_element()
	towers_changed.emit()

	print_verbose("ElementTowersMenu has added all towers.")


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


func _update_empty_slots():
	var current_element = _elements_container.get_element()
	var towers = _get_available_tower_buttons_for_element(current_element).size()
	_tower_buttons_container.update_empty_slots(towers)

#########################
###     Callbacks     ###
#########################

func _on_element_changed():
	_update_element()
	_update_upgrade_element_button_state()
	_update_element_icon()
	_update_title()
	_update_element_level_label()
	_update_info_label()
	_update_empty_slots()


func _on_tower_built(tower_id):
	match Globals.game_mode:
		GameMode.enm.BUILD: return
		GameMode.enm.RANDOM_WITH_UPGRADES: remove_tower_button(tower_id)
		GameMode.enm.TOTALLY_RANDOM: remove_tower_button(tower_id)


func _on_upgrade_element_mouse_entered():
	var element: Element.enm = _elements_container.get_element()
	var tooltip: String = RichTexts.get_research_text(element)
	ButtonTooltip.show_tooltip(_upgrade_element_button, tooltip)


func _on_upgrade_element_button_pressed():
	var element = _elements_container.get_element()
	if ElementLevel.is_able_to_research(element):
		var cost: int = ElementLevel.get_research_cost(element)
		KnowledgeTomesManager.spend(cost)
		ElementLevel.increment(element)

		var tooltip: String = RichTexts.get_research_text(element)
		ButtonTooltip.show_tooltip(_upgrade_element_button, tooltip)
	else:
#		NOTE: this case should really never happen because
#		button should be disabled (not pressable) if element
#		can't be researched.
		Messages.add_error("Can't research this element. Not enough tomes.")
		push_error("Research element button was in incorrect state. It was enabled even though current element cannot be researched - and player was able to press it.")

	_update_upgrade_element_button_state()


func _on_close_button_pressed():
	hide()


func _on_game_mode_was_chosen():
	if Globals.game_mode == GameMode.enm.BUILD:
		_add_all_towers()
		_roll_towers_button.hide()
	else:
		_roll_towers_button.show()



func _on_rolling_starting_towers():
	var tower_list: Array = _tower_buttons.keys()

#	NOTE: call remove_tower_button() multiple times to remove
#	all stacks of tower
	for tower in tower_list:
		while _tower_buttons.has(tower):
			remove_tower_button(tower, false)


func _on_random_tower_distributed(tower_id: int):
#	NOTE: in random modes, sort towers by rarity and place
#	new towers in the front of the list.
#	
#	Only do this for random game modes because in build mode
#	towers are sorted in _add_all_towers().
	var insert_index: int = _get_insert_index_for_tower(tower_id)
	add_tower_button(tower_id, true, insert_index)


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
	var research_any_elements: bool = false
	
	for element in Element.get_list():
		var researched_element: bool = ElementLevel.get_current(element) > 0
		if researched_element:
			research_any_elements = true
	
	if !research_any_elements:
		Messages.add_error("Cannot roll towers yet! You need to research at least one element.")
	
		return
	
	var can_roll_again: bool = TowerDistribution.roll_starting_towers()
	
	_update_tooltip_for_roll_towers_button()
	
	if !can_roll_again:
		_roll_towers_button.disabled = true


func _on_towers_changed():
	_update_resource_status_panels()


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


func get_towers_count(element = null) -> int:
	var counter = 0
	if element != null:
		for tower_id in _tower_buttons.keys():
			if TowerProperties.get_element(tower_id) == element:
				counter += 1
	else:
		counter = _tower_buttons.size()
	return counter


func _get_available_tower_buttons_for_element(element: Element.enm) -> Array:
	var element_string: String = Element.convert_to_string(element)
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	var res: Array = []
	for tower_id in tower_id_list:
		if _tower_buttons.has(tower_id):
			res.append(tower_id)
	
	return res


func get_tower_buttons() -> Array:
	return get_tree().get_nodes_in_group("tower_button")


func get_empty_slots() -> Array:
	return get_tree().get_nodes_in_group("empty_slot")


