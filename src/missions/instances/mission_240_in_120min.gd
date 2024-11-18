extends Mission


func process_game_win() -> bool:
	var time: float = Utils.get_time()
	var completed: bool = time < 120 * 60

	return completed
