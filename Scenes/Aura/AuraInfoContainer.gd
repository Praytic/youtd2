extends Node

# AuraInfoContainer stores the aura info list. It is used by
# ProximitySpell and ProjectileSpell. Aura info is the
# description of an aura, which is used to make the actual
# aura instance. This container handles aura's modifying
# other aura's.

# Aura modifying another aura is implemented like this:
# 
# 1. A tower applies an aura to another the tower.
# 2. The affected tower calls apply_aura() on it's AuraInfoContainer.
# 3. AuraInfoContainer remembers the modifier from given aura.
# 4. Affected tower needs to pass it's aura info list to a projectile.
# 5. Affected tower calls get_modded() on it's AuraInfoContainer.
# 6. get_modded() returns the aura info list with modifiers applied.
# 7. Projectile stores the modified aura info list.
# 8. Projectile reaches the mob and passes modified aura info list to the mob.
# 9. Mob creates aura's based on the modified aura info list.

class_name AuraInfoContainer


var default_aura_info_list: Array

var mod_map: Dictionary = {
	Properties.AuraType.MODIFY_VALUE_FOR_DAMAGE_AURA: 0.0,
	Properties.AuraType.MODIFY_DURATION_FOR_POISON_AURA: 0.0,
	Properties.AuraType.MODIFY_CRIT_CHANCE: 0.0,
	Properties.AuraType.MODIFY_CRIT_MODIFIER: 0.0,
	Properties.AuraType.MODIFY_MISS_CHANCE: 0.0
}

const DEFAULT_CRIT_CHANCE: float = 0.25
const DEFAULT_CRIT_MODIFIER: float = 1.0
const DEFAULT_MISS_CHANCE: float = 0.0


func _init(default_aura_info_list_arg: Array):
	default_aura_info_list = default_aura_info_list_arg


func _ready():
	pass


func apply_aura(aura: Aura):
	if mod_map.has(aura.type):
		if aura.is_expired:
			mod_map[aura.type] = 0.0
		else:
			mod_map[aura.type] = aura.get_value()


# Returns aura info list with all mods applied
# NOTE: have to be careful not to modify default aura list, so use duplicate()
# NOTE: get_modded() also implements critical damage, even though basic criticals don't come from aura's
func get_modded() -> Array:
# 	DESIGN DECISION: it makes sense that if spell misses
# 	then none of the aura's are applied, but maybe there are
# 	some exceptions?
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

	var crit_modifier: float = DEFAULT_CRIT_MODIFIER + mod_map[Properties.AuraType.MODIFY_CRIT_MODIFIER]
	var is_critical: bool = get_is_critical()

	for aura_info in modded_aura_info_list:
		var type: int = aura_info[Properties.AuraParameter.TYPE]
		var duration: int = aura_info[Properties.AuraParameter.DURATION]
		var period: int = aura_info[Properties.AuraParameter.PERIOD]
		var is_damage_aura = type == Properties.AuraType.DAMAGE
		var is_poison_aura = type == Properties.AuraType.DAMAGE && duration > 0 && period > 0

		if is_damage_aura:
# 			Apply damage modifier from aura's
			modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + mod_map[Properties.AuraType.MODIFY_VALUE_FOR_DAMAGE_AURA])

#			Apply crit modifier
			if is_critical:
				modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + crit_modifier)

		if is_poison_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.DURATION, 1.0 + mod_map[Properties.AuraType.MODIFY_DURATION_FOR_POISON_AURA])


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
	var crit_chance: float = min(1.0, DEFAULT_CRIT_CHANCE + mod_map[Properties.AuraType.MODIFY_CRIT_CHANCE])
	var out: bool = Utils.rand_chance(crit_chance)

	return out


func get_is_miss() -> bool:
	var miss_chance: float = min(1.0, DEFAULT_MISS_CHANCE + mod_map[Properties.AuraType.MODIFY_MISS_CHANCE])
	var out: bool = Utils.rand_chance(miss_chance)

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
