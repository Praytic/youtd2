extends PanelContainer


@export var _old_item_names: CheckBox
@export var _damage_numbers: CheckBox
@export var _enable_sfx: CheckBox
@export var _enable_unreleased_towers: CheckBox
@export var _mouse_scroll: Slider
@export var _keyboard_scroll: Slider

var _setting_to_checkbox_map: Dictionary
var _setting_to_slider_map: Dictionary


func _ready():
#	NOTE: need to init this in ready() because this map uses @export vars which are not ready before ready()
	_setting_to_checkbox_map = {
		Settings.SHOW_OLD_ITEM_NAMES: _old_item_names,
		Settings.SHOW_ALL_DAMAGE_NUMBERS: _damage_numbers,
		Settings.ENABLE_SFX: _enable_sfx,
		Settings.ENABLE_UNRELEASED_TOWERS: _enable_unreleased_towers,
	}
	
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = Settings.get_bool_setting(setting)
		checkbox.set_pressed(enabled)
		
	_setting_to_slider_map = {
		Settings.MOUSE_SCROLL: _mouse_scroll,
		Settings.KEYBOARD_SCROLL: _keyboard_scroll,
	}
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = Settings.get_setting(setting) as float
		slider.value = value


func _on_close_button_pressed():
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = checkbox.is_pressed()
		Settings.set_setting(setting, enabled)
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = slider.value
		Settings.set_setting(setting, value)
	
	Settings.flush()
	
	hide()
