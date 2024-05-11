class_name ElementsMenu extends PanelContainer


@export var _ice_button: UnitButton
@export var _fire_button: UnitButton
@export var _nature_button: UnitButton
@export var _darkness_button: UnitButton
@export var _iron_button: UnitButton
@export var _astral_button: UnitButton
@export var _storm_button: UnitButton
@export var _roll_towers_button: UnitButton
@export var _empty_unit_button_to_replace_roll_towers: Button

@onready var _button_map: Dictionary = {
	Element.enm.ICE: _ice_button,
	Element.enm.FIRE: _fire_button,
	Element.enm.NATURE: _nature_button,
	Element.enm.DARKNESS: _darkness_button,
	Element.enm.IRON: _iron_button,
	Element.enm.ASTRAL: _astral_button,
	Element.enm.STORM: _storm_button,
}


#########################
###     Built-in      ###
#########################

func _ready():
	for element in _button_map.keys():
		var button: UnitButton = _button_map[element]
		button.always_show_count()
		button.set_count(0)
		
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button, element))
		button.pressed.connect(_on_button_pressed.bind(element))


#########################
###       Public      ###
#########################

func hide_roll_towers_button():
	_roll_towers_button.hide()
	_empty_unit_button_to_replace_roll_towers.show()
	

func update_element_level(element_levels: Dictionary):
	var current_tooltip_target: Button = ButtonTooltip.get_current_target()
	
	for element in element_levels.keys():
		var button: UnitButton = _button_map[element]
		var element_level: int = element_levels[element]
		button.set_count(element_level)
		
#		NOTE: need to manually refresh button tooltip,
#		otherwise it will keep showing old element level
#		which is confusing for the player
		if button == current_tooltip_target:
			_show_element_tooltip(button, element)


#########################
###      Private      ###
#########################

func _show_element_tooltip(button: Button, element: Element.enm):
	var local_player: Player = PlayerManager.get_local_player()
	var tooltip: String = RichTexts.get_research_text(element, local_player)
	ButtonTooltip.show_tooltip(button, tooltip)


#########################
###     Callbacks     ###
#########################

func _on_button_mouse_entered(button: Button, element: Element.enm):
	_show_element_tooltip(button, element)


func _on_button_pressed(element: Element.enm):
	EventBus.player_requested_to_research_element.emit(element)


func _on_roll_towers_button_pressed():
	EventBus.player_requested_to_roll_towers.emit()
