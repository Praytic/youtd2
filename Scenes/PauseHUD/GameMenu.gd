extends Control


enum Tab {
	MAIN = 0,
	HELP,
	HINTS,
	SETTINGS,
}


signal close_pressed()
signal restart_pressed()


@export var _tab_container: TabContainer


func _on_close_button_pressed():
	close_pressed.emit()


func _on_help_button_pressed():
	_tab_container.current_tab = Tab.HELP


func _on_hints_button_pressed():
	_tab_container.current_tab = Tab.HINTS


func _on_settings_button_pressed():
	_tab_container.current_tab = Tab.SETTINGS


func _on_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_hints_menu_closed():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_help_menu_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_restart_button_pressed():
	restart_pressed.emit()
