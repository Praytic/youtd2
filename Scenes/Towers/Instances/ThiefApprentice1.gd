extends Tower


var m0ck_thief_multiboard: MultiboardValues
var mOck_steal: ProjectileType


# NOTE: gold is multiplied by 10 in stats compared to number
# in description.
func get_tier_stats() -> Dictionary:
	return {
		1: {bounty_add = 0.0050, item_bonus = 0.05, item_bonus_add = 0.0020, gold = 3},
		2: {bounty_add = 0.0075, item_bonus = 0.06, item_bonus_add = 0.0024, gold = 9},
		3: {bounty_add = 0.0100, item_bonus = 0.07, item_bonus_add = 0.0028, gold = 27},
		4: {bounty_add = 0.0125, item_bonus = 0.08, item_bonus_add = 0.0032, gold = 60},
		5: {bounty_add = 0.0150, item_bonus = 0.09, item_bonus_add = 0.0036, gold = 120},
	}


func get_extra_tooltip_text() -> String:
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


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, _stats.bounty_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)


func tower_init():
	mOck_steal = ProjectileType.create_interpolate("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl", 1000, self)
	mOck_steal.set_event_on_interpolation_finished(steal)
	
	m0ck_thief_multiboard = MultiboardValues.new(1)
	m0ck_thief_multiboard.set_key(0, "Gold Stolen")


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	
	tower.user_real = 0.0
	tower.user_int = _stats.gold


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self
	var gold_stolen_text: String = Utils.format_float(tower.user_real, 0)
	m0ck_thief_multiboard.set_value(0, gold_stolen_text)
	
	return m0ck_thief_multiboard


func on_damage(event: Event):
	var tower = self

	if !tower.calc_chance(0.1 + tower.get_level() * 0.004):
		return
	
	Projectile.create_linear_interpolation_from_unit_to_unit(mOck_steal, tower, 0, 0, event.get_target(), tower, 0, true)


func steal(p: Projectile, _creep: Unit):
	var tower = p.get_caster()
	var gold_granted: float = (tower.user_int * (tower.get_level() * tower.user_int * 0.04)) / 10
	tower.get_player().give_gold(gold_granted, tower, false, true)
	tower.user_real = tower.user_real + gold_granted
