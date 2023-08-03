extends Control

# Displays detailed information about the stats of the
# currently selected tower. Hidden by default. Becomes
# visible when player pushes the expand button in the
# TowerInfoHeader.


var _current_tower: Tower = null

@onready var _tower_stat_int_labels: Array = get_tree().get_nodes_in_group("tower_stat_int")
@onready var _tower_stat_float_labels: Array = get_tree().get_nodes_in_group("tower_stat_float")
@onready var _tower_stat_percent_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent")
@onready var _tower_stat_percent_signed_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent_signed")
@onready var _tower_stat_multiplier_labels: Array = get_tree().get_nodes_in_group("tower_stat_multiplier")
@onready var _tower_details_label: RichTextLabel = $VBoxContainer/MarginContainer/VBoxContainer/MultiboardContainer/TowerDetailsLabel
@onready var _level_x_at_label: Label = %LevelXAt
@onready var _exp_for_next_level_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer2/VeteranContainer/ExperienceForNextLevel


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)

	_on_selected_unit_changed()


func _on_selected_unit_changed(_prev_unit = null):
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit != null && selected_unit is Tower:
# 		NOTE: show() is not called here because tower
# 		tooltip is shown when a button in tooltip header is
# 		pressed
		set_tower_tooltip_text(selected_unit)
	else:
		hide()


#########################
###       Public      ###
#########################

func set_tower_tooltip_text(tower):
	_current_tower = tower

#	NOTE: don't set tooltips for towers that haven't been
#	added to scene tree yet because their _ready() functions
#	haven't been called so they aren't setup completely.
#	This can happen while hovering over tower build buttons.
	if !tower.is_inside_tree():
		return

	for tower_stat_label in _tower_stat_int_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _int_format(stat)

	for tower_stat_label in _tower_stat_float_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _float_format(stat)
	
	for tower_stat_label in _tower_stat_percent_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _percent_format(stat)
	
	for tower_stat_label in _tower_stat_percent_signed_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _percent_signed_format(stat)
	
	for tower_stat_label in _tower_stat_multiplier_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _multiplier_format(stat)

	_update_exp_for_next_lvl_labels(tower)
	
	var tower_details_text: String = _get_tower_details_text(tower)
	_tower_details_label.clear()
	_tower_details_label.append_text(tower_details_text)


func set_tower(tower_node):
	set_tower_tooltip_text(tower_node)


#########################
###      Private      ###
#########################

func _get_stat(tower_stat_label: Label, tower):
	var stat_name = tower_stat_label.get_name()
	var getter_name = "get_" + Utils.camel_to_snake(stat_name)
	var stat = tower.call(getter_name)
	return stat

func _int_format(num: float) -> String:
	# Determine the appropriate suffix for the number
	var suffix = ""
	if num >= 1_000_000_000_000:
		num /= 1_000_000_000_000
		suffix = "T"
	elif num >= 1_000_000_000:
		num /= 1_000_000_000
		suffix = "G"
	elif num >= 1_000_000:
		num /= 1_000_000
		suffix = "M"

	# Convert the number to a string and handle the fractional part
	var num_str = ""
	if num >= 1:
		num_str = str(int(num))
	else:
		num_str = "0"
	var frac_str = ""
	if suffix != "":
		frac_str = ".%d" % ((num - int(num)) * 100)
	
	# Add commas to the integer part of the number
	var digits = num_str.length()
	if digits > 3:
		num_str = num_str.substr(0, digits % 3) + "," + num_str.substr(digits % 3)
		for i in range(digits - digits % 3 - 3, -1, -3):
			num_str = num_str.substr(0, i+1) + "," + num_str.substr(i+1)
	
	# Combine the integer part, fractional part, and suffix into the final string
	return num_str + frac_str + suffix

func _percent_signed_format(number, base = 0.0) -> String:
	var sign_str = ""
	match sign(number - base):
		-1.0: sign_str = "-"
		1.0: sign_str = "+"
	return "%s%d%%" % [sign_str, abs(number - base) * 100]

func _multiplier_format(number) -> String:
	return "x%.2f" % number

func _percent_format(number) -> String:
	return "%d%%" % (number * 100)

func _float_format(number) -> String:
	return "%.2f" % number


func _update_exp_for_next_lvl_labels(tower: Tower):
	var next_level: int = tower.get_level() + 1
	var exp_for_next_level: int = Experience.get_exp_for_level(next_level)
	
	if tower.reached_max_level():
		_level_x_at_label.text = "Max level reached!"
		_exp_for_next_level_label.text = ""
	else:
		_level_x_at_label.text = "Level %s at" % str(next_level)
		_exp_for_next_level_label.text = str(exp_for_next_level)


func _get_tower_details_text(tower: Tower) -> String:
	var text: String = ""
	
	var tower_multiboard: MultiboardValues = tower.on_tower_details()
	var item_multiboard_list: Array[MultiboardValues] = tower.get_item_tower_details()

	var all_multiboard_list: Array[MultiboardValues] = item_multiboard_list
	all_multiboard_list.insert(0, tower_multiboard)

	text += "[color=GOLD]Tower Details:[/color]\n \n"

	text += "[table=2]"

	for multiboard in all_multiboard_list:
		for row in range(0, multiboard.size()):
			var key: String = multiboard.get_key(row)
			var value: String = multiboard.get_value(row)

			text += "[cell]%s:[/cell][cell]%s[/cell]\n" % [key, value]

	text += "[/table]"

	return text


func _on_refresh_timer_timeout():
	if _current_tower != null:
		set_tower_tooltip_text(_current_tower)
