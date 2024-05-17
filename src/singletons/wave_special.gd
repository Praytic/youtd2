extends Node


# Functions for dealing with specials that are applied to
# creep waves. Note that getters for wave special properties
# are located in as separate class WaveSpecialProperties.


const _special_count_chances: Dictionary = {
	0: 30,
	1: 50,
	2: 20,
}


#########################
###       Public      ###
#########################

func get_random(level: int, creep_size: CreepSize.enm, wave_has_champions: bool) -> Array[int]:
	var override_wave_specials: Array[int] = Config.override_wave_specials()
	if !override_wave_specials.is_empty():
		return override_wave_specials

	var is_challenge: bool = CreepSize.is_challenge(creep_size)

	if is_challenge:
		return []

	var available_specials_for_first: Array[int] = _get_available_specials_for_first_special(level, creep_size, wave_has_champions)
	var first_special: int = _get_random_special(available_specials_for_first)

	var available_specials_for_second: Array[int] = _get_available_specials_for_second_special(first_special, available_specials_for_first)
	var second_special: int = _get_random_special(available_specials_for_second)

	var generated_specials: Array[int] = [first_special, second_special]

	var special_count: int
	if level <= Constants.MIN_WAVE_FOR_SPECIAL:
		special_count = 0
	else:
		special_count = Utils.random_weighted_pick(Globals.synced_rng, _special_count_chances)

	var random_special_list: Array[int] = []

	for i in range(0, special_count):
		var special: int = generated_specials[i]

		if special != -1:
			random_special_list.append(special)

	return random_special_list


func apply_to_creep(special_list: Array[int], creep: Creep):
#	NOTE: need to filter specials because a special may not
#	apply to all creeps in wave. A common scenario is when a
#	special applies only to champions
	var applied_list: Array[int] = special_list.filter(
		func(special: int) -> bool:
			var special_applies: bool = _special_applies_to_creep(special, creep)

			return special_applies
	)

	creep.set_special_list(applied_list)

	var hp_modifier: float = _get_hp_modifier(applied_list)
	creep.modify_property(Modification.Type.MOD_HP_PERC, hp_modifier)

#	NOTE: creep needs mana only if the *applied* specials
#	require mana.
	var creep_base_mana: float = _get_creep_base_mana(applied_list, creep)
	creep.set_base_mana(creep_base_mana)
	creep.set_mana(creep_base_mana)

	var base_color: Color = WaveSpecialProperties.get_base_color(applied_list)
	creep.set_sprite_base_color(base_color)

	for special in applied_list:
		var buff: BuffType = WaveSpecialProperties.get_special_buff(special)
		buff.apply_to_unit_permanent(creep, creep, 0)


func creep_has_flock_special(creep: Creep) -> bool:
	var flock_special: BuffType = WaveSpecialProperties.get_special_buff(WaveSpecialProperties.FLOCK)
	var creep_has_buff: bool = creep.get_buff_of_type(flock_special) != null

	return creep_has_buff


#########################
###      Private      ###
#########################

func _get_random_special(available_special_list: Array[int]) -> int:
	if available_special_list.is_empty():
		return -1

	var special_to_frequency_map: Dictionary = {}

	for special in available_special_list:
		var frequency: int = WaveSpecialProperties.get_frequency(special)
		special_to_frequency_map[special] = frequency

	var random_special: int = Utils.random_weighted_pick(Globals.synced_rng, special_to_frequency_map)

	return random_special


func _get_available_specials_for_first_special(level: int, creep_size: CreepSize.enm, wave_has_champions: bool) -> Array[int]:
	var all_special_list: Array = WaveSpecialProperties.get_all_specials_list()
	var available_special_list: Array[int] = []

	var wave_level: int = level

	for special in all_special_list:
		var is_enabled: bool = WaveSpecialProperties.get_enabled(special)

		if !is_enabled:
			continue

		var required_level: int = WaveSpecialProperties.get_required_wave_level(special)
		var level_ok: bool = wave_level >= required_level

		var applicable_sizes: Array[CreepSize.enm] = WaveSpecialProperties.get_applicable_sizes(special)
		var size_ok: bool = applicable_sizes.has(creep_size)

		var champion_or_boss_wave_only: bool = WaveSpecialProperties.get_champion_or_boss_wave_only(special)
		var wave_is_champion_or_boss: bool = wave_has_champions || creep_size == CreepSize.enm.BOSS
		var wave_power_ok: bool
		if champion_or_boss_wave_only:
			wave_power_ok = wave_is_champion_or_boss
		else:
			wave_power_ok = true

		var is_available: bool = level_ok && size_ok && wave_power_ok

		if is_available:
			available_special_list.append(special)

	return available_special_list


func _get_available_specials_for_second_special(first_special: int, available_specials_for_first: Array[int]) -> Array[int]:
	if first_special == -1:
		return []

	var result: Array[int] = available_specials_for_first.duplicate()

	var groups_of_first_special: Array[String] = WaveSpecialProperties.get_group_list(first_special)

# 	Filter out specials which are in the same group as
# 	the first special
	for group in groups_of_first_special:
		var specials_in_group: Array = WaveSpecialProperties.get_specials_in_group(group)

		for special in specials_in_group:
			result.erase(special)

#	NOTE: don't pick same special twice
	result.erase(first_special)

	return result


func _get_hp_modifier(special_list: Array[int]) -> float:
	if special_list.is_empty():
		return 0.0

	var hp_mod_list: Array[float] = []

	for special in special_list:
		var hp_modifier: float = WaveSpecialProperties.get_hp_modifier(special)

		hp_mod_list.append(hp_modifier)

	hp_mod_list.sort()

	if hp_mod_list.size() == 1:
		return hp_mod_list.front()
	else:
		var min_mod: float = hp_mod_list.front()
		var max_mod: float = hp_mod_list.back()

		if min_mod <= 0 && max_mod >= 0:
			var total_mod: float = min_mod + max_mod

			return total_mod
		elif min_mod < 0 && max_mod < 0:
			return min_mod
		elif min_mod > 0 && max_mod > 0:
			return max_mod
		else:
			return max_mod


func _get_creep_base_mana(special_list: Array[int], creep: Creep) -> float:
	var creep_should_have_mana: bool = false

	for special in special_list:
		var special_applies: bool = _special_applies_to_creep(special, creep)
		var special_uses_mana: bool = WaveSpecialProperties.get_uses_mana(special)

		if special_applies && special_uses_mana:
			creep_should_have_mana = true

	var creep_base_mana: float
	if creep_should_have_mana:
		var creep_size: CreepSize.enm = creep.get_size()
		creep_base_mana = CreepSize.get_base_mana(creep_size)
	else:
		creep_base_mana = 0

	return creep_base_mana


func _special_applies_to_creep(special: int, creep: Creep) -> bool:
	var creep_size: CreepSize.enm = creep.get_size()
	var special_only_for_champions_or_bosses: bool = WaveSpecialProperties.get_champion_or_boss_wave_only(special)
	var special_applies: bool
	if special_only_for_champions_or_bosses:
		special_applies = creep_size == CreepSize.enm.BOSS || creep_size == CreepSize.enm.CHAMPION
	else:
		special_applies = true

	return special_applies
