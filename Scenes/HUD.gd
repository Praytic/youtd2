extends Control


signal start_wave(wave_index)
signal stop_wave()

@onready var element_buttons_parent = $MarginContainer/HBoxContainer


func _ready():
	for element_button in element_buttons_parent.get_children():
		element_button.connect("pressed",Callable(self,"_on_element_button_pressed").bind(element_button))
	
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")


func _on_Camera_updated(_direction):
	$Hints.hide()


func _on_RightMenuBar_tower_info_requested(tower_id):
	var tower = TowerManager.get_tower(tower_id)
	
	$TowerTooltip.set_tower_tooltip_text(tower)
	$TowerTooltip.hide()
	
	$TooltipHeader.set_header_unit(tower)
	$TooltipHeader.show()


func _on_RightMenuBar_tower_info_canceled():
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_RightMenuBar_item_info_requested(item_id):
	var item = TowerManager.get_tower(item_id)
	$TooltipHeader.set_header_unit(item)
	$TooltipHeader.show()


func _on_RightMenuBar_item_info_canceled():
	$TowerTooltip.hide()
	$TooltipHeader.hide()

func _on_MobYSort_child_entered_tree(node):
		node.connect("selected",Callable(self,"_on_Unit_selected").bind(node))
		node.connect("unselected",Callable(self,"_on_Unit_unselected").bind(node))


func _on_Unit_selected(unit):
	if unit is Tower:
		$TowerTooltip.set_tower_tooltip_text(unit)
	$TowerTooltip.hide()
	$TooltipHeader.set_header_unit(unit)
	$TooltipHeader.show()


func _on_Unit_unselected(unit):
	$TowerTooltip.hide()
	$TooltipHeader.hide()


func _on_MenuButton_pressed():
	$Hints2.hide()

func _on_element_button_pressed(element_button):
	$MarginContainer.hide()
	
	var element: int = element_button.element
	$RightMenuBar.set_element(element)


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
	else:
		$TowerTooltip.hide()


func _on_ItemMenuButton_pressed():
	var element: int = -1
	$RightMenuBar.set_element(element)
