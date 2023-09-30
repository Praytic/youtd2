class_name BottomMenuBar extends Control


signal research_element()
signal test_signal()

@export var _item_stash_menu: GridContainer
@export var _build_bar: GridContainer
@export var _elements_container: HBoxContainer
@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel
@export var _tower_stash_scroll_container: ScrollContainer
@export var _item_stash_scroll_container: ScrollContainer
@export var _center_menu: VBoxContainer

var _item_rarity_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/item_rarity_filter_button_group.tres")
var _item_type_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/item_type_filter_button_group.tres")
var _element_filter_button_group: ButtonGroup = preload("res://Resources/UI/ButtonGroup/element_filter_button_group.tres")


func _ready():
#	NOTE: this is to fix "unused" warning
	_center_menu = _center_menu	
	
	for item_filter_button in _item_rarity_filter_button_group.get_buttons():
		item_filter_button.toggled.connect(_on_item_rarity_filter_button_toggled)
	
	for item_filter_button in _item_type_filter_button_group.get_buttons():
		item_filter_button.toggled.connect(_on_item_type_filter_button_toggled)
	
	for element_button in _element_filter_button_group.get_buttons():
		element_button.pressed.connect(_on_ElementButton_pressed.bind(element_button))
	
	ItemStash.items_changed.connect(_on_item_stash_changed)
	_build_bar.towers_changed.connect(_on_tower_stash_changed)
	
	_on_item_stash_changed()
	
	set_element(Element.enm.ICE)
	
	HighlightUI.register_target("elements_container", _elements_container)
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
	HighlightUI.register_target("tower_stash", _build_bar)


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


func _on_item_rarity_filter_button_toggled(_toggle: bool):
	var active_button = _item_rarity_filter_button_group.get_pressed_button()
	if active_button:
		_item_stash_menu.set_current_item_rarity_filter(active_button.filter_value)
	else:
		_item_stash_menu.set_current_item_rarity_filter(null)
	
#	NOTE: set_value() is a member of Range class which is an
#	ancestor of HScrollBar class
	var scroll_bar: HScrollBar = _item_stash_scroll_container.get_h_scroll_bar()
	scroll_bar.set_value(0.0)


func _on_item_type_filter_button_toggled(_toggle: bool):
	var active_button = _item_type_filter_button_group.get_pressed_button()
	if active_button:
		_item_stash_menu.set_current_item_type_filter(active_button.filter_value)
	else:
		_item_stash_menu.set_current_item_type_filter(null)
	
#	NOTE: set_value() is a member of Range class which is an
#	ancestor of HScrollBar class
	var scroll_bar: HScrollBar = _item_stash_scroll_container.get_h_scroll_bar()
	scroll_bar.set_value(0.0)


func _on_ElementButton_pressed(element_button):
	set_element(element_button.element)


func _on_BuildMenuButton_pressed():
	set_element(_build_bar.get_element())


func _on_stash_margin_container_gui_input(event):
	if event.is_action_released("left_click") && _item_stash_menu.is_visible():
		ItemMovement.item_stash_was_clicked()


func _on_item_stash_changed():
	var item_stash_container: ItemContainer = ItemStash.get_item_container()
	for button in _item_rarity_filter_button_group.get_buttons():
		button.set_items_count(item_stash_container.get_item_count(button.filter_value, null))
	for button in _item_type_filter_button_group.get_buttons():
		button.set_items_count(item_stash_container.get_item_count(null, button.filter_value))


func _on_tower_stash_changed():
	for button in _element_filter_button_group.get_buttons():
		var filtered_towers_count = _build_bar.get_towers_count(button.element)
		button.set_towers_counter(filtered_towers_count)
