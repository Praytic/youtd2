extends Node


# Functions for dealing with specials that are applied to
# creep waves.


enum enm {
	NONE,
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


var _buff_speed: BuffType = CreepSpeed.new(self)
var _buff_greater_speed: BuffType = CreepGreaterSpeed.new(self)
var _buff_xtreme_speed: BuffType = CreepXtremeSpeed.new(self)
var _buff_slow: BuffType = CreepSlow.new(self)
var _buff_invisible: BuffType = CreepInvisible.new(self)
var _buff_strong: BuffType = CreepStrong.new(self)
var _buff_rich: BuffType = CreepRich.new(self)
var _buff_relic_raider: BuffType = CreepRelicRaider.new(self)
var _buff_ultra_wisdom: BuffType = CreepUltraWisdom.new(self)
var _buff_armored: BuffType = CreepArmored.new(self)
var _buff_heavy_armored: BuffType = CreepHeavyArmored.new(self)
var _buff_xtreme_armor: BuffType = CreepXtremeArmor.new(self)


# TODO: implement correct randomization.
func get_random(wave: Wave) -> WaveSpecial.enm:
	var all_special_list: Array = WaveSpecial.enm.values()
	var special_list: Array = []

	var wave_level: int = wave.get_wave_number()

	for special in all_special_list:
		var required_level: int = _get_required_wave_level(special)
		var is_available: bool = wave_level >= required_level

		if is_available:
			special_list.append(special)

	if special_list.is_empty():
		push_error("No specials are available")

		return WaveSpecial.enm.NONE

	var random_index: int = randi_range(0, special_list.size() - 1)
	var random_special: WaveSpecial.enm = special_list[random_index]

	return random_special


func convert_to_string(special: WaveSpecial.enm) -> String:
	match special:
		WaveSpecial.enm.NONE: return ""
		WaveSpecial.enm.SPEED: return "Speed"
		WaveSpecial.enm.GREATER_SPEED: return "Greater Speed"
		WaveSpecial.enm.XTREME_SPEED: return "Xtreme Speed"
		WaveSpecial.enm.SLOW: return "Slow"
		WaveSpecial.enm.INVISIBLE: return "Invisible"
		WaveSpecial.enm.STRONG: return "Strong"
		WaveSpecial.enm.RICH: return "Rich"
		WaveSpecial.enm.RELIC_RAIDER: return "Relic Raider"
		WaveSpecial.enm.ULTRA_WISDOM: return "Ultra Wisdom"
		WaveSpecial.enm.ARMORED: return "Armored"
		WaveSpecial.enm.HEAVY_ARMORED: return "Heavy Armored"
		WaveSpecial.enm.XTREME_ARMOR: return "Xtreme Armor"

	push_error("Unhandled special: ", special)

	return "unknown special"


func apply_to_creep(special: WaveSpecial.enm, creep: Creep):
	var buff: BuffType = _get_buff(special)

	if buff != null:
		buff.apply_to_unit_permanent(creep, creep, 0)


func _get_buff(special: WaveSpecial.enm) -> BuffType:
	match special:
		WaveSpecial.enm.NONE: return null
		WaveSpecial.enm.SPEED: return _buff_speed
		WaveSpecial.enm.GREATER_SPEED: return _buff_greater_speed
		WaveSpecial.enm.XTREME_SPEED: return _buff_xtreme_speed
		WaveSpecial.enm.SLOW: return _buff_slow
		WaveSpecial.enm.INVISIBLE: return _buff_invisible
		WaveSpecial.enm.STRONG: return _buff_strong
		WaveSpecial.enm.RICH: return _buff_rich
		WaveSpecial.enm.RELIC_RAIDER: return _buff_relic_raider
		WaveSpecial.enm.ULTRA_WISDOM: return _buff_ultra_wisdom
		WaveSpecial.enm.ARMORED: return _buff_armored
		WaveSpecial.enm.HEAVY_ARMORED: return _buff_heavy_armored
		WaveSpecial.enm.XTREME_ARMOR: return _buff_xtreme_armor

	push_error("Unhandled special: ", special)

	return null


func _get_required_wave_level(special: WaveSpecial.enm) -> int:
	match special:
		WaveSpecial.enm.NONE: return 0
		WaveSpecial.enm.SPEED: return 0
		WaveSpecial.enm.GREATER_SPEED: return 16
		WaveSpecial.enm.XTREME_SPEED: return 24
		WaveSpecial.enm.SLOW: return 32
		WaveSpecial.enm.INVISIBLE: return 0
		WaveSpecial.enm.STRONG: return 16
		WaveSpecial.enm.RICH: return 0
		WaveSpecial.enm.RELIC_RAIDER: return 0
		WaveSpecial.enm.ULTRA_WISDOM: return 0
		WaveSpecial.enm.ARMORED: return 0
		WaveSpecial.enm.HEAVY_ARMORED: return 16
		WaveSpecial.enm.XTREME_ARMOR: return 32

	push_error("Unhandled special: ", special)

	return 0
