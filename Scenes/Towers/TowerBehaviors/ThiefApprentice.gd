extends TowerBehavior


var multiboard: MultiboardValues
var steal_pt: ProjectileType


# NOTE: "gold" value is 10 times greater than actual because
# its divided later by 10 when doing actual calculations.
# This is NOT a typo
# TODO: make it not multiplied by 10. I think original
# script does this because it's saved in user_int, so save
# it in user_float instead.
func get_tier_stats() -> Dictionary:
	return {
		1: {bounty_add = 0.0050, item_bonus = 0.05, item_bonus_add = 0.0020, gold = 3},
		2: {bounty_add = 0.0075, item_bonus = 0.06, item_bonus_add = 0.0024, gold = 9},
		3: {bounty_add = 0.0100, item_bonus = 0.07, item_bonus_add = 0.0028, gold = 27},
		4: {bounty_add = 0.0125, item_bonus = 0.08, item_bonus_add = 0.0032, gold = 60},
		5: {bounty_add = 0.0150, item_bonus = 0.09, item_bonus_add = 0.0036, gold = 120},
	}


func get_ability_description() -> String:
	var gold: String = Utils.format_float(_stats.gold / 10.0, 2)
	var gold_add: String = Utils.format_float(_stats.gold * 0.04 / 10.0, 3)

	var text: String = ""

	text += "[color=GOLD]Steal[/color]\n"
	text += "Every time the thief damages a creep there is a 10%% chance he steals %s gold.\n" % gold
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s gold\n" % gold_add
	text += "+0.4% chance"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Steal[/color]\n"
	text += "The Thief has a chance to get gold when he damages a creep.\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, _stats.bounty_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)


func tower_init():
	steal_pt = ProjectileType.create_interpolate("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl", 1000, self)
	steal_pt.set_event_on_interpolation_finished(steal)
	
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Gold Stolen")


func on_create(_preceding_tower: Tower):
	tower.user_real = 0.0
	tower.user_int = _stats.gold


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
	var gold_granted: float = (tower.user_int + (tower.get_level() * tower.user_int * 0.04)) / 10
	tower.get_player().give_gold(gold_granted, tower, false, true)
	tower.user_real = tower.user_real + gold_granted
