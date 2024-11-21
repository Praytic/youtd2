class_name MissionTrackerContainer extends VBoxContainer


# Contains mission trackers which is shown in HUD.


var _indicator_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

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
			_indicator_map[mission_id] = mission_track_indicator
			add_child(mission_track_indicator)
			added_mission_count += 1
			
			if added_mission_count >= MissionTracking.MAX_TRACKED_COUNT:
				break


#########################
###       Public      ###
#########################

func set_mission_track_state(mission_id: int, state: MissionTrackIndicator.State):
	if !_indicator_map.has(mission_id):
		return

	var indicator: MissionTrackIndicator = _indicator_map.get(mission_id)
	indicator.set_state(state)
