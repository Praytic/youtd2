extends Control


onready var _tower_stat_int_labels: Array = get_tree().get_nodes_in_group("tower_stat_int")
onready var _tower_stat_float_labels: Array = get_tree().get_nodes_in_group("tower_stat_float")
onready var _tower_stat_percent_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent")
onready var _tower_stat_percent_signed_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent_signed")
onready var _tower_stat_multiplier_labels: Array = get_tree().get_nodes_in_group("tower_stat_multiplier")
onready var _multiboard_container: MarginContainer = $VBoxContainer/MarginContainer/VBoxContainer/MultiboardContainer
onready var _multiboard_grid: GridContainer = $VBoxContainer/MarginContainer/VBoxContainer/MultiboardContainer/VBoxContainer/MarginContainer2/MultiboardGrid


func _ready():
	pass


#########################
###       Public      ###
#########################

func set_tower_tooltip_text(tower):
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

	var multiboard_values: MultiboardValues = tower.on_tower_details()

	_load_multiboard(multiboard_values)


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


func _load_multiboard(multiboard: MultiboardValues):
#	Hide multiboard display if there are no rows
	var multiboard_has_rows: bool = multiboard.size() > 0
	_multiboard_container.visible = multiboard_has_rows

#	Expand GridContainer if it's smaller than multiboard
	var current_row_count: int = int(_multiboard_grid.get_child_count() / 2.0)
	var row_count_is_enough: bool = current_row_count >= multiboard.size()

	if !row_count_is_enough:
		var rows_to_add: int = multiboard.size() - current_row_count

		for _row in range(0, rows_to_add):
			var key_label: Label = Label.new()
			key_label.align = Label.ALIGN_LEFT

			var value_label: Label = Label.new()
			value_label.align = Label.ALIGN_RIGHT

			_multiboard_grid.add_child(key_label)
			_multiboard_grid.add_child(value_label)

#	Load values from multiboard into labels
	for child in _multiboard_grid.get_children():
		child.hide()

	for row in range(0, multiboard.size()):
		var key: String = multiboard.get_key(row)
		var value: String = multiboard.get_value(row)

		var key_label_index: int = row * 2
		var value_label_index: int = row * 2 + 1

		var key_label: Label = _multiboard_grid.get_child(key_label_index)
		var value_label: Label = _multiboard_grid.get_child(value_label_index)

		key_label.text = key
		value_label.text = value

		key_label.show()
		value_label.show()
