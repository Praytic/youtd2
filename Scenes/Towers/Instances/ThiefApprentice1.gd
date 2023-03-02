extends Tower

# TODO: visual

var m0ck_thief_multiboard: MultiboardValues


# NOTE: gold is multiplied by 10 in stats compared to number
# in description.
func _get_tier_stats() -> Dictionary:
	return {
		1: {bounty_add = 0.0050, item_bonus = 0.05, item_bonus_add = 0.0020, gold = 3},
		2: {bounty_add = 0.0075, item_bonus = 0.06, item_bonus_add = 0.0024, gold = 9},
		3: {bounty_add = 0.0100, item_bonus = 0.07, item_bonus_add = 0.0028, gold = 27},
		4: {bounty_add = 0.0125, item_bonus = 0.08, item_bonus_add = 0.0032, gold = 60},
		5: {bounty_add = 0.0150, item_bonus = 0.09, item_bonus_add = 0.0036, gold = 120},
	}


func _ready():
	var tower = self

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Unit.ModType.MOD_DMG_TO_UNDEAD, -0.10, 0.004)
	specials_modifier.add_modification(Unit.ModType.MOD_BOUNTY_RECEIVED, 0.0, _stats.bounty_add)
	specials_modifier.add_modification(Unit.ModType.MOD_ITEM_CHANCE_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)
	specials_modifier.add_modification(Unit.ModType.MOD_ITEM_QUALITY_ON_KILL, _stats.item_bonus, _stats.item_bonus_add)
	add_modifier(specials_modifier)

	var triggers_buff: Buff = TriggersBuff.new()
	triggers_buff.add_event_on_damage(self, "on_damage", 1.0, 0.004)
	triggers_buff.apply_to_unit_permanent(self, self, 0)	

	m0ck_thief_multiboard = MultiboardValues.new(1)
	m0ck_thief_multiboard.set_key(0, "Gold Stolen")

	tower.user_real = 0.0
	tower.user_int = _stats.gold
	Utils.add_unit_animation_properties(tower, "stand alternate", false)


# TODO: currently this is not called by anyone, should be
# called by tooltip i guess?
func on_tower_details() -> MultiboardValues:
	var tower = self
	m0ck_thief_multiboard.set_value(0, String(int(tower.user_real)))
	return m0ck_thief_multiboard


func on_damage(event: Event):
	var tower = self

	var projectile = _projectile_scene.instance()
	projectile.create_interpolate("Abilities/Weapons/WardenMissile/WardenMissile.mdl", 1000)
	projectile.set_event_on_interpolation_finished(self, "steal")
	projectile.create_linear_interpolation_from_unit_to_unit(tower, 0, 0, event.get_target(), tower, 0, true)


func steal(p: Projectile):
	var tower = p.get_caster()
	var gold_granted: float = (tower.user_int * (tower.get_level() * tower.user_int * 0.04)) / 10
	tower.get_owner().give_gold(gold_granted, tower, false, true)
	tower.user_real = tower.user_real + gold_granted
