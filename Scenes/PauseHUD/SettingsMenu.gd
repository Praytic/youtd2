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
@export var _apply_button: Button


var _setting_to_checkbox_map: Dictionary
var _setting_to_slider_map: Dictionary
var _setting_to_button_group_map: Dictionary
var _is_dirty: bool = false


#########################
###     Built-in      ###
#########################

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
		checkbox.pressed.connect(_on_checkbox_pressed)
		
	_setting_to_slider_map = {
		Settings.MOUSE_SCROLL: _mouse_scroll,
		Settings.KEYBOARD_SCROLL: _keyboard_scroll,
	}
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		slider.changed.connect(_on_slider_changed)
	
	_setting_to_button_group_map = {
		Settings.INTERFACE_SIZE: _interface_size_button_group,
	}
	
	for setting in _setting_to_button_group_map.keys():
		var button_group: ButtonGroup = _setting_to_button_group_map[setting]
		button_group.pressed.connect(_on_button_group_pressed)
	
	var all_controls: Array = []
	all_controls.append(_setting_to_checkbox_map.keys())
	all_controls.append(_setting_to_button_group_map.keys())
	all_controls.append(_setting_to_slider_map.keys())
	
	Settings.interface_size_changed.connect(_apply_new_interface_size)
	Settings.flush()

	_load_current_settings()


#########################
###      Private      ###
#########################

func _apply_new_interface_size(new_size: float):
	get_tree().root.content_scale_factor = new_size


func _load_current_settings():
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = Settings.get_bool_setting(setting)
		checkbox.set_pressed(enabled)
		
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = Settings.get_setting(setting) as float
		slider.value = value
	
	for setting in _setting_to_button_group_map.keys():
		var button_group: ButtonGroup = _setting_to_button_group_map[setting]
		var value: String = Settings.get_setting(setting)
		for button in button_group.get_buttons():
			if button.text == value:
				button.set_pressed(true)
				break
	
	_clear_dirty_state()


func _apply_changes():
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
		var value: String = button_group.get_pressed_button().text
		Settings.set_setting(setting, value)
	
	Settings.flush()
	
	_clear_dirty_state()


func _set_dirty_state():
	_is_dirty = true
	_apply_button.disabled = false


func _clear_dirty_state():
	_is_dirty = false
	_apply_button.disabled = true


#########################
###     Callbacks     ###
#########################

func _on_cancel_button_pressed():
	_load_current_settings()
	hide()


func _on_apply_button_pressed():
	_apply_changes()


func _on_ok_button_pressed():
	_apply_changes()
	hide()


func _on_button_group_pressed(_button: BaseButton):
	_set_dirty_state()


func _on_slider_changed(_value: float):
	_set_dirty_state()


func _on_checkbox_pressed():
	_set_dirty_state()
