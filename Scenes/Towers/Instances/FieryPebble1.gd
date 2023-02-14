extends Tower

const _tier_stats_map: Dictionary = {
	1: {splash_radius = 150},
	2: {splash_radius = 160},
	3: {splash_radius = 170},
	4: {splash_radius = 180},
	5: {splash_radius = 190},
	6: {splash_radius = 200},
}


func _ready():
	var tier: int = get_tier()
	var tier_data = _tier_stats_map[tier]
	var splash_radius: float = tier_data.splash_radius

	var splash_attack_buff = SplashAttack.new({splash_radius: 0.25})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0, true)
