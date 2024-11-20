class_name MenuExpandingButton extends Button


# This button is used to toggle a menu on and off. When used
# as a group of buttons, they can toggle one menu at a time.
# When a menu is open, this button shows a rectangle between
# the button and the menu - to visually connect the two UI
# elements.


# NOTE: set the "_menu" variable to the menu which this
# button should toggle
@export var _menu: Control
@export var _panel: PanelContainer


#########################
###     Built-in      ###
#########################

func _ready():
	_menu.hidden.connect(_on_menu_hidden)


#########################
###     Callbacks     ###
#########################

func _on_toggled(button_is_pressed: bool):
	_panel.visible = button_is_pressed
	_menu.visible = button_is_pressed


func _on_menu_hidden():
	set_pressed(false)
