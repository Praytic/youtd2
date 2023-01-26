extends Node2D


class_name Spell

# Spell contains code that is common between ProximitySpell
# and ProjectileSpell, which includes cast timer, cast area
# and spell parameters.

var spell_info: Dictionary
var aura_info_container: AuraInfoContainer
var spell_parameter_mod_map: Dictionary = {
	Properties.AuraType.DECREASE_SPELL_CAST_CD: 0.0,
	Properties.AuraType.INCREASE_SPELL_CAST_RANGE: 0.0,
}


func _ready():
	pass


func init(spell_info_arg: Dictionary):
	spell_info = spell_info_arg

	$CastTimer.wait_time = spell_info[Properties.SpellParameter.CAST_CD]

	Utils.circle_shape_set_radius($CastArea/CollisionShape2D, spell_info[Properties.SpellParameter.CAST_RANGE])

	var aura_info_list: Array = spell_info[Properties.SpellParameter.AURA_INFO_LIST]
	aura_info_container = AuraInfoContainer.new(aura_info_list)


func get_cast_timer() -> Timer:
	return $CastTimer as Timer


func get_cast_area() -> Area2D:
	return $CastArea as Area2D


func get_modded_aura_info() -> Array:
	return aura_info_container.get_modded()


func apply_aura(aura: Aura):
	if spell_parameter_mod_map.has(aura.type):
		if aura.is_expired:
			spell_parameter_mod_map[aura.type] = 0.0
		else:
			spell_parameter_mod_map[aura.type] = aura.get_value()

	match aura.type:
		Properties.AuraType.DECREASE_SPELL_CAST_CD:
			$CastTimer.wait_time = get_modded_spell_parameter(Properties.SpellParameter.CAST_CD, Properties.AuraType.DECREASE_SPELL_CAST_CD)
		Properties.AuraType.INCREASE_SPELL_CAST_RANGE:			
			var cast_range: float = get_modded_spell_parameter(Properties.SpellParameter.CAST_RANGE, Properties.AuraType.INCREASE_SPELL_CAST_RANGE)
			Utils.circle_shape_set_radius($CastArea/CollisionShape2D, cast_range)

	aura_info_container.apply_aura(aura)


func get_spell_parameter(parameter: int):
	return spell_info[parameter]


func get_modded_spell_parameter(spell_parameter: int, mod_aura_type: int) -> float:
	$CastTimer.wait_time
	var default_value: float = spell_info[spell_parameter]
	var modifier: float = spell_parameter_mod_map[mod_aura_type]
	var modded = default_value * (1.0 + modifier)

	return modded
