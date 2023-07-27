class_name TowerButton
extends UnitButton


const _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")


var _tower_id: int: get = get_tower_id, set = set_tower_id


static func make(tower_id: int):
	var tower_button = Globals.tower_button.instantiate()
	
	tower_button.set_tower_id(tower_id)
	tower_button.set_rarity(TowerProperties.get_rarity(tower_id))
	tower_button.set_icon(TowerProperties.get_icon_texture(tower_id))
	return tower_button



func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value
