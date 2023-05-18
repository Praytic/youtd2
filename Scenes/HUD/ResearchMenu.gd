extends Control

@onready var _element_to_button_map: Dictionary = {
	Element.enm.ICE: $VBoxContainer/IceButton,
	Element.enm.NATURE: $VBoxContainer/NatureButton,
	Element.enm.FIRE: $VBoxContainer/FireButton,
	Element.enm.ASTRAL: $VBoxContainer/AstralButton,
	Element.enm.DARKNESS: $VBoxContainer/DarknessButton,
	Element.enm.IRON: $VBoxContainer/IronButton,
	Element.enm.STORM: $VBoxContainer/StormButton,
}

var _hovered_button_element: Element.enm = Element.enm.NONE


func _ready():
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]

		button.pressed.connect(_on_button_pressed.bind(element))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(element))
		button.mouse_exited.connect(_on_button_mouse_exited)

	KnowledgeTomesManager.knowledge_tomes_change.connect(_on_knowledge_tomes_change)

	_on_knowledge_tomes_change()


func _on_button_pressed(element: Element.enm):
	ElementLevel.increment(element)

	var cost: int = ElementLevel.get_research_cost(element)
	KnowledgeTomesManager.spend(cost)

	refresh_button_tooltip()


func _on_button_mouse_entered(element: Element.enm):
	EventBus.research_button_mouse_entered.emit(element)
	_hovered_button_element = element


func _on_button_mouse_exited():
	EventBus.research_button_mouse_exited.emit()
	_hovered_button_element = Element.enm.NONE


func _on_knowledge_tomes_change():
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]
		var can_afford: bool = ElementLevel.can_afford_research(element)

		button.set_disabled(!can_afford)

	refresh_button_tooltip()


func refresh_button_tooltip():
	if _hovered_button_element != Element.enm.NONE:
		_on_button_mouse_entered(_hovered_button_element)
