extends Mission


func check_for_fail():
	var tower_list: Array = Utils.get_tower_list()
	var tower_count: int = tower_list.size()
	
	if tower_count > 5:
		mission_failed()
