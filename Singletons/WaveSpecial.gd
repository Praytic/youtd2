extends Node


# Functions for dealing with specials that are applied to
# creep waves.

const PROPERTIES_PATH: String = "res://Data/wave_special_properties.csv"
const FLOCK: int = 31


enum CsvProperty {
	ID,
	NAME,
	SHORT_NAME,
	HP_MODIFIER,
	REQUIRED_WAVE_LEVEL,
	FREQUENCY,
	APPLICABLE_SIZES,
	CHAMPION_OR_BOSS_WAVE_ONLY,
	GROUP_LIST,
	USES_MANA,
	COLOR,
	DESCRIPTION,
	ENABLED,
}


const _special_count_chances: Dictionary = {
	0: 30,
	1: 50,
	2: 20,
}


var _buff_map: Dictionary = {
	0: CreepSpeed.new(self),
	1: CreepGreaterSpeed.new(self),
	2: CreepXtremeSpeed.new(self),
	3: CreepSlow.new(self),
	4: CreepInvisible.new(self),
	5: CreepStrong.new(self),
	6: CreepRich.new(self),
	7: CreepRelicRaider.new(self),
	8: CreepUltraWisdom.new(self),
	9: CreepArmored.new(self),
	10: CreepHeavyArmored.new(self),
	11: CreepXtremeArmor.new(self),
	12:	CreepEvasion.new(self),
	13:	CreepXtremeEvasion.new(self),
	14:	CreepGhost.new(self),
	15:	CreepSpellResistance.new(self),
	16:	CreepGreaterSpellResistance.new(self),
	17:	CreepMagicImmunity.new(self),
	18:	CreepEthereal.new(self),
	19: CreepSlowAura.new(self),
	20: CreepManaDrainAura.new(self),
	21: CreepSpellbinder.new(self),
	22: CreepStunRevenge.new(self),
	23: CreepRegeneration.new(self),
	24: CreepXtremeRegeneration.new(self),
	25: CreepSecondChance.new(self),
	26: CreepSemiMechanical.new(self),
	27: CreepMechanical.new(self),
	28: CreepMeaty.new(self),
	29: CreepEvolving.new(self),
	30: CreepUnlucky.new(self),
	WaveSpecial.FLOCK: CreepFlock.new(self),
	32: CreepGravid.new(self),
	33: CreepProtector.new(self),
	34: CreepManaShield.new(self),
	35: CreepManaShieldPlus.new(self),
	36: CreepNecromancer.new(self),
	37: CreepPurgeRevenge.new(self),
	38: CreepFireball.new(self),
	39: CreepDart.new(self),
	40: CreepBroody.new(self),
}

# Map of group [String] to special [int]
var _group_to_special_map: Dictionary = {}

var _properties: Dictionary = {}


func _init():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, WaveSpecial.CsvProperty.ID)
	_group_to_special_map = _make_group_to_special_map()
	print_verbose("_group_to_special_map = ", _group_to_special_map)

	for special in _buff_map.keys():
		var buff: BuffType = _buff_map[special]
		var special_name: String = get_special_name(special)
		var description: String = get_description(special)
		var tooltip: String = "%s\n%s" % [special_name, description]

		buff.set_buff_tooltip(tooltip)


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
		special_count = Utils.random_weighted_pick(_special_count_chances)

	var random_special_list: Array[int] = []

	for i in range(0, special_count):
		var special: int = generated_specials[i]

		if special != -1:
			random_special_list.append(special)

	return random_special_list


func arrays_intersect(a: Array, b: Array) -> bool:
	for element in a:
		if b.has(element):
			return true

	return false


func _get_random_special(available_special_list: Array[int]) -> int:
	if available_special_list.is_empty():
		return -1

	var special_to_frequency_map: Dictionary = {}

	for special in available_special_list:
		var frequency: int = _get_frequency(special)
		special_to_frequency_map[special] = frequency

	var random_special: int = Utils.random_weighted_pick(special_to_frequency_map)

	return random_special


func get_special_name(special: int) -> String:
	var string: String = _get_property(special, WaveSpecial.CsvProperty.NAME)

	return string


func get_short_name(special: int) -> String:
	var string: String = _get_property(special, WaveSpecial.CsvProperty.SHORT_NAME)

	return string


func apply_to_creep(special_list: Array[int], creep: Creep):
	for special in special_list:
		if !_buff_map.has(special):
			push_error("No buff for special: ", special)

			return

	creep._special_list = special_list

	var hp_modifier: float = _get_hp_modifier(special_list)
	creep.modify_property(Modification.Type.MOD_HP_PERC, hp_modifier)

	var creep_base_mana: float = _get_creep_base_mana(special_list, creep)
	creep.set_base_mana(creep_base_mana)
	creep.set_mana(creep_base_mana)

	var base_color: Color = _get_base_color(special_list)
	creep.set_sprite_base_color(base_color)

	for special in special_list:
		var special_applies: bool = _special_applies_to_creep(special, creep)

		if special_applies:
			var buff: BuffType = _buff_map[special]
			buff.apply_to_unit_permanent(creep, creep, 0)


