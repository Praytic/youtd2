extends Mission


func check_for_fail():
	var local_player: Player = PlayerManager.get_local_player()
	var food: int = local_player.get_food()
	var food_ok: int = food <= 35
	
	if !food_ok:
		mission_failed()
