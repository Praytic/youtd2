extends TowerBehavior


var multiboard: MultiboardValues
var steal_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {bounty_add = 0.0050, item_bonus = 0.05, item_bonus_add = 0.0020, gold = 0.3, gold_add = 0.012},
		2: {bounty_add = 0.0075, item_bonus = 0.06, item_bonus_add = 0.0024, gold = 0.9, gold_add = 0.036},
		3: {bounty_add = 0.0100, item_bonus = 0.07, item_bonus_add = 0.0028, gold = 2.7, gold_add = 0.108},
		4: {bounty_add = 0.0125, item_bonus = 0.08, item_bonus_add = 0.0032, gold = 6.0, gold_add = 0.240},
		5: {bounty_add = 0.0150, item_bonus = 0.09, item_bonus_add = 0.0036, gold = 12.0, gold_add = 0.480},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var gold: String = Utils.format_float(_stats.gold, 2)
	var gold_add: String = Utils.format_float(_stats.gold_add, 3)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Steal"
	ability.icon = "res://resources/icons/gloves/steal.tres"
	ability.description_short = "Whenever this tower hits a creep, it has a chance to steal gold.\n"
	ability.description_full = "Whenever this tower hits a creep, it has a 10%% chance to steal %s gold.\n" % gold \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s gold\n" % gold_add \
	+ "+0.4% chance"
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, _stats.bounty_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)


func tower_init():
	steal_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	steal_pt.set_event_on_interpolation_finished(steal)
	
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Stolen")


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
