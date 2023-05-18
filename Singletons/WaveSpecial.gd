extends Node


# Functions for dealing with specials that are applied to
# creep waves.

const PROPERTIES_PATH: String = "res://Data/wave_special_properties.csv"


enum CsvProperty {
	ID,
	NAME,
	HP_MODIFIER,
	REQUIRED_WAVE_LEVEL,
	FREQUENCY,
	DESCRIPTION,
}


# TODO: figure out real values. Maybe special count
# distribution changes as the game progresses? For example
# less 0 specials for later waves.
const _special_count_chances: Dictionary = {
	0: 50,
	1: 30,
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
	31: CreepFlock.new(self),
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

# NOTE: some wave specials are disabled because they are
# incomplete
var _disabled_special_list: Array[int] = [4, 28, 31, 32, 36, 40]

var _properties: Dictionary = {}


func _init():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, WaveSpecial.CsvProperty.ID)

	for special in _buff_map.keys():
		var buff: BuffType = _buff_map[special]
		var special_name: String = convert_to_string(special)
		var description: String = _get_description(special)
		var tooltip: String = "%s\n%s" % [special_name, description]

		buff.set_buff_tooltip(tooltip)


# TODO: implement correct randomization.
func get_random(wave: Wave) -> Array[int]:
	var random_special_list: Array[int] = []
	var available_special_list: Array[int] = _get_available_specials(wave)
	var special_count: int = Utils.random_weighted_pick(_special_count_chances)


	var special_to_frequency_map: Dictionary = {}

	for special in available_special_list:
		var frequency: int = _get_frequency(special)
		special_to_frequency_map[special] = frequency

	for _i in range(0, special_count):
		if available_special_list.is_empty():
			break

		var random_special: int = Utils.random_weighted_pick(special_to_frequency_map)
		special_to_frequency_map.erase(random_special)

		random_special_list.append(random_special)
	
	return random_special_list


func convert_to_string(special: int) -> String:
	var string: String = _get_property(special, WaveSpecial.CsvProperty.NAME)

	return string


func apply_to_creep(special: int, creep: Creep):
	if !_buff_map.has(special):
		push_error("No buff for special: ", special)

		return

	var hp_modifier: float = _get_hp_modifier(special)
	creep.modify_property(Modification.Type.MOD_HP_PERC, hp_modifier)

	var buff: BuffType = _buff_map[special]
	buff.apply_to_unit_permanent(creep, creep, 0)


func _get_available_specials(wave: Wave) -> Array[int]:
	var all_special_list: Array = _properties.keys()
	var available_special_list: Array[int] = []

	var wave_level: int = wave.get_wave_number()

	for special in all_special_list:
		var required_level: int = _get_required_wave_level(special)
		var is_available: bool = wave_level >= required_level

		if is_available:
			available_special_list.append(special)

	for disabled_special in _disabled_special_list:
		available_special_list.erase(disabled_special)

	return available_special_list


func _get_required_wave_level(special: int) -> int:
	var level: int = _get_property(special, WaveSpecial.CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

	return level


func _get_frequency(special: int) -> int:
	var frequency: int = _get_property(special, WaveSpecial.CsvProperty.FREQUENCY).to_int()

	return frequency


func _get_description(special: int) -> String:
	var description: String = _get_property(special, WaveSpecial.CsvProperty.DESCRIPTION)

	return description


func _get_hp_modifier(special: int) -> float:
	var hp_modifier: float = _get_property(special, WaveSpecial.CsvProperty.HP_MODIFIER).to_float()

	return hp_modifier


func _get_property(special: int, property: WaveSpecial.CsvProperty) -> String:
	if !_properties.has(special):
		push_error("No properties for special: ", special)

		return ""

	var map: Dictionary = _properties[special]
	var property_value: String = map[property]

	return property_value
