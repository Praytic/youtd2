extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {lightning_dmg = 100, lightning_dmg_add = 5},
		2: {lightning_dmg = 300, lightning_dmg_add = 15},
		3: {lightning_dmg = 750, lightning_dmg_add = 37.5},
		4: {lightning_dmg = 1875, lightning_dmg_add = 93.75},
		5: {lightning_dmg = 3750, lightning_dmg_add = 187.5},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_create(_preceding_tower: Tower):
	tower.user_int = 0
	

func on_damage(event: Event):
	var creep: Unit = event.get_target()

	if event.is_main_target() == true:
		tower.user_int = 1
	else:
		tower.user_int = 0

	await Utils.create_manual_timer(0.4, self).timeout

	if tower.user_int == 1 && Utils.unit_is_valid(creep):
		CombatLog.log_ability(tower, creep, "Lightning Strike")

		Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", creep)
		tower.do_attack_damage(creep, _stats.lightning_dmg + (_stats.lightning_dmg_add * tower.get_level()), tower.calc_attack_multicrit(0.0, 0.0, 0.0))
