class_name TowerInfo extends GridContainer

# Displays detailed information about the stats of the
# currently selected tower. Can be toggled in unit menu by
# pressing the "info" button.


@onready var _tower_stat_int_labels: Array = get_tree().get_nodes_in_group("tower_stat_int")
@onready var _tower_stat_float_labels: Array = get_tree().get_nodes_in_group("tower_stat_float")
@onready var _tower_stat_percent_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent")
@onready var _tower_stat_percent_signed_labels: Array = get_tree().get_nodes_in_group("tower_stat_percent_signed")
@onready var _tower_stat_multiplier_labels: Array = get_tree().get_nodes_in_group("tower_stat_multiplier")

@export var _tower_details_label: RichTextLabel
@export var _level_x_at_label: Label
@export var _exp_for_next_level_label: Label


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)


func _on_selected_unit_changed(_prev_unit):
	update_text()


func _on_refresh_timer_timeout():
	update_text()


#########################
###       Public      ###
#########################

func update_text():
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if !selected_unit is Tower:
		return

	var tower: Tower = selected_unit as Tower

#	NOTE: don't set tooltips for towers that haven't been
#	added to scene tree yet because their _ready() functions
#	haven't been called so they aren't setup completely.
#	This can happen while hovering over tower build buttons.
	if !tower.is_inside_tree():
		return

	for tower_stat_label in _tower_stat_int_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = TowerInfo.int_format(stat)

	for tower_stat_label in _tower_stat_float_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _float_format(stat)
	
	for tower_stat_label in _tower_stat_percent_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = Utils.format_percent(stat, 1)

	for tower_stat_label in _tower_stat_percent_signed_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _percent_signed_format(stat)
	
	for tower_stat_label in _tower_stat_multiplier_labels:
		var stat = _get_stat(tower_stat_label, tower)
		tower_stat_label.text = _multiplier_format(stat)

	_update_exp_for_next_lvl_labels(tower)
	
	var tower_ranges_text: String = _get_tower_ranges_text(tower)
	var tower_oils_text: String = _get_tower_oils_text(tower)
	var tower_details_text: String = _get_tower_details_text(tower)
	var combined_details_text: String = ""
	combined_details_text += tower_ranges_text
	combined_details_text += " \n"
	combined_details_text += " \n"
	combined_details_text += tower_oils_text
	combined_details_text += " \n"
	combined_details_text += " \n"
	combined_details_text += tower_details_text
	_tower_details_label.clear()
	_tower_details_label.append_text(combined_details_text)


#########################
###      Private      ###
#########################

func _get_stat(tower_stat_label: Label, tower):
	var stat_name = tower_stat_label.get_name()
	var getter_name = "get_" + Utils.camel_to_snake(stat_name)
	var stat = tower.call(getter_name)
	return stat

static func int_format(num: float) -> String:
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
	for i in range(digits - 3, 0, -3):
		num_str = num_str.insert(i, ",")
	
	# Combine the integer part, fractional part, and suffix into the final string
	return num_str + frac_str + suffix

func _percent_signed_format(number: float, base: float = 1.0) -> String:
	var diff_from_base: float = number - base
	var formatted: String = Utils.format_percent(diff_from_base, 0)

	if diff_from_base >= 0:
		formatted = "+%s" % formatted

	return formatted

func _multiplier_format(number) -> String:
	return "x%.2f" % number

func _float_format(number) -> String:
	return Utils.format_float(number, 2)


func _update_exp_for_next_lvl_labels(tower: Tower):
	var next_level: int = tower.get_level() + 1
	var exp_for_next_level: int = Experience.get_exp_for_level(next_level)
	
	if tower.reached_max_level():
		_level_x_at_label.text = "Max level reached!"
		_exp_for_next_level_label.text = ""
	else:
		_level_x_at_label.text = "Level %s at" % str(next_level)
		_exp_for_next_level_label.text = str(exp_for_next_level)


func _get_tower_oils_text(tower: Tower) -> String:
	var text: String = ""

	text += "[color=PURPLE]Tower Oils:[/color]\n"
	text += " \n"

	var oil_count_map: Dictionary = _get_oil_count_map(tower)

	var oil_name_list: Array = oil_count_map.keys()
	oil_name_list.sort()

	for oil_name in oil_name_list:
		var count: int = oil_count_map[oil_name]

		text += "%s x %s\n" % [str(count), oil_name]

	if oil_count_map.is_empty():
		text += "None"

	return text


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


func _get_tower_ranges_text(tower: Tower) -> String:
	var text: String = ""

	var attack_range: float = tower.get_range()
	var attack_range_string: String = Utils.format_float(attack_range, 0)

	var aura_list: Array[Aura] = tower.get_aura_list()
	
	text += "[color=GOLD]Ranges:[/color]\n \n"

	text += "[table=2]"

	text += "[cell]Attack Range:[/cell][cell][color=AQUA]%s[/color][/cell]\n" % attack_range_string

	if !aura_list.is_empty():
		var first_aura: Aura = aura_list.front()
		var aura_range: float = first_aura.get_range()
		var aura_range_string: String = Utils.format_float(aura_range, 0)

		text += "[cell]Aura Range:[/cell][cell][color=ORANGE]%s[/color][/cell]\n" % aura_range_string

	text += "[/table]"

	return text


func _get_oil_count_map(tower: Tower) -> Dictionary:
	var oil_list: Array[Item] = tower.get_item_container().get_oil_list()

	var oil_count_map: Dictionary = {}

	for oil in oil_list:
		var oil_id: int = oil.get_id()
		var oil_name: String = ItemProperties.get_display_name(oil_id)

		if !oil_count_map.has(oil_name):
			oil_count_map[oil_name] = 0

		oil_count_map[oil_name] += 1

	return oil_count_map
