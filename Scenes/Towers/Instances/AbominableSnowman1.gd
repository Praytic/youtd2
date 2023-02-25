extends Tower

# TODO: visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounce_damage_multiplier = 0.25},
		2: {bounce_damage_multiplier = 0.20},
		3: {bounce_damage_multiplier = 0.15},
		4: {bounce_damage_multiplier = 0.10},
		5: {bounce_damage_multiplier = 0.05},
	}


func _ready():
	var bounce_attack_buff = BounceAttack.new(2, _stats.bounce_damage_multiplier)
	bounce_attack_buff.apply_to_unit_permanent(self, self, 0)

