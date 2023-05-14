class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()

@onready var element_buttons_parent = $MarginContainer/HBoxContainer
@onready var _wave_status: Control = $WaveStatus
@onready var _error_message_container: VBoxContainer = $MarginContainer2/ErrorMessageContainer
@onready var _normal_message_container: VBoxContainer = $MarginContainer3/NormalMessageContainer


func _ready():
	if FF.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	if OS.is_debug_build() and FF.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	
	for element_button in element_buttons_parent.get_children():
		element_button.pressed.connect(_on_element_button_pressed.bind(element_button))
	

func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_element_button_pressed(element_button):
	$MarginContainer.hide()
	
	var element: Tower.Element = element_button.element
	$RightMenuBar.set_element(element)


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
		_wave_status.hide()
	else:
		$TowerTooltip.hide()
		_wave_status.show()


func _on_ItemMenuButton_pressed():
	var element: Tower.Element = Tower.Element.NONE
	$RightMenuBar.set_element(element)


# NOTE: if right menu bar is hidden with escape, then
# "button_exited()" signals are not emitted, so we have to
# manually hide button tooltip
func _on_right_menu_bar_hidden():
	$ButtonTooltip.hide()


func _on_research_button_pressed():
	$ResearchMenu.visible = !$ResearchMenu.visible
