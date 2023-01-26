extends Node2D


class_name Spell

# Spell contains code that is common between ProximitySpell
# and ProjectileSpell, which includes cast timer, cast area
# and spell parameters.

var cast_cd_mod: float = 0.0
var spell_info: Dictionary
var aura_info_container: AuraInfoContainer


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
	match aura.type:
		Properties.AuraType.DECREASE_SPELL_CAST_CD:
			if aura.is_expired:
				cast_cd_mod = 0.0
			else:
				cast_cd_mod = aura.get_value()

			$CastTimer.wait_time = spell_info[Properties.SpellParameter.CAST_CD] * (1.0 + cast_cd_mod)

	aura_info_container.apply_aura(aura)


func get_spell_parameter(parameter: int):
	return spell_info[parameter]
