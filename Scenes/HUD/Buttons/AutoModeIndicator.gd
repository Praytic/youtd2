class_name AutoModeIndicator extends Control

# Displays a sparkly animation while autocast is in auto
# mode. Nothing while autocast is in manual mode.

@export var _texture_rect: TextureRect


var _autocast: Autocast = null


func set_autocast(autocast: Autocast):
	_autocast = autocast


func _process(_delta: float):
	_texture_rect.visible = _autocast != null && _autocast.auto_mode_is_enabled()