func _get_available_specials_for_first_special(level: int, creep_size: CreepSize.enm, wave_has_champions: bool) -> Array[int]:
	var all_special_list: Array = _properties.keys()
	var available_special_list: Array[int] = []

	var wave_level: int = level

	for special in all_special_list:
		var is_enabled: bool = WaveSpecial.get_enabled(special)

		if !is_enabled:
			continue

		var required_level: int = _get_required_wave_level(special)
		var level_ok: bool = wave_level >= required_level

		var applicable_sizes: Array[CreepSize.enm] = _get_applicable_sizes(special)
		var size_ok: bool = applicable_sizes.has(creep_size)

		var champion_or_boss_wave_only: bool = _get_champion_or_boss_wave_only(special)
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

	var groups_of_first_special: Array[String] = _get_group_list(first_special)

# 	Filter out specials which are in the same group as
# 	the first special
	for group in groups_of_first_special:
		var specials_in_group: Array = _group_to_special_map[group]

		for special in specials_in_group:
			result.erase(special)

#	NOTE: don't pick same special twice
	result.erase(first_special)

	return result


func _get_required_wave_level(special: int) -> int:
	var level: int = _get_property(special, WaveSpecial.CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

	return level


func _get_frequency(special: int) -> int:
	var frequency: int = _get_property(special, WaveSpecial.CsvProperty.FREQUENCY).to_int()

	return frequency


func _get_applicable_sizes(special: int) -> Array[CreepSize.enm]:
	var size_list_string: String = _get_property(special, WaveSpecial.CsvProperty.APPLICABLE_SIZES)

	if size_list_string == "all":
		return [CreepSize.enm.MASS, CreepSize.enm.NORMAL, CreepSize.enm.AIR, CreepSize.enm.BOSS]

	var size_list: Array[CreepSize.enm] = []

	var size_string_list: Array = size_list_string.split(",")

	for size_string in size_string_list:
		var creep_size: CreepSize.enm = CreepSize.from_string(size_string)
		size_list.append(creep_size)

	return size_list


# NOTE: this is separate from "applicable sizes" because
# this defines if wave buff can apply to specific creep, not
# the whole wave. For example if the wave is 10 normal + 1
# champion, then special can apply to whole wave but the
# buff portion will apply only to the champion. Note that
# health modifiers still apply to whole wave.
#
# TODO: double check if health modifiers apply to whole wave
# if special is only for champions.
func _get_champion_or_boss_wave_only(special: int) -> bool:
	var champion_or_boss_wave_only: bool = _get_property(special, WaveSpecial.CsvProperty.CHAMPION_OR_BOSS_WAVE_ONLY) == "TRUE"

	return champion_or_boss_wave_only


func _get_group_list(special: int) -> Array[String]:
	var group_list_packed: PackedStringArray = _get_property(special, WaveSpecial.CsvProperty.GROUP_LIST).split(",")
	
	var group_list: Array[String] = []
	
	for group in group_list_packed:
		group_list.append(group)

	return group_list


func get_description(special: int) -> String:
	var description: String = _get_property(special, WaveSpecial.CsvProperty.DESCRIPTION)

	return description


func get_enabled(special: int) -> bool:
	var enabled: bool = _get_property(special, WaveSpecial.CsvProperty.ENABLED) == "TRUE"

	return enabled


func _get_hp_modifier(special_list: Array[int]) -> float:
	if special_list.is_empty():
		return 0.0

	var hp_mod_list: Array[float] = []

	for special in special_list:
		var hp_modifier: float = _get_property(special, WaveSpecial.CsvProperty.HP_MODIFIER).to_float()

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


func _get_uses_mana(special: int) -> bool:
	var uses_mana: bool = _get_property(special, WaveSpecial.CsvProperty.USES_MANA) == "TRUE"

	return uses_mana


# NOTE: in case creep has multiple specials, we return color
# of the first one. Mixing colors wouldn't look good.
func _get_base_color(special_list: Array[int]) -> Color:
	if special_list.is_empty():
		return Color.WHITE
	
	var first_special: int = special_list[0]
	var color_html: String = _get_property(first_special, WaveSpecial.CsvProperty.COLOR)
	var color: Color = Color.html(color_html)

	return color


func _get_property(special: int, property: WaveSpecial.CsvProperty) -> String:
	if !_properties.has(special):
		push_error("No properties for special: ", special)

		return ""

	var map: Dictionary = _properties[special]
	var property_value: String = map[property]

	return property_value


func _make_group_to_special_map() -> Dictionary:
	var result: Dictionary = {}

	var special_list: Array = _properties.keys()

	for special in special_list:
		var group_list: Array[String] = _get_group_list(special)

		for group in group_list:
			if !result.has(group):
				result[group] = []

			result[group].append(special)

	return result


func _get_creep_base_mana(special_list: Array[int], creep: Creep) -> float:
	var creep_should_have_mana: bool = false

	for special in special_list:
		var special_applies: bool = _special_applies_to_creep(special, creep)
		var special_uses_mana: bool = _get_uses_mana(special)

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
	var special_only_for_champions_or_bosses: bool = _get_champion_or_boss_wave_only(special)
	var special_applies: bool
	if special_only_for_champions_or_bosses:
		special_applies = creep_size == CreepSize.enm.BOSS || creep_size == CreepSize.enm.CHAMPION
	else:
		special_applies = true

	return special_applies


func creep_has_flock_special(creep: Creep) -> bool:
	var flock_special: BuffType = _buff_map[FLOCK]
	var creep_has_buff: bool = creep.get_buff_of_type(flock_special) != null

	return creep_has_buff
