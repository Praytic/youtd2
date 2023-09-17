class_name BottomMenuBar extends Control


signal research_element()
signal test_signal()

@export var _item_stash_menu: GridContainer
@export var _build_bar: GridContainer
@export var _research_button: Button
@export var _elements_container: HBoxContainer
@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel
@export var _tower_stash: GridContainer
@export var _tower_stash_scroll_container: ScrollContainer
@export var _item_stash_scroll_container: ScrollContainer

var _item_rarity_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/item_rarity_filter_button_group.tres")
var _item_type_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/item_type_filter_button_group.tres")
var _element_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/element_filter_button_group.tres")


func _ready():
	for item_filter_button in _item_rarity_filter_button_group.get_buttons():
		item_filter_button.toggled.connect(_on_item_rarity_filter_button_toggled)
	
	for element_button in _element_filter_button_group.get_buttons():
		element_button.pressed.connect(_on_ElementButton_pressed.bind(element_button))
	
	KnowledgeTomesManager.changed.connect(_on_knowledge_tomes_changed)
	ItemStash.items_changed.connect(_on_item_stash_changed)
	_build_bar.towers_changed.connect(_on_tower_stash_changed)
	_on_item_stash_changed()
	
	set_element(Element.enm.ICE)
	
	HighlightUI.register_target("research_button", _research_button)
	HighlightUI.register_target("elements_container", _elements_container)
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
	HighlightUI.register_target("tower_stash", _tower_stash)


func _on_upgrade_element_button_pressed():
	var element: Element.enm = _element_filter_button_group.get_pressed_button().element
	ElementLevel.increment(element)

	var cost: int = ElementLevel.get_research_cost(element)
	KnowledgeTomesManager.spend(cost)

#	NOTE: force update of button tooltip
	_on_upgrade_element_button_mouse_entered()

	_update_upgrade_element_button()


func _on_upgrade_element_button_mouse_entered():
	var element: Element.enm = _element_filter_button_group.get_pressed_button().element
	EventBus.research_button_mouse_entered.emit(element)


func _on_upgrade_element_button_mouse_exited():
	EventBus.research_button_mouse_exited.emit()


func _on_knowledge_tomes_changed():
	_update_upgrade_element_button()


# NOTE: below are getters for elements inside bottom menu
# bar which are used as targets by TutorialMenu. This is to
# avoid hardcoding paths to these elements in TutorialMenu.
func get_research_button() -> Control:
	return _research_button


func get_elements_container() -> Control:
	return _elements_container


func get_item_rarity_filter_button(rarity: Rarity.enm) -> Button:
	var target_button
	for button in _item_rarity_filter_button_group.get_buttons():
		if button.filter_value == rarity:
			target_button = button
			break
	return target_button


func set_element(element: Element.enm):
	_build_bar.set_element(element)

#	NOTE: set_value() is a member of Range class which is an
#	ancestor of HScrollBar class
	var scroll_bar: HScrollBar = _tower_stash_scroll_container.get_h_scroll_bar()
	scroll_bar.set_value(0.0)

	_update_upgrade_element_button()


func _on_item_rarity_filter_button_toggled(_toggle: bool):
	var active_button = _item_rarity_filter_button_group.get_pressed_button()
	_item_stash_menu.set_current_item_rarity_filter(active_button.filter_value)
	
#	NOTE: set_value() is a member of Range class which is an
#	ancestor of HScrollBar class
	var scroll_bar: HScrollBar = _item_stash_scroll_container.get_h_scroll_bar()
	scroll_bar.set_value(0.0)


func _on_item_type_filter_button_toggled(_toggle: bool):
	var active_button = _item_type_filter_button_group.get_pressed_button()
	_item_stash_menu.set_current_item_type_filter(active_button.filter_value)
	
#	NOTE: set_value() is a member of Range class which is an
#	ancestor of HScrollBar class
	var scroll_bar: HScrollBar = _item_stash_scroll_container.get_h_scroll_bar()
	scroll_bar.set_value(0.0)


func _on_ElementButton_pressed(element_button):
	set_element(element_button.element)
	_update_upgrade_element_button()


func _on_BuildMenuButton_pressed():
	set_element(_build_bar.get_element())


func _on_stash_margin_container_gui_input(event):
	if event.is_action_released("left_click") && _item_stash_menu.is_visible():
		ItemMovement.item_stash_was_clicked()


func _on_item_stash_changed():
	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	for button in _item_rarity_filter_button_group.get_buttons():
		button.items_count = item_stash_container.get_item_count(button.filter_value, null)
	for button in _item_type_filter_button_group.get_buttons():
		button.items_count = item_stash_container.get_item_count(null, button.filter_value)


func _on_tower_stash_changed():
	for button in _element_filter_button_group.get_buttons():
		var filtered_towers_count = _build_bar.get_towers_count(button.element)
		button.set_towers_counter(filtered_towers_count)


func _update_upgrade_element_button():
	var element: Element.enm = _build_bar.get_element()
	var can_afford: bool = ElementLevel.can_afford_research(element)
	var current_level: int = ElementLevel.get_current(element)
	var reached_max_level: bool = current_level == ElementLevel.get_max()
	var button_is_enabled: bool = can_afford && !reached_max_level

	_research_button.set_disabled(!button_is_enabled)


func _on_item_filter_button_toggled(button_pressed):
	pass # Replace with function body.
