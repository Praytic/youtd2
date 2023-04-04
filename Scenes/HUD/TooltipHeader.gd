extends Control


signal expanded(expand)


@onready var _tooltip_labels: Array = get_tree().get_nodes_in_group("tooltip_variable")
@onready var _expand_button: Button = get_node("%ExpandButton")


#########################
###       Public      ###
#########################

func set_header_unit(unit):
	if unit is ItemDrop:
		hide()
		return
	
	for label in _tooltip_labels:
		var stat = _get_stat(label, unit)
		label.text = str(stat)
	
	if not unit is Tower:
		_expand_button.hide()

func reset():
	hide()
	_expand_button.set_pressed_no_signal(false)
	_expand_button.icon.atlas.region.position.x = 0

#########################
###      Private      ###
#########################

func _get_stat(label: Label, unit):
	var stat_name = label.get_name()
	var getter_name = "get_" + Utils.camel_to_snake(stat_name)
	var stat = unit.call(getter_name)
	return stat


#########################
###     Callbacks     ###
#########################

func _on_ExpandButton_toggled(button_pressed):
	var icon_atlas = _expand_button.icon
	if button_pressed:
		icon_atlas.atlas.region.position.x = icon_atlas.region.size.x
	else:
		icon_atlas.atlas.region.position.x = 0
	expanded.emit(button_pressed)
