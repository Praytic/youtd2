class_name WisdomUpgradeBar extends HBoxContainer


# UI element for WisdomUpgradeMenu.


signal minus_pressed()
signal plus_pressed()
signal max_pressed()

@export var _progress_bar: ProgressBar
@export var _progress_label: Label

@export var wisdom_upgrade: WisdomUpgrade.enm
@export var icon_texture: Texture
@export var _texture_rect: TextureRectWithRichTooltip


var _current_value: int = 0


#########################
###     Built-in      ###
#########################

func _ready():
	_texture_rect.texture = icon_texture


#########################
###       Public      ###
#########################

func get_value() -> int:
	return _current_value


func set_value(value: int):
	_current_value = clampi(value, 0, 8)
	_progress_bar.value = (_current_value / 8.0) * 100
	_progress_label.text = "%d/8" % _current_value


#########################
###     Callbacks     ###
#########################

func _on_minus_button_pressed():
	minus_pressed.emit()


func _on_plus_button_pressed():
	plus_pressed.emit()


func _on_max_button_pressed():
	max_pressed.emit()
