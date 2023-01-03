extends StaticBody2D


func _unhandled_input(event):
	if event is InputEventMagnifyGesture:
		print(event)
	elif event is InputEventMouseButton:
		print(event)
