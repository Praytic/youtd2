extends Control


signal start_wave(wave_index)
signal stop_wave()

@onready var element_buttons_parent = $MarginContainer/HBoxContainer


func _ready():
	if FF.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	if OS.is_debug_build() and FF.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	for element_button in element_buttons_parent.get_children():
		element_button.pressed.connect(_on_element_button_pressed.bind(element_button))
	

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


# NOTE: if right menu bar is hidden with escape, then
# "button_exited()" signals are not emitted, so we have to
# manually hide button tooltip
func _on_right_menu_bar_hidden():
	$ButtonTooltip.hide()
