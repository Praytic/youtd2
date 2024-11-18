extends Node


# Controls state of missions.


func get_mission_is_complete(id: int) -> bool:
	var mission_status: Dictionary = Settings.get_setting(Settings.MISSION_STATUS) as Dictionary
	var id_string: String = str(id)
	var mission_is_complete: bool = mission_status.get(id_string, false)

	return mission_is_complete


func set_mission_is_complete(id: int, is_complete: bool):
	var prev_mission_status: Dictionary = Settings.get_setting(Settings.MISSION_STATUS) as Dictionary
	var new_mission_status: Dictionary = prev_mission_status.duplicate()
	var id_string: String = str(id)
	new_mission_status[id_string] = is_complete

	Settings.set_setting(Settings.MISSION_STATUS, new_mission_status)
	Settings.flush()
