class_name WisdomUpgradeBar extends HBoxContainer


# UI element for WisdomUpgradeMenu.


signal minus_pressed()
signal plus_pressed()
signal max_pressed()

@export var _icon: TextureRectWithRichTooltip
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
	
	var icon_path: String = WisdomUpgradeProperties.get_icon_path(upgrade_id)
	
	var icon_texture: Texture
	if ResourceLoader.exists(icon_path):
		icon_texture = load(icon_path)
	else:
		push_error("Invalid icon for wisdom upgrade: %s" % icon_path)
		icon_texture = Preloads.fallback_buff_icon
	
	bar._icon.texture = icon_texture
	
	var tooltip: String = WisdomUpgradeProperties.get_tooltip(upgrade_id)
	bar._icon.tooltip_text = tooltip

	return bar
	
