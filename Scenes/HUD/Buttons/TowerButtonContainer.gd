class_name TowerButtonContainer
extends UnitButtonContainer


static func make(tower_id: int) -> TowerButtonContainer:
	var tower_button_container: TowerButtonContainer = Globals.tower_button_scene.instantiate()
	tower_button_container._tower_id = tower_id

	return tower_button_container
