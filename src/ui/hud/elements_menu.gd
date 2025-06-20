class_name ElementsMenu extends PanelContainer


@export var _ice_button: ElementButton
@export var _fire_button: ElementButton
@export var _nature_button: ElementButton
@export var _darkness_button: ElementButton
@export var _iron_button: ElementButton
@export var _astral_button: ElementButton
@export var _storm_button: ElementButton
@export var _roll_towers_button: Button

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
	var game_mode_is_build: bool = Globals.get_game_mode() == GameMode.enm.BUILD
	if game_mode_is_build:
		_hide_roll_towers_button()

	for element in _button_map.keys():
		var button: ElementButton = _button_map[element]
		button.set_level(0)
		
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button, element))
		button.pressed.connect(_on_button_pressed.bind(element))


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	local_player.element_level_changed.connect(_on_element_level_changed)
	_on_element_level_changed()

	local_player.roll_was_disabled.connect(_on_local_player_roll_was_disabled)


#########################
###      Private      ###
#########################

func _hide_roll_towers_button():
	_roll_towers_button.hide()


func _show_element_tooltip(button: Button, element: Element.enm):
	var local_player: Player = PlayerManager.get_local_player()
	var tooltip: String = RichTexts.get_research_text(element, local_player)
	ButtonTooltip.show_tooltip(button, tooltip)


#########################
###     Callbacks     ###
#########################

func _on_local_player_roll_was_disabled():
	_hide_roll_towers_button()


func _on_element_level_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var element_levels: Dictionary = local_player.get_element_level_map()
	
	var current_tooltip_target: Button = ButtonTooltip.get_current_target()
	
	for element in element_levels.keys():
		var button: ElementButton = _button_map[element]
		var element_level: int = element_levels[element]
		button.set_level(element_level)
		
#		NOTE: need to manually refresh button tooltip,
#		otherwise it will keep showing old element level
#		which is confusing for the player
		if button == current_tooltip_target:
			_show_element_tooltip(button, element)


func _on_button_mouse_entered(button: Button, element: Element.enm):
	_show_element_tooltip(button, element)


func _on_button_pressed(element: Element.enm):
	EventBus.player_requested_to_research_element.emit(element)


func _on_roll_towers_button_pressed():
	EventBus.player_requested_to_roll_towers.emit()


func _on_close_button_pressed():
	hide()


func _on_roll_towers_button_mouse_entered():
	var tooltip: String = tr("ROLL_TOWERS_BUTTON_TOOLTIP")
	ButtonTooltip.show_tooltip(_roll_towers_button, tooltip)
