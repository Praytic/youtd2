extends Tower


func _get_base_properties() -> Dictionary:
	return {}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.15, 0.01)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.15, 0.01)

	return specials_modifier
