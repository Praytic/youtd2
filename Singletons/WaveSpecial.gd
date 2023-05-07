extends Node


# Functions for dealing with specials that are applied to
# creep waves.

# TODO: implement wave requirement. If wave level is not
# high enough certain buffs shouldn't be.


enum enm {
	NONE,
	SPEED,
	GREATER_SPEED,
	XTREME_SPEED,
	SLOW,
	INVISIBLE,
}


var _buff_speed: BuffType = CreepSpeed.new(self)
var _buff_greater_speed: BuffType = CreepGreaterSpeed.new(self)
var _buff_xtreme_speed: BuffType = CreepXtremeSpeed.new(self)
var _buff_slow: BuffType = CreepSlow.new(self)
var _buff_invisible: BuffType = CreepInvisible.new(self)


# TODO: implement correct randomization.
func get_random() -> WaveSpecial.enm:
	var special_list: Array = WaveSpecial.enm.values()
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

	push_error("WaveSpecial.convert_to_string() doesn't handle special: ", special)

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

	push_error("WaveSpecial._get_buff() doesn't handle special: ", special)

	return null
