extends VBoxContainer


enum Tab {
	MAIN = 0,
	HELP,
	ENCYCLOPEDIA,
	SETTINGS,
}


signal continue_pressed()
signal quit_pressed()


@export var _tab_container: TabContainer


func switch_to_help_menu():
	_tab_container.current_tab = Tab.HELP


func _on_continue_button_pressed():
	continue_pressed.emit()


func _on_help_button_pressed():
	_tab_container.current_tab = Tab.HELP


func _on_settings_button_pressed():
	_tab_container.current_tab = Tab.SETTINGS


func _on_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_help_menu_closed():
	_tab_container.current_tab = Tab.MAIN


func _on_help_menu_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_cancel_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_ok_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_quit_button_pressed():
	quit_pressed.emit()


func _on_encyclopedia_button_pressed() -> void:
	_tab_container.current_tab = Tab.ENCYCLOPEDIA


func _on_encyclopedia_menu_close_pressed() -> void:
	_tab_container.current_tab = Tab.MAIN
