extends PanelContainer


@export var _old_item_names: CheckBox
@export var _damage_numbers: CheckBox
@export var _enable_sfx: CheckBox
@export var _enable_unreleased_towers: CheckBox
@export var _enable_mouse_scroll: CheckBox
@export var _show_combat_log: CheckBox
@export var _mouse_scroll: Slider
@export var _keyboard_scroll: Slider
@export var _interface_size_button_group: ButtonGroup


var _setting_to_checkbox_map: Dictionary
var _setting_to_slider_map: Dictionary
var _setting_to_button_group_map: Dictionary


func _ready():
#	NOTE: need to init this in ready() because this map uses @export vars which are not ready before ready()
	_setting_to_checkbox_map = {
		Settings.SHOW_OLD_ITEM_NAMES: _old_item_names,
		Settings.SHOW_ALL_DAMAGE_NUMBERS: _damage_numbers,
		Settings.ENABLE_SFX: _enable_sfx,
		Settings.ENABLE_UNRELEASED_TOWERS: _enable_unreleased_towers,
		Settings.ENABLE_MOUSE_SCROLL: _enable_mouse_scroll,
		Settings.SHOW_COMBAT_LOG: _show_combat_log,
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
	
	_setting_to_button_group_map = {
		Settings.INTERFACE_SIZE: _interface_size_button_group,
	}
	
	for setting in _setting_to_button_group_map.keys():
		var button_group: ButtonGroup = _setting_to_button_group_map[setting]
		var value: String = Settings.get_setting(setting)
		for button in button_group.get_buttons():
			if button.text == value:
				button.set_pressed_no_signal(true)
				break
	
	Settings.interface_size_changed.connect(_apply_new_interface_size)


func _apply_new_interface_size(size_label: String):
	var new_scale: float
	match size_label:
		"Small": new_scale = 0.75
		"Medium": new_scale = 1
		"Large": new_scale = 1.25
	get_tree().root.content_scale_factor = new_scale


func _on_close_button_pressed():
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = checkbox.is_pressed()
		Settings.set_setting(setting, enabled)
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = slider.value
		Settings.set_setting(setting, value)
	
	for setting in _setting_to_button_group_map.keys():
		var button_group: ButtonGroup = _setting_to_button_group_map[setting]
		var value: float = button_group.get_pressed_button().text
		Settings.set_setting(setting, value)
	
	Settings.flush()
	
	hide()
