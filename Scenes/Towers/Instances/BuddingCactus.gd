extends Tower


func _ready():
	var splash_attack_buff = SplashAttack.new({320: 0.5})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0, true)


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = SmallCactus.get_cactus_special(0.17, 0.011)

	return specials_modifier
