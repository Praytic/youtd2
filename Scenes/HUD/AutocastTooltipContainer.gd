extends VBoxContainer


# This script positions the tooltip so it's next to button.

@export var _tooltip: ButtonTooltip


func _process(_delta: float):
	var button: Button = _tooltip._current_button
	
	if button == null:
		return
	
	var new_pos: Vector2 = button.get_screen_position()
	
#	NOTE: position tooltip vertically either below or above
# 	the button. Below button by default. Switch to above
# 	button if tooltip doesn't fit between button and bottom
# 	of viewport.
	var tooltip_height: float = _tooltip.size.y
	var viewport_height: float = get_viewport().size.y
	var tooltip_goes_outside_bottom_of_viewport: bool = new_pos.y + tooltip_height > viewport_height
	if tooltip_goes_outside_bottom_of_viewport:
		new_pos.y -= tooltip_height

#	NOTE: position tooltip horizontally to the left of the
#	button
	new_pos.x -= _tooltip.size.x
	
	position = new_pos
