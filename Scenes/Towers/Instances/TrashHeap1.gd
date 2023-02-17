extends Tower

# TODO: implement visual


const _stats_map: Dictionary = {
	1: {item_chance_add = 0.005, item_quality_add = -0.005},
	2: {item_chance_add = 0.006, item_quality_add = -0.006},
	3: {item_chance_add = 0.007, item_quality_add = -0.007},
	4: {item_chance_add = 0.008, item_quality_add = -0.008},
	5: {item_chance_add = 0.009, item_quality_add = -0.009},
	6: {item_chance_add = 0.010, item_quality_add = -0.010},
}


func _ready():
	pass


func _get_specials_modifier() -> Modifier:
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.10, 0.006)
	specials_modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.20, stats.item_chance_add)
	specials_modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.20, stats.item_quality_add)

	return specials_modifier
