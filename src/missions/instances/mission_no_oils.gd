extends Mission


func check_for_fail():
	var tower_list: Array = Utils.get_tower_list()
	var tower_count: int = tower_list.size()
	
	for tower in tower_list:
		var oil_list: Array = tower.get_oils()
		var tower_has_oils: bool = oil_list.size() > 0
		
		if tower_has_oils:
			mission_failed()
			
			return
