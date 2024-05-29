extends HBoxContainer


#########################
###     Callbacks     ###
#########################


func _on_speed_normal_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_NORMAL)


func _on_speed_fast_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_FAST)


func _on_speed_fastest_toggled(button_pressed: bool):
	if button_pressed:
		Globals.set_update_ticks_per_physics_tick(Constants.GAME_SPEED_FASTEST)
