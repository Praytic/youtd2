class_name TowerStash extends Node


# Stores towers which can currently be built as well as how
# many of each tower is available. Note that if player
# selects build mode, then tower stash will fill up with all
# towers and won't change after that.


signal changed()


# Map of [tower_id -> available count]
var _tower_map: Dictionary = {}


#########################
###       Public      ###
#########################

func get_towers() -> Dictionary:
	return _tower_map


func clear():
	_tower_map.clear()
	changed.emit()


func add_towers(tower_list: Array):
	for tower in tower_list:
		if !_tower_map.has(tower):
			_tower_map[tower] = 0

		_tower_map[tower] += 1

	changed.emit()


func spend_tower(tower: int):
#	NOTE: in build mode, building a tower doesn't use it up
#	from the stash
	if Globals.get_game_mode() == GameMode.enm.BUILD:
		return

	if !_tower_map.has(tower):
		return

	_tower_map[tower] -= 1

	if _tower_map[tower] == 0:
		_tower_map.erase(tower)

	changed.emit()


func has_tower(tower: int) -> bool:
	if !_tower_map.has(tower):
		return false

	var count: int = _tower_map[tower]
	var count_is_enough: bool = count > 0

	return count_is_enough


#########################
###     Callbacks     ###
#########################

func add_all_towers():
	var first_tier_towers: Array = TowerProperties.get_tower_id_list_by_filter(TowerProperties.CsvProperty.TIER, str(1))
	add_towers(first_tier_towers)
