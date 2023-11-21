class_name ButtonTooltip extends PanelContainer


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.


static var _global_self: ButtonTooltip = null

@export var _label: RichTextLabel

var _current_button: Button = null


func _ready():
	ButtonTooltip._global_self = self


static func show_tooltip(button: Button, tooltip: String):
	if ButtonTooltip._global_self == null:
		return

	_global_self._show_tooltip(button, tooltip)


func _show_tooltip(button: Button, tooltip: String):
	_clear_current_button()

	_current_button = button
	_current_button.mouse_exited.connect(_clear_current_button)
	_current_button.tree_exiting.connect(_clear_current_button)
	_current_button.hidden.connect(_clear_current_button)

	_label.clear()
	_label.append_text(tooltip)

	show()


func _clear_current_button():
	if _current_button != null && is_instance_valid(_current_button):
		_current_button.mouse_exited.disconnect(_clear_current_button)
		_current_button.tree_exiting.disconnect(_clear_current_button)
		_current_button.hidden.disconnect(_clear_current_button)

	_current_button = null
	hide()
