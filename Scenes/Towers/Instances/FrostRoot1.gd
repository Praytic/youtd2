extends Tower


const _tier_stats_map: Dictionary = {
	1: {value = 25, value_add = 1},
	2: {value = 125, value_add = 5},
	3: {value = 375, value_add = 15},
	4: {value = 750, value_add = 30},
	5: {value = 1500, value_add = 60},
	6: {value = 2500, value_add = 100},
}


func _ready():
	var tier: int = get_tier()
	var stats = _tier_stats_map[tier]

	var frozen_thorn_buff = FrozenThorn.new(stats.value, stats.value_add)
	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)
