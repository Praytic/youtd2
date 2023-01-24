extends Node


class_name AuraInfoContainer


var default_aura_info_list: Array

var mod_value_for_damage_aura: float = 0.0
var mod_duration_for_poison_aura: float = 0.0


func _init(default_aura_info_list_arg: Array):
	default_aura_info_list = default_aura_info_list_arg


func _ready():
	pass


func apply_aura(aura: Aura):
	match aura.type:
		Properties.AuraType.MODIFY_VALUE_FOR_DAMAGE_AURA:
			if aura.is_expired:
				mod_value_for_damage_aura = 0.0
			else:
				mod_value_for_damage_aura = aura.get_value()
		Properties.AuraType.MODIFY_DURATION_FOR_POISON_AURA:
			if aura.is_expired:
				mod_duration_for_poison_aura = 0.0
			else:
				mod_duration_for_poison_aura = aura.get_value()



# Returns aura info list with all mods applied
# NOTE: have to be careful not to modify default aura list, so use duplicate()
func get_modded() -> Array:
	var modded_aura_list: Array = default_aura_info_list.duplicate(true)

	for aura_info in modded_aura_list:
		var type: int = aura_info[Properties.AuraParameter.TYPE]
		var duration: int = aura_info[Properties.AuraParameter.DURATION]
		var period: int = aura_info[Properties.AuraParameter.PERIOD]
		var is_damage_aura = type == Properties.AuraType.DAMAGE
		var is_poison_aura = type == Properties.AuraType.DAMAGE && duration > 0 && period > 0

		if is_damage_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.VALUE, 1.0 + mod_value_for_damage_aura)
		
		if is_poison_aura:
			modify_aura_info_value(aura_info, Properties.AuraParameter.DURATION, 1.0 + mod_duration_for_poison_aura)


	return modded_aura_list


func modify_aura_info_value(aura_info: Dictionary, value_key: int, mod_value: float):
	if aura_info[value_key] is Array:
		var modded_value_range: Array = (aura_info[value_key] as Array).duplicate(true)
		
		for value in modded_value_range:
			value *= mod_value

		aura_info[value_key] = modded_value_range
	else:
		aura_info[value_key] *= mod_value