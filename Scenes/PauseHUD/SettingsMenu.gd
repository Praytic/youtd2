extends PanelContainer


@export var _old_item_names: CheckBox


func _ready():
	var foobar_value: bool = Settings.get_setting(Settings.SHOW_OLD_ITEM_NAMES) as bool
	_old_item_names.set_pressed(foobar_value)


func _on_close_button_pressed():
	var foobar_value: bool = _old_item_names.is_pressed()

	Settings.set_setting(Settings.SHOW_OLD_ITEM_NAMES, foobar_value)
	Settings.flush()
	
	hide()
