extends Mission


func check_for_fail():
	if !MissionOnlyIceTowers.check_for_element_fail(Element.enm.ASTRAL):
		mission_failed()