extends VBoxContainer


enum Tab {
	MAIN = 0,
	HELP,
	HINTS,
	SETTINGS,
	QUIT,
}


signal close_pressed()


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


func _on_help_menu_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_cancel_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_ok_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_quit_button_pressed():
	_tab_container.current_tab = Tab.QUIT


func _on_quit_menu_cancel_pressed():
	_tab_container.current_tab = Tab.MAIN


func _on_quit_menu_go_to_title_pressed():
	get_tree().set_pause(false)
	get_tree().change_scene_to_packed(Preloads.title_screen_scene)


func _on_quit_menu_quit_game_pressed():
	get_tree().set_pause(false)
	get_tree().quit()
