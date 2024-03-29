extends Node

# Main menu for the game. Opens when the game starts.


enum Tab {
	MAIN,
	SETTINGS,
	CREDITS,
}

@export var _tab_container: TabContainer


func _on_button_pressed():
	get_tree().change_scene_to_packed(Preloads.game_scene_scene)


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	_tab_container.current_tab = Tab.SETTINGS


func _on_credits_button_pressed():
	_tab_container.current_tab = Tab.CREDITS


func _on_credits_menu_hidden():
	_tab_container.current_tab = Tab.MAIN


func _on_settings_menu_hidden():
	_tab_container.current_tab = Tab.MAIN
