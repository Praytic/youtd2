class_name HUD extends Control


signal start_wave(wave_index)
signal stop_wave()


@onready var _wave_status: Control = $WaveStatus
@onready var _error_message_container: VBoxContainer = $MarginContainer2/ErrorMessageContainer
@onready var _normal_message_container: VBoxContainer = $MarginContainer3/NormalMessageContainer


func _ready():
	if Config.minimap_enabled():
		$Minimap.call_deferred("create_instance")
	if OS.is_debug_build() and Config.dev_controls_enabled():
		$DevControls.call_deferred("create_instance")
	

func get_error_message_container() -> VBoxContainer:
	return _error_message_container


func get_normal_message_container() -> VBoxContainer:
	return _normal_message_container


func _on_TooltipHeader_expanded(expand):
	if expand:
		$TowerTooltip.show()
		_wave_status.hide()
	else:
		$TowerTooltip.hide()
		_wave_status.show()


func _on_research_button_pressed():
	$ResearchMenu.visible = !$ResearchMenu.visible
