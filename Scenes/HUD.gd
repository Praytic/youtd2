extends Control


signal start_wave(wave_index)
signal stop_wave()


func _ready():
	$TowerTooltip.hide()


func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")


func _on_MissleT1_mouse_entered():
	_on_TowerButton_mouse_entered($BuildBar/MissleT1)


func _on_MissleT1_mouse_exited():
	_on_GenericButton_mouse_exited()


func _on_GunT1_mouse_entered():
	_on_TowerButton_mouse_entered($BuildBar/GunT1)


func _on_GunT1_mouse_exited():
	_on_GenericButton_mouse_exited()


# TODO: connect button signals directly to the general entered/exited slots,
# without using specific slots for each button.
func _on_TowerButton_mouse_entered(tower_button):
	var tower_id = tower_button.tower_id
	$TowerTooltip.set_tower_id(tower_id)
	$TowerTooltip.show()


func _on_GenericButton_mouse_exited():
	$TowerTooltip.hide()


func _on_Camera_camera_moved(direction):
	$Hints.hide()


func _on_Camera_camera_zoomed():
	$Hints.hide()
