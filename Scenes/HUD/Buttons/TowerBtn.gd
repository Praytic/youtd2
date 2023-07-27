extends UnitButton


const _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")


var _tower_id: int: get = get_tower_id, set = set_tower_id


func get_tower_id() -> int:
	return _tower_id

func set_tower_id(value: int):
	_tower_id = value
	match Rarity.convert_from_string(value):
		Rarity.enm.COMMON:
			_rarity_container.theme_type_variation = "CommonRarityPanelContainer"
		Rarity.enm.UNCOMMON:
			_rarity_container.theme_type_variation = "UncommonRarityPanelContainer"
		Rarity.enm.RARE:
			_rarity_container.theme_type_variation = "RareRarityPanelContainer"
		Rarity.enm.UNIQUE:
			_rarity_container.theme_type_variation = "UniqueRarityPanelContainer"
