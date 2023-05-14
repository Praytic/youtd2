extends Control

@onready var _element_to_button_map: Dictionary = {
	Tower.Element.ICE: $VBoxContainer/IceButton,
	Tower.Element.NATURE: $VBoxContainer/NatureButton,
	Tower.Element.FIRE: $VBoxContainer/FireButton,
	Tower.Element.ASTRAL: $VBoxContainer/AstralButton,
	Tower.Element.DARKNESS: $VBoxContainer/DarknessButton,
	Tower.Element.IRON: $VBoxContainer/IronButton,
	Tower.Element.STORM: $VBoxContainer/StormButton,
}

var _hovered_button_element: Tower.Element = Tower.Element.NONE


func _ready():
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]

		button.pressed.connect(_on_button_pressed.bind(element))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(element))
		button.mouse_exited.connect(_on_button_mouse_exited)

	KnowledgeTomesManager.knowledge_tomes_change.connect(_on_knowledge_tomes_change)

	_on_knowledge_tomes_change(0)


func _on_button_pressed(element: Tower.Element):
	ElementLevel.increment(element)

	var cost: int = ElementLevel.get_research_cost(element)
	KnowledgeTomesManager.spend(cost)

	refresh_button_tooltip()


func _on_button_mouse_entered(element: Tower.Element):
	EventBus.research_button_mouse_entered.emit(element)
	_hovered_button_element = element


func _on_button_mouse_exited():
	EventBus.research_button_mouse_exited.emit()
	_hovered_button_element = Tower.Element.NONE


func _on_knowledge_tomes_change(_value):
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]
		var can_afford: bool = ElementLevel.can_afford_research(element)

		button.set_disabled(!can_afford)

	refresh_button_tooltip()


func refresh_button_tooltip():
	if _hovered_button_element != Tower.Element.NONE:
		_on_button_mouse_entered(_hovered_button_element)
