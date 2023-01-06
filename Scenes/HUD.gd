extends Control


signal start_wave(wave_index)
signal stop_wave()


onready var camera: Camera2D = get_node(@"/root/GameScene/DefaultCamera")


func _ready():
	camera.connect("camera_moved", self, "_on_camera_moved")
	camera.connect("camera_zoomed", self, "_on_camera_zoomed")


func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")


func _on_camera_moved(_vector):
	$Hints.hide()

func _on_camera_zoomed():
	$Hints.hide()
