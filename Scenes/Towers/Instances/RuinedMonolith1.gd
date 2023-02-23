extends Tower

# TODO: visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounce_damage_multiplier = 0.50},
		2: {bounce_damage_multiplier = 0.46},
		3: {bounce_damage_multiplier = 0.42},
		4: {bounce_damage_multiplier = 0.38},
		5: {bounce_damage_multiplier = 0.34},
		6: {bounce_damage_multiplier = 0.30},
	}


func _ready():
	var bounce_attack_buff = BounceAttack.new(3, _stats.bounce_damage_multiplier)
	bounce_attack_buff.apply_to_unit_permanent(self, self, 0, true)

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.10, 0.01)
	add_modifier(specials_modifier)
