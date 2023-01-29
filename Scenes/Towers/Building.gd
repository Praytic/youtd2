class_name Building
extends KinematicBody2D


var building_in_progress: bool = false
var is_selected: bool = false
const cell_size: int = 128


func _ready():
	$Base.hide()
	$Selection.hide()
	z_index = 999


func build_init():
	building_in_progress = true


func _unhandled_input(event):
	if event is InputEventMouseButton and not building_in_progress:
		if event.get_button_index() == BUTTON_LEFT or event.get_button_index() == BUTTON_RIGHT:
			var is_inside: bool = Geometry.is_point_in_polygon(
				$CollisionShape2D.get_local_mouse_position(), 
				$CollisionShape2D.polygon)
			if is_inside:
				_select()
			else:
				if is_selected:
					_unselect()


func _select():
	$Selection.show()
	is_selected = true
#	emit_signal("")


func _unselect():
	$Selection.hide()
	is_selected = false
	emit_signal("unselected")
