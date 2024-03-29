class_name ElementTowersMenu extends Control


@export var _tab_container: TabContainer
@export var _element_container: ElementsContainer


#########################
###       Public      ###
#########################

func hide_roll_towers_button():
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.hide_roll_towers_button()


func set_towers(towers: Dictionary):
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.set_towers(towers)


func update_level(level: int):
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.update_level(level)


func update_element_level(element_levels: Dictionary):
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		var element: Element.enm = tab.get_element()
		var level: int = element_levels[element]
		tab.set_element_level(level)

	_element_container.update_element_level(element_levels)


#########################
###      Private      ###
#########################

func _get_tab_list() -> Array[ElementTowersTab]:
	var list: Array[ElementTowersTab] = []

	var tab_list: Array[Node] = _tab_container.get_children()
	
	for tab_node in tab_list:
		if !tab_node is ElementTowersTab:
			push_error("element menu tab is not ElementTowersTab")

			continue

		var tab: ElementTowersTab = tab_node as ElementTowersTab
		list.append(tab)

	return list


func _get_tab(element: Element.enm) -> ElementTowersTab:
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	var tab_for_element: ElementTowersTab = null

	for tab in tab_list:
		if tab.get_element() == element:
			tab_for_element = tab

			break

	return tab_for_element


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed():
	hide()


func _on_elements_container_element_changed():
	var element: Element.enm = _element_container.get_element()
	var tab: ElementTowersTab = _get_tab(element)
	var tab_index: int = _tab_container.get_tab_idx_from_control (tab)
	_tab_container.current_tab = tab_index
