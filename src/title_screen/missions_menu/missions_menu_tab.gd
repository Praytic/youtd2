class_name MissionsMenuTab extends MarginContainer


@export var _section_name: String
@export var _mission_box: VBoxContainer
@export var _completed_count_label: Label


func _ready() -> void:
	var id_list: Array = MissionProperties.get_id_list()

#	Sort id list to display missions in order
	id_list.sort()
	
	for id in id_list:
		var mission_section: String = MissionProperties.get_section(id)
		var section_match: bool = mission_section == _section_name
		
		if !section_match:
			continue
		
		var card: MissionCard = MissionCard.make(id)
		
		_mission_box.add_child(card)
	
	var total_count: int = _get_mission_count_in_section()
	var completed_count: int = _get_completed_mission_count_in_section()
	var complete_text: String = "%d/%d" % [completed_count, total_count]
	_completed_count_label.text = complete_text


func _get_mission_count_in_section() -> int:
	var count: int = 0
	
	var id_list: Array = MissionProperties.get_id_list()
	for id in id_list:
		var mission_section: String = MissionProperties.get_section(id)
		var section_match: bool = mission_section == _section_name
		
		if section_match:
			count += 1
	
	return count


func _get_completed_mission_count_in_section() -> int:
	var count: int = 0
	
	var id_list: Array = MissionProperties.get_id_list()
	for id in id_list:
		var mission_section: String = MissionProperties.get_section(id)
		var section_match: bool = mission_section == _section_name
		var completed: bool = MissionStatus.get_mission_is_complete(id)
		
		if section_match && completed:
			count += 1
	
	return count
