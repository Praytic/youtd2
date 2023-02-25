extends Tower

func _get_tier_stats() -> Dictionary:
	return {
		1: {splash_radius = 150},
		2: {splash_radius = 160},
		3: {splash_radius = 170},
		4: {splash_radius = 180},
		5: {splash_radius = 190},
		6: {splash_radius = 200},
	}


func _ready():
	var splash_attack_buff = SplashAttack.new({_stats.splash_radius: 0.25})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0)
