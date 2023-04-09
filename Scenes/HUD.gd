extends Control


signal start_wave(wave_index)
signal stop_wave()

@onready var element_buttons_parent = $MarginContainer/HBoxContainer
@onready var _dev_controls = $DevControls


func _ready():
	for element_button in element_buttons_parent.get_children():
		element_button.pressed.connect(_on_element_button_pressed.bind(element_button))
	
	if not OS.is_debug_build() or not FF.dev_controls_enabled():
		_dev_controls.hide()
	
	$TowerTooltip.hide()
	$TooltipHeader.reset()


func _on_ObjectYSort_child_entered_tree(node):
		node.selected.connect(_on_Unit_selected.bind(node))
		node.unselected.connect(_on_Unit_unselected.bind(node))


func _on_Unit_selected(unit):
	if unit is Tower:
		$TowerTooltip.set_tower_tooltip_text(unit)
		$TowerInventory.set_tower(unit)

	$TowerInventory.visible = unit is Tower
	$TowerTooltip.hide()
	$TooltipHeader.set_header_unit(unit)


func _on_Unit_unselected(_unit):
	$TowerTooltip.hide()
	$TooltipHeader.reset()
	$TowerInventory.hide()


func _on_element_button_pressed(element_button):
	$MarginContainer.hide()
	
	var element: Tower.Element = element_button.element
	$RightMenuBar.set_element(element)


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
	else:
		$TowerTooltip.hide()


func _on_ItemMenuButton_pressed():
	var element: Tower.Element = Tower.Element.NONE
	$RightMenuBar.set_element(element)
