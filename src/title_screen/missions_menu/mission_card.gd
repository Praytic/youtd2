class_name MissionCard extends PanelContainer


@export var _description_label: Label
@export var _completed_indicator: PanelContainer


var _mission_id: int


func _ready():
	var description: String = MissionProperties.get_description(_mission_id)
	_description_label.text = description
	
	var mission_is_complete: bool = MissionStatus.get_mission_is_complete(_mission_id)
	_completed_indicator.visible = mission_is_complete
	
	if mission_is_complete:
		set_theme_type_variation("UniqueRarityPanelContainer")


func set_mission_id(mission_id: int):
	_mission_id = mission_id


static func make(mission_id: int) -> MissionCard:
	var card: MissionCard = Preloads.mission_card.instantiate()
	card.set_mission_id(mission_id)
	
	return card
