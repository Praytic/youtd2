extends HBoxContainer


# NOTE: disable game speed controls in multiplayer because
# all players need to play at same speed
func _ready():
	var game_player_mode: PlayerMode.enm = Globals.get_player_mode()
	var game_is_singleplayer: bool = game_player_mode == PlayerMode.enm.SINGLE

	if !game_is_singleplayer:
		hide()
		
		var button_list: Array[Node] = get_children()
		for button in button_list:
			button.disabled = true


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
