class_name AutocastButton extends Button


var _autocast: Autocast = null
@onready var _cooldown_indicator: CooldownIndicator = $IndicatorContainer/CooldownIndicator
@onready var _auto_mode_indicator: AutoModeIndicator = $IndicatorContainer/AutoModeIndicator
@onready var _indicator_container: MarginContainer = $IndicatorContainer

func _ready():
	_cooldown_indicator.set_autocast(_autocast)
	_auto_mode_indicator.set_autocast(_autocast)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	var button_stylebox: StyleBox = get_theme_stylebox("normal", "Button")
	var icon_offset: Vector2 = button_stylebox.get_offset()

#	NOTE: need to load margins here because they are not
#	finalized while in editor
	_indicator_container.add_theme_constant_override("margin_top", button_stylebox.content_margin_top)
	_indicator_container.add_theme_constant_override("margin_left", button_stylebox.content_margin_left)
	_indicator_container.add_theme_constant_override("margin_bottom", button_stylebox.content_margin_bottom)
	_indicator_container.add_theme_constant_override("margin_right", button_stylebox.content_margin_right)


func _gui_input(event):
	var pressed_shift_right_click: bool = event.is_action_released("right_click") && Input.is_action_pressed("shift")
	var pressed_right_click: bool = event.is_action_released("right_click")

	if pressed_shift_right_click:
		_autocast.toggle_auto_mode()
	elif pressed_right_click:
		_autocast.do_cast_if_possible()


func set_autocast(autocast: Autocast):
	_autocast = autocast


func _on_mouse_entered():
	EventBus.autocast_button_mouse_entered.emit(_autocast)


func _on_mouse_exited():
	EventBus.autocast_button_mouse_exited.emit()
