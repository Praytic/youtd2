extends Control

# Displays name and instance id of the currently selected
# unit. Contains an button which toggles the tower info
# panel, if the selected unit is a tower.


signal expanded(expand)


@onready var _tooltip_labels: Array = get_tree().get_nodes_in_group("tooltip_variable")
@onready var _expand_button: Button = get_node("%ExpandButton")


#########################
###       Public      ###
#########################

func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)

	hide()


func _on_selected_unit_changed(_prev_unit = null):
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit != null:
		set_header_unit(selected_unit)
		show()
	else:
		_expand_button.set_pressed_no_signal(false)
		_expand_button.icon.region.position.x = 256
		hide()

#		NOTE: emit expanded signal so that if wave status
#		was hidden, it becomes visible again. Should rework
#		for this to be more explicit
		expanded.emit(false)


func set_header_unit(unit):
	for label in _tooltip_labels:
		var stat = _get_stat(label, unit)
		label.text = str(stat)
	
	_expand_button.set_visible(unit is Tower)

	visible = unit is Tower || unit is Creep

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
		icon_atlas.region.position.x = icon_atlas.region.size.x
	else:
		icon_atlas.region.position.x = 0
	expanded.emit(button_pressed)
