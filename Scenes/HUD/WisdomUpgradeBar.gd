class_name WisdomUpgradeBar extends HBoxContainer


# UI element for WisdomUpgradeMenu.


signal minus_pressed()
signal plus_pressed()
signal max_pressed()

@export var _name_label: Label
@export var _progress_bar: ProgressBar
@export var _progress_label: Label


var _current_value: int = 0
var _max_value: int = 0
var _upgrade_id: int


#########################
###     Built-in      ###
#########################

func _ready():
	_update_bar()


#########################
###       Public      ###
#########################


func set_max_value(max_value: int):
	_max_value = max_value
	_update_bar()


func get_value() -> int:
	return _current_value


func set_value(value: int):
	_current_value = clampi(value, 0, _max_value)
	_update_bar()


#########################
###      Private      ###
#########################

func _update_bar():
	_progress_bar.value = (float(_current_value) / _max_value) * 100
	_progress_label.text = "%d/%d" % [_current_value, _max_value]


#########################
###     Callbacks     ###
#########################

func _on_minus_button_pressed():
	minus_pressed.emit()


func _on_plus_button_pressed():
	plus_pressed.emit()


func _on_max_button_pressed():
	max_pressed.emit()


#########################
###       Static      ###
#########################

static func make(upgrade_id: int) -> WisdomUpgradeBar:
	var bar: WisdomUpgradeBar = Preloads.wisdom_upgrade_bar.instantiate()

	bar._upgrade_id = upgrade_id
	
	var upgrade_name: String = WisdomUpgradeProperties.get_upgrade_name(upgrade_id)
	var description: String = WisdomUpgradeProperties.get_description(upgrade_id)
	bar._name_label.text = upgrade_name
	bar._name_label.tooltip_text = description
	
	return bar
	
