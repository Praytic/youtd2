extends Tower

# TODO: visual


const _stats_map: Dictionary = {
	1: {bounce_damage_multiplier = 0.25},
	2: {bounce_damage_multiplier = 0.20},
	3: {bounce_damage_multiplier = 0.15},
	4: {bounce_damage_multiplier = 0.10},
	5: {bounce_damage_multiplier = 0.05},
}


func _ready():
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var bounce_attack_buff = BounceAttack.new(2, stats.bounce_damage_multiplier)
	bounce_attack_buff.apply_to_unit_permanent(self, self, 0, true)

