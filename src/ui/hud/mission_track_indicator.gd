class_name MissionTrackIndicator extends HBoxContainer


# Shows status of tracked mission to the player during game match.


enum State {
	IN_PROGRESS,
	FAILED,
	COMPLETED,
}

const STATUS_FAILED: String = "[color=RED]FAILED[/color]"
const STATUS_COMPLETED: String = "[color=GOLD]COMPLETED[/color]"

var _mission_id: int

@export var _description_label: Label
@export var _in_progress_label: Label
@export var _failed_label: Label
@export var _completed_label: Label


#########################
###     Built-in      ###
#########################

func _ready():
	var description: String = MissionProperties.get_description(_mission_id)
	_description_label.text = description


#########################
###       Public      ###
#########################

func set_state(state: MissionTrackIndicator.State):
	_in_progress_label.visible = state == MissionTrackIndicator.State.IN_PROGRESS
	_failed_label.visible = state == MissionTrackIndicator.State.FAILED
	_completed_label.visible = state == MissionTrackIndicator.State.COMPLETED


static func make(mission_id: int) -> MissionTrackIndicator:
	var mission_track_indicator: MissionTrackIndicator = Preloads.mission_track_indicator_scene.instantiate()
	mission_track_indicator._mission_id = mission_id
	
	return mission_track_indicator
