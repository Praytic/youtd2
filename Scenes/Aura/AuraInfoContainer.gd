extends Node


class_name AuraInfoContainer


var default_aura_info_list: Array

var damage_aura_value_mod: float = 0.0


func _init(default_aura_info_list_arg: Array):
	default_aura_info_list = default_aura_info_list_arg


func _ready():
	pass


func apply_aura(aura: Aura):
	match aura.type:
		Properties.AuraType.MODIFY_DAMAGE_AURA_VALUE:
			if aura.is_expired:
				damage_aura_value_mod = 0.0
			else:
				damage_aura_value_mod = aura.get_value()


# Returns aura info list with all mods applied
# NOTE: have to be careful not to modify default aura list, so use duplicate()
func get_modded() -> Array:
	var modded_aura_list: Array = default_aura_info_list.duplicate(true)

	for aura_info in modded_aura_list:
		var is_damage_aura = aura_info[Properties.AuraParameter.TYPE] == Properties.AuraType.DAMAGE

		if !is_damage_aura:
			continue
		
		modify_aura_info_value(aura_info, 1.0 + damage_aura_value_mod)

	return modded_aura_list


func modify_aura_info_value(aura_info: Dictionary, mod_value: float):
	if aura_info[Properties.AuraParameter.VALUE] is Array:
		var modded_value_range: Array = (aura_info[Properties.AuraParameter.VALUE] as Array).duplicate(true)
		
		for value in modded_value_range:
			value *= mod_value

		aura_info[Properties.AuraParameter.VALUE] = modded_value_range
	else:
		aura_info[Properties.AuraParameter.VALUE] *= mod_value


