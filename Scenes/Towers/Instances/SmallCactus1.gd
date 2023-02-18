class_name SmallCactus1
extends Tower


const _stats_map: Dictionary = {
	1: {value = 0.15, value_add = 0.01},
	2: {value = 0.17, value_add = 0.011},
	3: {value = 0.19, value_add = 0.012},
	4: {value = 0.21, value_add = 0.013},
	5: {value = 0.23, value_add = 0.014},
	6: {value = 0.25, value_add = 0.016},
}


func _ready():
	var tier: int = get_tier()
	var stats = _stats_map[tier]

#	NOTE: splash values are the same for all tiers
	var splash_attack_buff = SplashAttack.new({320: 0.5})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0, true)

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, stats.value, stats.value_add)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, stats.value, stats.value_add)
	add_modifier(specials_modifier)
