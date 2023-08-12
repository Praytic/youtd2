extends Control

@onready var _element_to_button_map: Dictionary = {
	Element.enm.ICE: { "button": ice_button, "label": ice_button_label },
	Element.enm.NATURE: { "button": nature_button, "label": nature_button_label },
	Element.enm.FIRE: { "button": fire_button, "label": fire_button_label },
	Element.enm.ASTRAL: { "button": astral_button, "label": astral_button_label },
	Element.enm.DARKNESS: { "button": darkness_button, "label": darkness_button_label },
	Element.enm.IRON: { "button": iron_button, "label": iron_button_label },
	Element.enm.STORM: { "button": storm_button, "label": storm_button_label },
}

@export var ice_button_label: RichTextLabel
@export var fire_button_label: RichTextLabel
@export var iron_button_label: RichTextLabel
@export var darkness_button_label: RichTextLabel
@export var storm_button_label: RichTextLabel
@export var astral_button_label: RichTextLabel
@export var nature_button_label: RichTextLabel

@export var ice_button: Button
@export var fire_button: Button
@export var iron_button: Button
@export var darkness_button: Button
@export var storm_button: Button
@export var astral_button: Button
@export var nature_button: Button

var _hovered_button_element: Element.enm = Element.enm.NONE


func _ready():
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]["button"]

		button.pressed.connect(_on_button_pressed.bind(element))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(element))
		button.mouse_exited.connect(_on_button_mouse_exited)
		
		refresh_button_label(element, false)

	KnowledgeTomesManager.knowledge_tomes_change.connect(_on_knowledge_tomes_change)

	_on_knowledge_tomes_change()


func _on_button_pressed(element: Element.enm):
	ElementLevel.increment(element)

	var cost: int = ElementLevel.get_research_cost(element)
	KnowledgeTomesManager.spend(cost)

	refresh_button_label(element, _hovered_button_element == element)
	refresh_button_tooltip()


func _on_button_mouse_entered(element: Element.enm):
	EventBus.research_button_mouse_entered.emit(element)
	refresh_button_label(element, true)
	_hovered_button_element = element


func _on_button_mouse_exited():
	EventBus.research_button_mouse_exited.emit()
	refresh_button_label(_hovered_button_element, false)
	_hovered_button_element = Element.enm.NONE


func _on_knowledge_tomes_change():
	for element in _element_to_button_map.keys():
		var button: Button = _element_to_button_map[element]["button"]
		var can_afford: bool = ElementLevel.can_afford_research(element)

		button.set_disabled(!can_afford)

	refresh_button_tooltip()


func refresh_button_tooltip():
	if _hovered_button_element != Element.enm.NONE:
		_on_button_mouse_entered(_hovered_button_element)


func refresh_button_label(element: Element.enm, hovered: bool):
	var label: RichTextLabel = _element_to_button_map[element]["label"]
	label.clear()
	label.append_text(RichTexts.get_research_button_label(element, hovered))
