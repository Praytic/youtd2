class_name TowerStash extends Node


# Stores towers which can currently be built as well as how
# many of each tower is available. Note that if player
# selects build mode, then tower stash will fill up with all
# towers and won't change after that.


signal changed()


# Map of [tower_id -> available count]
var _tower_map: Dictionary = {}
var _tower_count_for_next_roll: int = 6


#########################
###     Built-in      ###
#########################

func _ready():
	PregameSettings.finalized.connect(_on_pregame_settings_finalized)
	EventBus.player_requested_to_roll_towers.connect(_on_player_requested_to_roll_towers)
	EventBus.wave_finished.connect(_on_wave_finished)
	BuildTower.tower_built.connect(_on_tower_built)


#########################
###       Public      ###
#########################

func get_towers() -> Dictionary:
	return _tower_map


#########################
###      Private      ###
#########################

func _add_towers(tower_list: Array):
	for tower in tower_list:
		if !_tower_map.has(tower):
			_tower_map[tower] = 0

		_tower_map[tower] += 1

	changed.emit()


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

# If player selected build mode, add all towers of first
# tier.
func _on_pregame_settings_finalized():
	if !PregameSettings.get_game_mode() == GameMode.enm.BUILD:
		return

	print_verbose("Build mode was chosen. Adding all towers to tower stash.")

	var first_tier_towers: Array = TowerProperties.get_tower_id_list_by_filter(TowerProperties.CsvProperty.TIER, str(1))

	_add_towers(first_tier_towers)

	print_verbose("Added all towers to tower stash.")


func _on_player_requested_to_roll_towers():
	var researched_any_elements: bool = false
	
	for element in Element.get_list():
		var researched_element: bool = ElementLevel.get_current(element) > 0
		if researched_element:
			researched_any_elements = true
	
	if !researched_any_elements:
		Messages.add_error("Cannot roll towers yet! You need to research at least one element.")
	
		return

	if _tower_count_for_next_roll == 0:
		Messages.add_error("You cannot reroll towers anymore.")
	
		return

	_tower_map.clear()
	
	var rolled_towers: Array[int] = TowerDistribution.roll_starting_towers(_tower_count_for_next_roll)
	_add_towers(rolled_towers)
	_tower_count_for_next_roll -= 1


func _on_tower_built(tower: int):
	if Globals.get_game_state() == Globals.GameState.TUTORIAL:
		HighlightUI.highlight_target_ack.emit("tower_placed_on_map")

# 	In build mode towers are not "spent" when player builds
# 	them
	if PregameSettings.get_game_mode() == GameMode.enm.BUILD:
		return

	_remove_tower(tower)


# Distribute random towers when wave is finished
func _on_wave_finished(_level: int):
#	Towers are not distributed in build mode
	if PregameSettings.get_game_mode() == GameMode.enm.BUILD:
		return

	var rolled_towers: Array[int] = TowerDistribution.roll_starting_towers(_tower_count_for_next_roll)
	_add_towers(rolled_towers)
	
#	Add messages about new towers
	Messages.add_normal("New towers were added to stash:")

#	Sort tower list by element to group messages for same
#	element together
	rolled_towers.sort_custom(func(a, b): 
		var element_a: int = TowerProperties.get_element(a)
		var element_b: int = TowerProperties.get_element(b)
		return element_a < element_b)

	for tower in rolled_towers:
		var element: Element.enm = TowerProperties.get_element(tower)
		var element_string: String = Element.convert_to_colored_string(element)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower)
		var rarity_color: Color = Rarity.get_color(rarity)
		var tower_name: String = TowerProperties.get_display_name(tower)
		var tower_name_colored: String = Utils.get_colored_string(tower_name, rarity_color)
		var message: String = "    %s: %s" % [element_string, tower_name_colored]

		Messages.add_normal(message)
