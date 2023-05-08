extends Node


# Functions for dealing with specials that are applied to
# creep waves.


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


var _buff_map: Dictionary = {
	WaveSpecial.enm.SPEED: CreepSpeed.new(self),
	WaveSpecial.enm.GREATER_SPEED: CreepGreaterSpeed.new(self),
	WaveSpecial.enm.XTREME_SPEED: CreepXtremeSpeed.new(self),
	WaveSpecial.enm.SLOW: CreepSlow.new(self),
	WaveSpecial.enm.INVISIBLE: CreepInvisible.new(self),
	WaveSpecial.enm.STRONG: CreepStrong.new(self),
	WaveSpecial.enm.RICH: CreepRich.new(self),
	WaveSpecial.enm.RELIC_RAIDER: CreepRelicRaider.new(self),
	WaveSpecial.enm.ULTRA_WISDOM: CreepUltraWisdom.new(self),
	WaveSpecial.enm.ARMORED: CreepArmored.new(self),
	WaveSpecial.enm.HEAVY_ARMORED: CreepHeavyArmored.new(self),
	WaveSpecial.enm.XTREME_ARMOR: CreepXtremeArmor.new(self),
}

var _required_level_map: Dictionary = {
	WaveSpecial.enm.SPEED: 0,
	WaveSpecial.enm.GREATER_SPEED: 16,
	WaveSpecial.enm.XTREME_SPEED: 24,
	WaveSpecial.enm.SLOW: 32,
	WaveSpecial.enm.INVISIBLE: 0,
	WaveSpecial.enm.STRONG: 16,
	WaveSpecial.enm.RICH: 0,
	WaveSpecial.enm.RELIC_RAIDER: 0,
	WaveSpecial.enm.ULTRA_WISDOM: 0,
	WaveSpecial.enm.ARMORED: 0,
	WaveSpecial.enm.HEAVY_ARMORED: 16,
	WaveSpecial.enm.XTREME_ARMOR: 32,
}

var _string_map: Dictionary = {
	WaveSpecial.enm.SPEED: "Speed",
	WaveSpecial.enm.GREATER_SPEED: "Greater Speed",
	WaveSpecial.enm.XTREME_SPEED: "Xtreme Speed",
	WaveSpecial.enm.SLOW: "Slow",
	WaveSpecial.enm.INVISIBLE: "Invisible",
	WaveSpecial.enm.STRONG: "Strong",
	WaveSpecial.enm.RICH: "Rich",
	WaveSpecial.enm.RELIC_RAIDER: "Relic Raider",
	WaveSpecial.enm.ULTRA_WISDOM: "Ultra Wisdom",
	WaveSpecial.enm.ARMORED: "Armored",
	WaveSpecial.enm.HEAVY_ARMORED: "Heavy Armored",
	WaveSpecial.enm.XTREME_ARMOR: "Xtreme Armor",
}


func _init():
	var map_list: Array[Dictionary] = [_buff_map, _required_level_map, _string_map]

	for map in map_list:
		for special in WaveSpecial.enm.values():
			if !map.has(special):
				push_error("Not all properties have been defined for special: ", special)


# TODO: implement correct randomization.
func get_random(wave: Wave) -> Array[int]:
	var random_special_list: Array[int] = []
	var available_special_list: Array[int] = _get_available_specials(wave)
	var special_count: int = _get_random_specials_count()

	for _i in range(0, special_count):
		if available_special_list.is_empty():
			break

		var random_index: int = randi_range(0, available_special_list.size() - 1)
		var random_special: WaveSpecial.enm = available_special_list.pop_at(random_index)

		random_special_list.append(random_special)
	
	return random_special_list


func convert_to_string(special: WaveSpecial.enm) -> String:
	var string: String = _string_map.get(special, "unknown special")

	return string


func apply_to_creep(special: WaveSpecial.enm, creep: Creep):
	var buff: BuffType = _buff_map.get(special, null)

	if buff != null:
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
	var all_special_list: Array = WaveSpecial.enm.values()
	var available_special_list: Array[int] = []

	var wave_level: int = wave.get_wave_number()

	for special in all_special_list:
		var required_level: int = _required_level_map.get(special, 0)
		var is_available: bool = wave_level >= required_level

		if is_available:
			available_special_list.append(special)

	return available_special_list
