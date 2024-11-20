extends Mission


func check_for_fail():
	var tower_list: Array = Utils.get_tower_list()
	
	for tower in tower_list:
		var item_list: Array = tower.get_items()
		var tower_has_items: bool = item_list.size() > 0
		
		if tower_has_items:
			mission_failed()
			
			return
