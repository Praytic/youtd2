class_name BottomMenuBar extends Control


signal research_element()
signal test_signal()

@export var _item_bar: GridContainer
@export var _build_bar: GridContainer
@export var _item_menu_button: Button
@export var _building_menu_button: Button
@export var _research_panel: Control
@export var _research_button: Button
@export var _elements_container: HBoxContainer
@export var _tomes_status: ResourceStatusPanel
@export var _gold_status: ResourceStatusPanel
@export var _tower_stash: GridContainer


func _ready():
	for element_button in get_element_buttons():
		element_button.pressed.connect(_on_ElementButton_pressed.bind(element_button))
	
	_research_button.mouse_entered.connect(_on_button_mouse_entered)
	_research_button.mouse_exited.connect(_on_button_mouse_exited)
	_research_button.pressed.connect(_on_button_pressed)
	KnowledgeTomesManager.knowledge_tomes_change.connect(_on_knowledge_tomes_change)
	
	set_element(Element.enm.ICE)
	
	HighlightUI.register_target("research_button", _research_button)
	HighlightUI.register_target("elements_container", _elements_container)
	HighlightUI.register_target("tomes_status", _tomes_status)
	HighlightUI.register_target("gold_status", _gold_status)
	HighlightUI.register_target("tower_stash", _tower_stash)


func _process(_delta):
	var item_button_count: int = _item_bar.get_item_count()
	_item_menu_button.text = str(item_button_count)
	
	_building_menu_button.text = str(_build_bar.get_child_count())


func _on_button_pressed():
	var element = _build_bar.get_element()
	ElementLevel.increment(element)

	var cost: int = ElementLevel.get_research_cost(element)
	KnowledgeTomesManager.spend(cost)
	
	if ElementLevel.get_current(element) == ElementLevel.get_max():
		_research_button.disabled = true


func _on_button_mouse_entered():
	var element = _build_bar.get_element()
	EventBus.research_button_mouse_entered.emit(element)


func _on_button_mouse_exited():
	EventBus.research_button_mouse_exited.emit()


func _on_knowledge_tomes_change():
	var current_element: Element.enm = _build_bar.get_element()
	var can_afford: bool = ElementLevel.can_afford_research(current_element)
	_research_button.set_disabled(!can_afford)
	
	_on_button_mouse_entered()


# NOTE: below are getters for elements inside bottom menu
# bar which are used as targets by TutorialMenu. This is to
# avoid hardcoding paths to these elements in TutorialMenu.
func get_research_button() -> Control:
	return _research_button


func get_elements_container() -> Control:
	return _elements_container


func get_item_menu_button() -> Button:
	return _item_menu_button


func set_element(element: Element.enm):
#	Dim the color of unselected element buttons
	var buttons: Array = get_element_buttons()

	for button in buttons:
		var button_is_selected: bool = button.element == element

		if button_is_selected:
			button.modulate = Color.WHITE
		else:
			button.modulate = Color.WHITE.darkened(0.4)

	if element == Element.enm.NONE:
		_item_bar.show()
		_build_bar.hide()
	else:
		_item_bar.hide()
		_build_bar.show()
		_build_bar.set_element(element)


# NOTE: have to manually call this because ItemMovement
# can't detect clicks on right menu bar.
func _gui_input(event):
	if event.is_action_released("left_click"):
		ItemMovement.on_clicked_on_right_menu_bar()

func get_element_buttons() -> Array:
	return get_tree().get_nodes_in_group("element_button")


func _on_ItemMenuButton_pressed():
	set_element(Element.enm.NONE)


func _on_ElementButton_pressed(element_button):
	set_element(element_button.element)
	var can_afford_upgrade: bool = ElementLevel.can_afford_research(element_button.element)
	_research_button.set_disabled(!can_afford_upgrade)


func _on_BuildMenuButton_pressed():
	set_element(_build_bar.get_element())


func _on_research_button_pressed():
	_research_panel.visible = !_research_panel.visible
