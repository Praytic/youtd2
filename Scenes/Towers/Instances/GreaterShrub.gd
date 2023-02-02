extends Tower


func _get_base_properties() -> Dictionary:
	return {}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.05, 0.004)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.5, 0.04)

	return specials_modifier
