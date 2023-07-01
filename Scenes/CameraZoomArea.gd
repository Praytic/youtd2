extends Control

# NOTE: capture input in this control and pass it to camera so that camera's
# zoom can be ordered behind certain UI elements like BottomMenuBar. This way
# camera can be zoomed while mouse is outside BottomMenuBar but while mouse
# is inside BottomMenuBar, it will scroll the menu without also changing
# camera zoom

func _unhandled_input(event):
	Globals.camera._zoom(event)
