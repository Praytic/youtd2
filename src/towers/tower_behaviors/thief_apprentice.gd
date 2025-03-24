extends TowerBehavior


var multiboard: MultiboardValues
var steal_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {gold = 0.3, gold_add = 0.012},
		2: {gold = 0.9, gold_add = 0.036},
		3: {gold = 2.7, gold_add = 0.108},
		4: {gold = 6.0, gold_add = 0.240},
		5: {gold = 12.0, gold_add = 0.480},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	steal_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	steal_pt.set_event_on_interpolation_finished(steal)
	
	multiboard = MultiboardValues.new(1)
	var gold_stolen_label: String = tr("PZL1")
	multiboard.set_key(0, gold_stolen_label)


func on_create(preceding_tower: Tower):
	if preceding_tower != null && preceding_tower.get_family() == tower.get_family():
		tower.user_real = preceding_tower.user_real
	else:
		tower.user_real = 0.0


func on_tower_details() -> MultiboardValues:
	var gold_stolen_text: String = Utils.format_float(tower.user_real, 0)
	multiboard.set_value(0, gold_stolen_text)
	
	return multiboard


func on_damage(event: Event):
	if !tower.calc_chance(0.1 + tower.get_level() * 0.004):
		return
	
	CombatLog.log_ability(tower, event.get_target(), "Steal")

	Projectile.create_linear_interpolation_from_unit_to_unit(steal_pt, tower, 0, 0, event.get_target(), tower, 0, true)


func steal(_p: Projectile, _creep: Unit):
	var level: int = tower.get_level()
	var gold_granted: float = _stats.gold + _stats.gold_add * level
	tower.get_player().give_gold(gold_granted, tower, false, true)
	tower.user_real += gold_granted
