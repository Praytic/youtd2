extends Control


enum PauseTab {
	MAIN = 0,
	HINTS,
}


signal resume_pressed()


@export var _tab_container: TabContainer


func _on_resume_button_pressed():
	resume_pressed.emit()


func _on_hints_button_pressed():
	_tab_container.current_tab = PauseTab.HINTS


func _on_hidden():
	_tab_container.current_tab = PauseTab.MAIN


func _on_hints_menu_closed():
	_tab_container.current_tab = PauseTab.MAIN
