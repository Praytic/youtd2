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


func _ready():
	pass


func init(spell_info_arg: Dictionary):
	spell_info = spell_info_arg
	default_aura_info_list = spell_info[Properties.SpellParameter.AURA_INFO_LIST]

	$CastTimer.wait_time = spell_info[Properties.SpellParameter.CAST_CD]
	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, spell_info[Properties.SpellParameter.CAST_RANGE])


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

	var crit_modifier: float = DEFAULT_CRIT_MODIFIER + parameter_mod_map[Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_CRIT_MODIFIER]
	var is_critical: bool = get_is_critical()

	for aura_info in modded_aura_info_list:
		var type: int = aura_info[Properties.AuraParameter.TYPE]
		var duration: int = aura_info[Properties.AuraParameter.DURATION]
		var period: int = aura_info[Properties.AuraParameter.PERIOD]
		var is_damage_aura = type == Properties.AuraType.DAMAGE_MOB_HEALTH
		var is_poison_aura = type == Properties.AuraType.DAMAGE_MOB_HEALTH && duration > 0 && period > 0

		if is_damage_aura:
# 			Apply damage modifier from aura's
			modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + parameter_mod_map[Properties.AuraType.INCREASE_DAMAGE_MOB_HEALTH_AURA_VALUE])

#			Apply crit modifier
			if is_critical:
				modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + crit_modifier)

		if is_poison_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.DURATION, 1.0 + parameter_mod_map[Properties.AuraType.INCREASE_POISON_AURA_DURATION])


	return modded_aura_info_list


func modify_aura_info_value(aura_info: Dictionary, value_key: int, mod_value: float):
	if aura_info[value_key] is Array:
		var modded_value_range: Array = (aura_info[value_key] as Array).duplicate(true)
		
		for value in modded_value_range:
			value *= mod_value

		aura_info[value_key] = modded_value_range
	else:
		aura_info[value_key] *= mod_value


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

	match aura.type:
		Properties.AuraType.DECREASE_SPELL_CAST_CD:
			$CastTimer.wait_time = get_modded_spell_parameter(Properties.SpellParameter.CAST_CD, Properties.AuraType.DECREASE_SPELL_CAST_CD)
		Properties.AuraType.INCREASE_SPELL_CAST_RANGE:			
			var cast_range: float = get_modded_spell_parameter(Properties.SpellParameter.CAST_RANGE, Properties.AuraType.INCREASE_SPELL_CAST_RANGE)
			Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)


func get_spell_parameter(parameter: int):
	return spell_info[parameter]


func get_modded_spell_parameter(spell_parameter: int, mod_aura_type: int) -> float:
	var default_value: float = spell_info[spell_parameter]
	var modifier: float = parameter_mod_map[mod_aura_type]
	var modded = default_value * (1.0 + modifier)

	return modded


func get_is_miss() -> bool:
	var miss_chance: float = min(1.0, DEFAULT_MISS_CHANCE + parameter_mod_map[Properties.AuraType.INCREASE_SPELL_MISS_CHANCE])
	var out: bool = Utils.rand_chance(miss_chance)

	return out
