class_name MissionOnlyIceTowers extends Mission


static func check_for_element_fail(target_element: Element.enm) -> bool:
	var tower_list: Array = Utils.get_tower_list()
	
	for tower in tower_list:
		var element: Element.enm = tower.get_element()
		var element_match: bool = element == target_element
		
		if !element_match:
			return false
	
	return true


func check_for_fail():
	if !MissionOnlyIceTowers.check_for_element_fail(Element.enm.ICE):
		mission_failed()
