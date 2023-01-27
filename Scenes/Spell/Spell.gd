extends Node2D


class_name Spell

# Spell contains code that is common between ProximitySpell
# and ProjectileSpell, which includes cast timer, cast area,
# spell parameters. It also keeps track of modifiers from
# auras and applies them.

# Aura modifying another aura is implemented like this:
# 
# 1. A tower applies an aura to another the tower.
# 2. The affected tower calls apply_aura() on it's spells.
# 3. Spell remembers the modifier from given aura.
# 4. Affected spell needs to pass it's aura info list to a projectile.
# 5. Affected spell uses get_modded_aura_info_list().
# 6. get_modded_aura_info_list() returns the aura info list with modifiers applied.
# 7. Projectile stores the modified aura info list.
# 8. Projectile reaches the mob and passes modified aura info list to the mob.
# 9. Mob creates aura's based on the modified aura info list.


const DEFAULT_MISS_CHANCE: float = 0.0
const DEFAULT_CRIT_CHANCE: float = 0.25
const DEFAULT_CRIT_MODIFIER: float = 1.0
const CAST_RANGE_MAX: float = 10000.0
# NOTE: godot timers are unreliable at durations close to
# frame duration (0.16s), so don't go below 0.3
const CAST_CD_MIN: float = 0.3

var level: int = 1
var spell_info: Dictionary
var default_aura_info_list: Array
var parameter_mod_map: Dictionary = {
# 	Spell parameters
	Properties.AuraType.DECREASE_SPELL_CAST_CD: 0.0,
	Properties.AuraType.INCREASE_SPELL_CAST_RANGE: 0.0,
	Properties.AuraType.INCREASE_SPELL_MISS_CHANCE: 0.0,

# 	Aura parameters
	Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_VALUE: 0.0,
	Properties.AuraType.INCREASE_POISON_AURA_DURATION: 0.0,
	Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_CRIT_CHANCE: 0.0,
	Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_CRIT_MODIFIER: 0.0
}

enum ModifyType {
	MULTIPLICATIVE,
	ADDITIVE
}


func _ready():
	pass


func init(spell_info_arg: Dictionary):
	spell_info = spell_info_arg
	default_aura_info_list = spell_info[Properties.SpellParameter.AURA_INFO_LIST]

	load_spell_parameters()


func get_cast_timer() -> Timer:
	return $CastTimer as Timer


func get_cast_area() -> Area2D:
	return $CastArea as Area2D


func get_modded_aura_info() -> Array:
#	NOTE: implement missing spells by returning empty aura
#	info list. For example, a projectile spell would create
#	a projectile with no aura's and it would have no effect
#	when it reaches the mob.
	var is_miss: bool = get_is_miss()

	if is_miss:
		return []

	var modded_aura_info_list: Array = []

	# Add aura's based on their ADD_CHANCE
	# NOTE: ADD_CHANCE is handled in a weird way like this to
	# implement the behavior of aura's with same ADD_CHANCE
	# succeeding together. If we processed ADD_CHANCE values
	# individually, then aura's with same add chance would
	# succeed independently.
	var add_success_map: Dictionary = get_add_success_map()

	for aura_info in default_aura_info_list:
		var add_chance: float = aura_info[Properties.AuraParameter.ADD_CHANCE]
		var add_success: bool = add_success_map[add_chance]

		if add_success:
			modded_aura_info_list.append(aura_info.duplicate(true))

# 	NOTE: roll critical chance once and use it for all
# 	aura's in the spell, otherwise aura's would have
# 	mismatched criticals
	var is_critical: bool = get_is_critical()

	for aura_info in modded_aura_info_list:
		apply_level_modifiers_to_aura_values(aura_info)
		apply_aura_modifiers_to_aura_values(aura_info, is_critical)

	return modded_aura_info_list


func apply_aura_modifiers_to_aura_values(aura_info: Dictionary, is_critical: bool):
	var type: int = aura_info[Properties.AuraParameter.TYPE]
	var duration: int = aura_info[Properties.AuraParameter.DURATION]
	var period: int = aura_info[Properties.AuraParameter.PERIOD]
	var is_damage_aura = type == Properties.AuraType.DAMAGE_MOB_HEALTH
	var is_poison_aura = type == Properties.AuraType.DAMAGE_MOB_HEALTH && duration > 0 && period > 0

	if is_damage_aura:
# 			Apply damage modifier from aura's
		modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, parameter_mod_map[Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_VALUE], ModifyType.MULTIPLICATIVE)

