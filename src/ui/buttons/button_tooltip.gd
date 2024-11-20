class_name ButtonTooltip extends PanelContainer


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip is
# displayed at a pre-defined position, not under mouse
# cursor.


enum Location {
	TOP,
	BOTTOM,
}


static var _tooltip_instance_top: ButtonTooltip = null
static var _tooltip_instance_bottom: ButtonTooltip = null
static var _current_button_global: Button = null

@export var _label: RichTextLabel

var _current_button: Button = null


static func setup_tooltip_instances(tooltip_top: ButtonTooltip, tooltip_bottom: ButtonTooltip):
	ButtonTooltip._tooltip_instance_top = tooltip_top
	ButtonTooltip._tooltip_instance_bottom = tooltip_bottom


static func show_tooltip(button: Button, tooltip: String, location: Location = Location.TOP):	
	if ButtonTooltip._tooltip_instance_top == null || ButtonTooltip._tooltip_instance_bottom == null:
		push_error("Tooltip instances weren't setup correctly: [%s, %s]" % [ButtonTooltip._tooltip_instance_top, ButtonTooltip._tooltip_instance_bottom])

		return
	
	var tooltip_instance: ButtonTooltip
	match location:
		Location.TOP: tooltip_instance = ButtonTooltip._tooltip_instance_top
		Location.BOTTOM: tooltip_instance = ButtonTooltip._tooltip_instance_bottom

	ButtonTooltip._tooltip_instance_top._clear_current_button()
	ButtonTooltip._tooltip_instance_bottom._clear_current_button()
	
	tooltip_instance._show_tooltip(button, tooltip)
	ButtonTooltip._current_button_global = button


static func get_current_target() -> Button:
	return ButtonTooltip._current_button_global


func _show_tooltip(button: Button, tooltip: String):
	_clear_current_button()

	_current_button = button
	_current_button.mouse_exited.connect(_clear_current_button)
	_current_button.tree_exited.connect(_clear_current_button)
	_current_button.hidden.connect(_clear_current_button)

	_label.clear()
	_label.append_text(tooltip)

	show()


func _clear_current_button():
	if _current_button != null && is_instance_valid(_current_button):
		_current_button.mouse_exited.disconnect(_clear_current_button)
		_current_button.tree_exited.disconnect(_clear_current_button)
		_current_button.hidden.disconnect(_clear_current_button)

	_current_button = null
	hide()
