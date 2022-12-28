extends StaticBody2D


class_name Building


var building_in_progress: bool = false


func _ready():
	$Base.hide()
	z_index = 999


func build_init():
	building_in_progress = true