#			Apply crit modifier
		if is_critical:
			var crit_modifier_modifier: float = parameter_mod_map[Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_CRIT_MODIFIER]
			var crit_modifier: float = DEFAULT_CRIT_MODIFIER + crit_modifier_modifier
			modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, crit_modifier, ModifyType.MULTIPLICATIVE)

	if is_poison_aura:
		modify_aura_info_value(aura_info, Properties.AuraParameter.DURATION, parameter_mod_map[Properties.AuraType.INCREASE_POISON_AURA_DURATION], ModifyType.MULTIPLICATIVE)

func modify_aura_info_value(aura_info: Dictionary, value_key: int, mod_value: float, modifyType: int):
	if aura_info[value_key] is Array:
		var modded_value_range: Array = (aura_info[value_key] as Array).duplicate(true)
		
		for i in range(modded_value_range.size()):
			modded_value_range[i] = modify_aura_info_value_helper(modded_value_range[i], mod_value, modifyType)

		aura_info[value_key] = modded_value_range
	else:
		aura_info[value_key] = modify_aura_info_value_helper(aura_info[value_key], mod_value, modifyType)


func modify_aura_info_value_helper(value: float, mod_value: float, modifyType: int) -> float:
	match modifyType:
		ModifyType.MULTIPLICATIVE: return value * (1.0 + mod_value)
		ModifyType.ADDITIVE: return value + mod_value
		_: return 0.0


func get_is_critical() -> bool:
	var crit_chance: float = min(1.0, DEFAULT_CRIT_CHANCE + parameter_mod_map[Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_CRIT_CHANCE])
	var out: bool = Utils.rand_chance(crit_chance)

	return out


# Returns a map that contains chance values of aura's mapped to
# whether the chance succeeded or not. Note that aura's with same chance value always succeed together.
func get_add_success_map() -> Dictionary:
	var out: Dictionary = {}

	for aura_info in default_aura_info_list:
		var add_chance: float = aura_info[Properties.AuraParameter.ADD_CHANCE]
		var already_rolled: bool = out.has(add_chance)

		if !already_rolled:
			var add_success: bool = Utils.rand_chance(add_chance)
			out[add_chance] = add_success

	return out


func apply_aura(aura: Aura):
	if parameter_mod_map.has(aura.type):
		if aura.is_expired:
			parameter_mod_map[aura.type] = 0.0
		else:
			parameter_mod_map[aura.type] = aura.get_value()

#		Parameter mod map changed so reload spell parameters
		load_spell_parameters()


func get_spell_parameter(parameter: int):
	return spell_info[parameter]


func get_modded_spell_parameter(spell_parameter: int, mod_aura_type: int, level_mod_type: int) -> float:
	var default_value: float = spell_info[spell_parameter]
	var aura_modifier: float = parameter_mod_map[mod_aura_type]
	var level_modifier_value: float = spell_info[level_mod_type]
	var level_modifier_sign: int = Properties.spell_level_mod_sign_map[level_mod_type]
	var level_modifier: float = level_modifier_sign * (level - 1) * level_modifier_value
	var modded: float = default_value * (1.0 + aura_modifier + level_modifier)

	return modded


func get_is_miss() -> bool:
	var miss_chance: float = min(1.0, DEFAULT_MISS_CHANCE + parameter_mod_map[Properties.AuraType.INCREASE_SPELL_MISS_CHANCE])
	var out: bool = Utils.rand_chance(miss_chance)

	return out


func load_spell_parameters():
	var cast_cd: float = max(CAST_CD_MIN, get_modded_spell_parameter(Properties.SpellParameter.CAST_CD, Properties.AuraType.DECREASE_SPELL_CAST_CD, Properties.SpellParameter.LEVEL_DECREASE_CAST_CD))
	$CastTimer.wait_time = cast_cd

	var cast_range: float = min(CAST_RANGE_MAX, get_modded_spell_parameter(Properties.SpellParameter.CAST_RANGE, Properties.AuraType.INCREASE_SPELL_CAST_RANGE, Properties.SpellParameter.LEVEL_INCREASE_CAST_RANGE))
	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)


func change_level(new_level: int):
	level = new_level

#	Spell parameters could be affected by level change so
#	reload them.
	load_spell_parameters()


func apply_level_modifiers_to_aura_values(aura_info: Dictionary):
	for level_parameter in Properties.aura_level_parameter_list:
		var affected_parameter: int = Properties.aura_level_parameter_map[level_parameter]
		var level_modifier_value: float = aura_info[level_parameter]
		var level_modifier_sign: int = Properties.aura_level_mod_sign_map[level_parameter]
		var level_modifier: float = level_modifier_sign * (level - 1) * level_modifier_value
		modify_aura_info_value(aura_info, affected_parameter, level_modifier, ModifyType.ADDITIVE)
