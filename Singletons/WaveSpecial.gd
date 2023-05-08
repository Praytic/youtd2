extends Node


# Functions for dealing with specials that are applied to
# creep waves.

const PROPERTIES_PATH: String = "res://Data/wave_special_properties.csv"


enum enm {
	SPEED,
	GREATER_SPEED,
	XTREME_SPEED,
	SLOW,
	INVISIBLE,
	STRONG,
	RICH,
	RELIC_RAIDER,
	ULTRA_WISDOM,
	ARMORED,
	HEAVY_ARMORED,
	XTREME_ARMOR,
}

enum CsvProperty {
	ID,
	NAME,
	REQUIRED_WAVE_LEVEL,
	FREQUENCY,
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
}


var _properties: Dictionary = {}


func _init():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, WaveSpecial.CsvProperty.ID)


# TODO: implement correct randomization.
func get_random(wave: Wave) -> Array[int]:
	var random_special_list: Array[int] = []
	var available_special_list: Array[int] = _get_available_specials(wave)
	var special_count: int = _get_random_specials_count()

	for _i in range(0, special_count):
		if available_special_list.is_empty():
			break

		var random_index: int = randi_range(0, available_special_list.size() - 1)
		var random_special: int = available_special_list.pop_at(random_index)

		random_special_list.append(random_special)
	
	return random_special_list


func convert_to_string(special: int) -> String:
	var string: String = _get_property(special, WaveSpecial.CsvProperty.NAME)

	return string


func apply_to_creep(special: int, creep: Creep):
	if !_buff_map.has(special):
		push_error("No buff for special: ", special)

		return

	var buff: BuffType = _buff_map[special]
	buff.apply_to_unit_permanent(creep, creep, 0)


func _get_random_specials_count() -> int:
	if Utils.rand_chance(0.5):
		return 0
	else:
		if Utils.rand_chance(0.5):
			return 1
		else:
			return 2


func _get_available_specials(wave: Wave) -> Array[int]:
	var all_special_list: Array = _properties.keys()
	var available_special_list: Array[int] = []

	var wave_level: int = wave.get_wave_number()

	for special in all_special_list:
		var required_level: int = _get_required_wave_level(special)
		var is_available: bool = wave_level >= required_level

		if is_available:
			available_special_list.append(special)

	return available_special_list


func _get_required_wave_level(special: int) -> int:
	var level: int = _get_property(special, WaveSpecial.CsvProperty.REQUIRED_WAVE_LEVEL).to_int()

	return level


func _get_frequency(special: int) -> int:
	var frequency: int = _get_property(special, WaveSpecial.CsvProperty.FREQUENCY).to_int()

	return frequency


func _get_property(special: int, property: WaveSpecial.CsvProperty) -> String:
	if !_properties.has(special):
		push_error("No properties for special: ", special)

		return ""

	var map: Dictionary = _properties[special]
	var property_value: String = map[property]

	return property_value
