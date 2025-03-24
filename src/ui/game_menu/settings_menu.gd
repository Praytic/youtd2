extends PanelContainer


signal cancel_pressed()
signal ok_pressed()


@export var _damage_numbers: CheckBox
@export var _enable_floating_text: CheckBox
@export var _enable_vfx: CheckBox
@export var _enable_sfx: CheckBox
@export var _enable_mouse_scroll: CheckBox
@export var _show_combat_log: CheckBox
@export var _show_tutorial_on_start: CheckBox
@export var _projectile_density: Slider
@export var _mouse_scroll: Slider
@export var _keyboard_scroll: Slider
@export var _interface_size_button_group: ButtonGroup
@export var _apply_button: Button
@export var _display_mode_combo: OptionButton
@export var _language_combo: OptionButton
@export var _interface_size_button_small: Button
@export var _interface_size_button_medium: Button
@export var _interface_size_button_large: Button


var _setting_to_combo_map: Dictionary
var _setting_to_checkbox_map: Dictionary
var _setting_to_slider_map: Dictionary
@onready var _interface_size_button_to_size_map: Dictionary = {
	_interface_size_button_small: Settings.InterfaceSize.SMALL,
	_interface_size_button_medium: Settings.InterfaceSize.MEDIUM,
	_interface_size_button_large: Settings.InterfaceSize.LARGE,
}
var _is_dirty: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
#	NOTE: need to setup these maps inside ready() because this map uses @export vars which are not ready before ready()
	_setting_to_combo_map = {
		Settings.DISPLAY_MODE: _display_mode_combo,
		Settings.LANGUAGE: _language_combo,
	}
	
	for setting in _setting_to_combo_map.keys():
		var combo: OptionButton = _setting_to_combo_map[setting]
		combo.item_selected.connect(_on_combo_changed)
	
	_setting_to_checkbox_map = {
		Settings.SHOW_ALL_DAMAGE_NUMBERS: _damage_numbers,
		Settings.ENABLE_FLOATING_TEXT: _enable_floating_text,
		Settings.ENABLE_VFX: _enable_vfx,
		Settings.ENABLE_SFX: _enable_sfx,
		Settings.ENABLE_MOUSE_SCROLL: _enable_mouse_scroll,
		Settings.SHOW_COMBAT_LOG: _show_combat_log,
		Settings.SHOW_TUTORIAL_ON_START: _show_tutorial_on_start,
	}
	
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		checkbox.pressed.connect(_on_checkbox_pressed)
		
	_setting_to_slider_map = {
		Settings.PROJECTILE_DENSITY: _projectile_density,
		Settings.MOUSE_SCROLL: _mouse_scroll,
		Settings.KEYBOARD_SCROLL: _keyboard_scroll,
	}
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		slider.changed.connect(_on_slider_changed)
	
	_interface_size_button_group.pressed.connect(_on_interface_size_button_group_pressed)
	
	_load_current_settings()


#########################
###      Private      ###
#########################

func _load_current_settings():
	var selected_display_mode_int: int = Settings.get_setting(Settings.DISPLAY_MODE) as int
	_display_mode_combo.select(selected_display_mode_int)
	
	var language_string: String = Settings.get_setting(Settings.LANGUAGE)
	var selected_language_int: int = Language.get_option_from_locale(language_string)
	_language_combo.select(selected_language_int)
	
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = Settings.get_bool_setting(setting)
		checkbox.set_pressed(enabled)
		
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = Settings.get_setting(setting) as float
		slider.value = value
	
	var selected_interface_size: Settings.InterfaceSize = Settings.get_interface_size_enum()
	for button in _interface_size_button_to_size_map.keys():
		var button_interface_size: Settings.InterfaceSize = _interface_size_button_to_size_map[button]
		var button_is_selected: bool = button_interface_size == selected_interface_size
		
		if button_is_selected:
			button.set_pressed(true)
			break
	
	_clear_dirty_state()


# NOTE: language and display settings are special cases and
# are not handled here. Instead, they are handled in
# specialised callbacks:
# _on_display_mode_combo_item_selected() and
# _on_language_item_selected()
func _apply_changes():
	for setting in _setting_to_checkbox_map.keys():
		var checkbox: CheckBox = _setting_to_checkbox_map[setting]
		var enabled: bool = checkbox.is_pressed()
		Settings.set_setting(setting, enabled)
	
	for setting in _setting_to_slider_map.keys():
		var slider: Slider = _setting_to_slider_map[setting]
		var value: float = slider.value
		Settings.set_setting(setting, value)
	
	var pressed_interface_size_button: Button = _interface_size_button_group.get_pressed_button()
	var selected_interface_size: Settings.InterfaceSize = _interface_size_button_to_size_map[pressed_interface_size_button]
	Settings.set_setting(Settings.INTERFACE_SIZE, selected_interface_size)
	
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
	cancel_pressed.emit()


func _on_apply_button_pressed():
	_apply_changes()


func _on_ok_button_pressed():
	_apply_changes()
	ok_pressed.emit()


func _on_interface_size_button_group_pressed(_button: BaseButton):
	_set_dirty_state()


func _on_slider_changed(_value: float):
	_set_dirty_state()


func _on_combo_changed(_index: int):
	_set_dirty_state()


func _on_checkbox_pressed():
	_set_dirty_state()


# Load current settings when menu is opened. Need to do this because settings can get changed outside of this menu, in code.
func _on_visibility_changed():
	if visible:
		_load_current_settings()


func _on_display_mode_combo_item_selected(index: int):
	var display_mode_int: int = index
	Settings.set_setting(Settings.DISPLAY_MODE, display_mode_int)


func _on_language_item_selected(index: int) -> void:
	var selected_locale: String = Language.get_locale_from_option(index)
	TranslationServer.set_locale(selected_locale)
	Settings.set_setting(Settings.LANGUAGE, selected_locale)
