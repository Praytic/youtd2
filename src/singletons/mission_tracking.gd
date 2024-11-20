extends Node


const MAX_TRACKED_COUNT: int = 3


var _tracked_mission_map: Dictionary = {}


func get_mission_is_tracked(id: int) -> bool:
	var is_tracked: bool = _tracked_mission_map.get(id, false)
	
	return is_tracked


func set_mission_is_tracked(id: int, value: bool):
	_tracked_mission_map[id] = value


func get_tracked_count() -> int:
	var count: int = 0
	for id in _tracked_mission_map.keys():
		var is_tracked: bool = get_mission_is_tracked(id)
		
		if is_tracked:
			count += 1
	
	return count
