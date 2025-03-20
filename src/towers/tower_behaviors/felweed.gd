extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {bonus_1_attack_count = 7, bonus_1 = 1.10, bonus_2 = 1.20, bonus_3 = 1.30, bonus_4 = 1.40, bonus_1_add = 0.002, bonus_2_add = 0.004, bonus_3_add = 0.006, bonus_4_add = 0.008},
		2: {bonus_1_attack_count = 7, bonus_1 = 1.10, bonus_2 = 1.20, bonus_3 = 1.30, bonus_4 = 1.40, bonus_1_add = 0.002, bonus_2_add = 0.004, bonus_3_add = 0.006, bonus_4_add = 0.008},
		3: {bonus_1_attack_count = 6, bonus_1 = 1.125, bonus_2 = 1.25, bonus_3 = 1.375, bonus_4 = 1.50, bonus_1_add = 0.0025, bonus_2_add = 0.005, bonus_3_add = 0.0075, bonus_4_add = 0.01},
		4: {bonus_1_attack_count = 6, bonus_1 = 1.125, bonus_2 = 1.25, bonus_3 = 1.375, bonus_4 = 1.50, bonus_1_add = 0.0025, bonus_2_add = 0.005, bonus_3_add = 0.0075, bonus_4_add = 0.01},
		5: {bonus_1_attack_count = 5, bonus_1 = 1.15, bonus_2 = 1.30, bonus_3 = 1.45, bonus_4 = 1.60, bonus_1_add = 0.003, bonus_2_add = 0.006, bonus_3_add = 0.009, bonus_4_add = 0.012},
		6: {bonus_1_attack_count = 5, bonus_1 = 1.15, bonus_2 = 1.30, bonus_3 = 1.45, bonus_4 = 1.60, bonus_1_add = 0.003, bonus_2_add = 0.006, bonus_3_add = 0.009, bonus_4_add = 0.012},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_create(_preceding_tower: Tower):
	tower.user_int = 0
	tower.user_int2 = 0
	tower.user_int3 = 0
	tower.user_real = 0


func on_damage(event: Event):
	var damage: float = event.damage
	var level: int = tower.get_level()

	tower.user_int = tower.user_int + 1
	tower.user_int2 = tower.user_int2 + 1
	tower.user_int3 = tower.user_int3 + 1
	tower.user_real = tower.user_real + 1

	var bonus_1_attack_count: int = _stats.bonus_1_attack_count
	var bonus_2_attack_count: int = _stats.bonus_1_attack_count + 1
	var bonus_3_attack_count: int = _stats.bonus_1_attack_count + 2
	var bonus_4_attack_count: int = _stats.bonus_1_attack_count + 3

	if tower.user_int >= bonus_1_attack_count:
		event.damage = event.damage * (_stats.bonus_1 + level * _stats.bonus_1_add)
		tower.user_int = 0

	if tower.user_int2 >= bonus_2_attack_count:
		event.damage = event.damage * (_stats.bonus_2 + level * _stats.bonus_2_add)
		tower.user_int2 = 0

	if tower.user_int3 >= bonus_3_attack_count:
		event.damage = event.damage * (_stats.bonus_3 + level * _stats.bonus_3_add)
		tower.user_int3 = 0

	if tower.user_real >= bonus_4_attack_count:
		event.damage = event.damage * (_stats.bonus_4 + level * _stats.bonus_4_add)
		tower.user_real = 0

	if event.damage > damage:
		var bonus_damage_text: String = Utils.format_float(event.damage, 0)
		tower.get_player().display_small_floating_text(bonus_damage_text, tower, Color8(190, 50, 50), 0)
