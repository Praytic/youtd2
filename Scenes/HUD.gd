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


func _on_Camera_camera_moved(_direction):
	remove_child($Hints)


func _on_Camera_camera_zoomed(_zoom_value):
	remove_child($Hints)


func _on_RightMenuBar_tower_info_requested(tower_id):
	$TowerTooltip.set_tower_id(tower_id)
	$TowerTooltip.show()


func _on_RightMenuBar_tower_info_canceled():
	$TowerTooltip.hide()


func _on_MobYSort_child_entered_tree(node):
	if node is Tower:
		node.connect("selected", self, "_on_Tower_selected", [node])
		node.connect("unselected", self, "_on_Tower_unselected")


func _on_Tower_selected(tower_node):
	$TowerTooltip.set_tower_id(tower_node.get_id())
	$TowerTooltip.show()


func _on_Tower_unselected():
	$TowerTooltip.hide()


func _on_BuildingMenuButton_pressed():
	remove_child($Hints2)
