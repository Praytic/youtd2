extends Label


func _ready() -> void:
	var plus_mode_is_enabled: bool = Settings.get_bool_setting(Settings.ENABLE_PLUS_MODE)
	visible = plus_mode_is_enabled
