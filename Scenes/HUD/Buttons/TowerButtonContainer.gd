class_name TowerButtonContainer
extends UnitButtonContainer


var _tower_id: int : set = set_tower_id, get = get_tower_id


static func make(tower_id: int):
	var tower_button_container = Globals.tower_button_container_scene.instantiate()
	tower_button_container.set_tower_id(tower_id)
	return tower_button_container


func _ready():
	super._ready()
	set_button(TowerButton.make(_tower_id))


func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value
