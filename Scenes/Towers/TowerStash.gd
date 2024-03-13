class_name TowerStash extends Node


# Stores towers which can currently be built as well as how
# many of each tower is available. Note that if player
# selects build mode, then tower stash will fill up with all
# towers and won't change after that.


signal changed()


# Map of [tower_id -> available count]
var _tower_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.tower_created.connect(_on_tower_created)


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


#########################
###      Private      ###
#########################

func _remove_tower(tower: int):
	if !_tower_map.has(tower):
		return

	_tower_map[tower] -= 1

	if _tower_map[tower] == 0:
		_tower_map.erase(tower)

	changed.emit()


#########################
###     Callbacks     ###
#########################

func add_all_towers():
	var first_tier_towers: Array = TowerProperties.get_tower_id_list_by_filter(TowerProperties.CsvProperty.TIER, str(1))
	add_towers(first_tier_towers)


func _on_tower_created(tower: Tower):
	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		HighlightUI.highlight_target_ack.emit("tower_placed_on_map")

# 	In build mode towers are not "spent" when player builds
# 	them
	if PregameSettings.get_game_mode() == GameMode.enm.BUILD:
		return

	var tower_id: int = tower.get_id()

	_remove_tower(tower_id)
