class_name MissionCard extends PanelContainer


@export var _description_label: Label
@export var _completed_indicator: PanelContainer
@export var _track_label: Label
@export var _track_checkbox: CheckBox


var _mission_id: int


func _ready():
	var description: String = MissionProperties.get_description(_mission_id)
	_description_label.text = description
	
	var mission_is_complete: bool = MissionStatus.get_mission_is_complete(_mission_id)
	_completed_indicator.visible = mission_is_complete
	
	var mission_is_tracked: bool = MissionTracking.get_mission_is_tracked(_mission_id)
	_track_checkbox.set_pressed_no_signal(mission_is_tracked)
	
	if mission_is_complete:
		set_theme_type_variation("UniqueRarityPanelContainer")
		
#		If mission is complete, then hide tracking UI
#		because there's no point to display it for completed
#		missions.
#		NOTE: hide UI elements and leave the box container
#		visible to have consistent width of the description
#		label for both complete/incomplete missions
		_track_label.hide()
		_track_checkbox.hide()


func set_mission_id(mission_id: int):
	_mission_id = mission_id


static func make(mission_id: int) -> MissionCard:
	var card: MissionCard = Preloads.mission_card.instantiate()
	card.set_mission_id(mission_id)
	
	return card


func _on_track_check_box_toggled(toggled_on: bool) -> void:
#	Limit max amount of tracked missions
	if toggled_on:
		var prev_tracked_count: int = MissionTracking.get_tracked_count()
		var going_over_max: bool = prev_tracked_count == MissionTracking.MAX_TRACKED_COUNT
		
		if going_over_max:
			Utils.show_popup_message(self, "Error", "Can't track more than 3 missions at the same time!")
			
			_track_checkbox.set_pressed_no_signal(false)
			
			return
	
	MissionTracking.set_mission_is_tracked(_mission_id, toggled_on)
