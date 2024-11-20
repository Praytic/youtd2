extends VBoxContainer


# Contains mission trackers which is shown in HUD.




func _ready() -> void:
	var mission_id_list: Array = MissionProperties.get_id_list()
	
	var added_mission_count: int = 0
	
	for mission_id in mission_id_list:
		var mission_is_tracked: bool = MissionTracking.get_mission_is_tracked(mission_id)
		var mission_is_completed: bool = MissionStatus.get_mission_is_complete(mission_id)
		
		if mission_is_completed:
			continue
		
		if mission_is_tracked:
			var mission_track_indicator: MissionTrackIndicator = MissionTrackIndicator.make(mission_id)
			add_child(mission_track_indicator)
			added_mission_count += 1
			
			if added_mission_count >= MissionTracking.MAX_TRACKED_COUNT:
				break
