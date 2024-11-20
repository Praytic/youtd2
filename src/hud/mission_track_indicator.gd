class_name MissionTrackIndicator extends HBoxContainer


# Shows status of tracked mission to the player during game match.

const STATUS_FAILED: String = "[color=RED]FAILED[/color]"
const STATUS_COMPLETED: String = "[color=GOLD]COMPLETED[/color]"

var _mission_id: int

@export var _description_label: Label
@export var _in_progress_label: Label
@export var _failed_label: Label
@export var _completed_label: Label


func _ready():
	EventBus.mission_was_failed.connect(_on_mission_was_failed)
	EventBus.mission_was_completed.connect(_on_mission_was_completed)

	var description: String = MissionProperties.get_description(_mission_id)
	_description_label.text = description


func _on_mission_was_failed(mission_id: int):
	var mission_id_match: bool = mission_id == _mission_id
	if !mission_id_match:
		return
	
	_in_progress_label.hide()
	_failed_label.show()


func _on_mission_was_completed(mission_id: int):
	var mission_id_match: bool = mission_id == _mission_id
	if !mission_id_match:
		return

	_in_progress_label.hide()
	_completed_label.show()


static func make(mission_id: int) -> MissionTrackIndicator:
	var mission_track_indicator: MissionTrackIndicator = Preloads.mission_track_indicator_scene.instantiate()
	mission_track_indicator._mission_id = mission_id
	
	return mission_track_indicator
