extends Node


# This class distributes random towers to players. This
# happens after every wave and also at the start of the game
# after player upgrades elements four times.


signal random_tower_distributed(tower_id)


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
		distribute_random_towers(0)


# TODO: implement
# NOTE: wave_level argument is used instead of current wave
# level because we need to distribute towers when waves are
# finished and waves may finish out of order. For example,
# player can spawn wave 2 early after wave 1 is done
# spawning but then finish wave 2 before wave 1.
func distribute_random_towers(_wave_level: int):
	var common_rarity_string: String = Rarity.convert_to_string(Rarity.enm.COMMON)
	var common_tower_list: Array = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.RARITY, common_rarity_string)
	var random_tower: int = common_tower_list.pick_random()

	random_tower_distributed.emit(random_tower)
