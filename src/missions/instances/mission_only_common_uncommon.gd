extends Mission


const VALID_RARITY_LIST: Array = [Rarity.enm.COMMON, Rarity.enm.UNCOMMON]


func check_for_fail():
	var tower_list: Array = Utils.get_tower_list()
	
	for tower in tower_list:
		var rarity: Rarity.enm = tower.get_rarity()
		var rarity_match: bool = VALID_RARITY_LIST.has(rarity)
		
		if !rarity_match:
			mission_failed()
			
			return
