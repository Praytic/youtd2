extends TowerBehavior


# Changed original script by adding apply_soul_bonus() to
# get rid of the need to store the soul stats in
# user_real's. Instead, tower will apply changes appropriate
# for it's tier in apply_soul_bonus().


var natac_hall_of_souls_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {soul_damage = 6, soul_damage_add = 0.3, soul_experience = 1},
		2: {soul_damage = 12, soul_damage_add = 0.6, soul_experience = 2},
		3: {soul_damage = 18, soul_damage_add = 0.9, soul_experience = 3},
	}

const AURA_RANGE: float = 1000


func get_ability_description() -> String:
	var soul_damage: String = Utils.format_float(_stats.soul_damage, 2)
	var soul_damage_add: String = Utils.format_float(_stats.soul_damage_add, 2)
	var soul_experience: String = Utils.format_float(_stats.soul_experience, 2)
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)

	var text: String = ""

	text += "[color=GOLD]Revenge of Souls[/color]\n"
	text += "This tower gains %s permanent bonus damage and %s experience every time a creep in %s range dies.\n" % [soul_damage, soul_experience, aura_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage per kill\n" % soul_damage_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Revenge of Souls[/color]\n"
	text += "This tower gains permanent bonus damage and experience every time a creep dies near the tower.\n"

	return text


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Revenge of Souls", 1000, TargetType.new(TargetType.CREEPS))]


func tower_init():
	natac_hall_of_souls_bt = BuffType.create_aura_effect_type("natac_hall_of_souls_bt", false, self)
	natac_hall_of_souls_bt.set_buff_icon("@@0@@")
	natac_hall_of_souls_bt.add_event_on_create(bt_on_create)
	natac_hall_of_souls_bt.add_event_on_death(bt_on_death)


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect = natac_hall_of_souls_bt
	return [aura]


# Carry over soul damage from previous tier
func on_create(preceding: Tower):
	tower.user_int = _stats.soul_experience
	tower.user_real = _stats.soul_damage
	tower.user_real2 = _stats.soul_damage_add

	if preceding != null && preceding.get_family() == tower.get_family():
		var soul_bonus: float = preceding.user_real3
		tower.user_real3 = soul_bonus
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD, soul_bonus)
	else:
		tower.user_real3 = 0.0


func bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var family: int = caster.get_family()
	buff.user_int = family


# Iterate over all Hall of Souls towers in range of killed
# creep and apply bonuses from "Revenge of Souls" ability
func bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(target, TargetType.new(TargetType.TOWERS), 1000)

	SFX.sfx_at_unit("AIsoTarget.mdl", target)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next.get_family() == buff.user_int:
			apply_soul_bonus(next)


func apply_soul_bonus(target: Unit):
	var stat_soul_experience: int = target.user_int
	var stat_soul_damage: float = target.user_real
	var stat_soul_damage_add: float = target.user_real2

#	NOTE: can't use "_stats" here because target may be
#	another "Hall of Souls" tower with a different tier.
	var soul_damage: float = stat_soul_damage + stat_soul_damage_add * target.get_level()
	var soul_experience: float = stat_soul_experience

	target.modify_property(Modification.Type.MOD_DAMAGE_ADD, soul_damage)
	target.add_exp(soul_experience)
	target.user_real3 += soul_damage
