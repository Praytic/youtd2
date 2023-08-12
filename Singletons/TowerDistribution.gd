extends Node


# This class distributes random towers to players. This
# happens after every wave and also at the start of the game
# after player upgrades elements four times.

var _upgrade_element_count: int = 0


func _ready():
	ElementLevel.changed.connect(_on_element_level_changed)


# NOTE: when the game starts, we wait for player to do first
# 4 element upgrades and then distribute random towers for
# the first time
func _on_element_level_changed():
	var before_first_wave: bool = WaveLevel.get_current() == 0

	if !before_first_wave:
		return

	_upgrade_element_count += 1

	var upgraded_first_four_times: bool = _upgrade_element_count == 4

	if upgraded_first_four_times:
		distribute_random_towers()


func distribute_random_towers():
	print("distribute_random_towers")
