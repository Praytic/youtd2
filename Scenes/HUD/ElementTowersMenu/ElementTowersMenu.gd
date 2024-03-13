class_name ElementTowersMenu extends Control


@export var _tab_container: TabContainer
@export var _menu_card: ButtonStatusCard
@export var _element_container: ElementsContainer

var _player: Player = null


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.tower_created.connect(_on_tower_created)


#########################
###       Public      ###
#########################

func hide_roll_towers_button():
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.hide_roll_towers_button()


func set_player(player: Player):
	_player = player

	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.set_player(player)

	_element_container.set_player(player)


func set_towers(towers: Dictionary):
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.set_towers(towers)


func update_element_level(element_levels: Dictionary):
	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		var element: Element.enm = tab.get_element()
		var level: int = element_levels[element]
		tab.set_element_level(level)


func close():
	if _menu_card.get_main_button().is_pressed():
		_menu_card.get_main_button().set_pressed(false)


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
	close()


func _on_tower_created(_tower: Tower):
	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		HighlightUI.highlight_target_ack.emit("tower_placed_on_map")

	var tab_list: Array[ElementTowersTab] = _get_tab_list()

	for tab in tab_list:
		tab.hide_roll_towers_button()


func _on_elements_container_element_changed():
	var element: Element.enm = _element_container.get_element()
	var tab: ElementTowersTab = _get_tab(element)
	var tab_index: int = _tab_container.get_tab_idx_from_control (tab)
	_tab_container.current_tab = tab_index
