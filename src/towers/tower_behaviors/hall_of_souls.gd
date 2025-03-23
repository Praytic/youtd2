extends TowerBehavior


# Changed original script by adding apply_soul_bonus() to
# get rid of the need to store the soul stats in
# user_real's. Instead, tower will apply changes appropriate
# for it's tier in apply_soul_bonus().

# [ORIGINAL_GAME_DEVIATION] Added display of damage
# accumulated from Revenge of Souls to tower details.


var aura_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {soul_damage = 6, soul_damage_add = 0.3, soul_experience = 1},
		2: {soul_damage = 12, soul_damage_add = 0.6, soul_experience = 2},
		3: {soul_damage = 18, soul_damage_add = 0.9, soul_experience = 3},
	}


func tower_init():
	multiboard = MultiboardValues.new(1)
	var revenge_damage_label: String = tr("UUFH")
	multiboard.set_key(0, revenge_damage_label)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	aura_bt.add_event_on_create(aura_bt_on_create)
	aura_bt.add_event_on_death(aura_bt_on_death)
	aura_bt.set_hidden()


func on_tower_details() -> MultiboardValues:
	var damage_bonus_text: String = TowerDetails.int_format(tower.user_real3)
	multiboard.set_value(0, damage_bonus_text)

	return multiboard


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


# NOTE: setFamID() in original script
func aura_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var family: int = caster.get_family()
	buff.user_int = family


# Iterate over all Hall of Souls towers in range of killed
# creep and apply bonuses from "Revenge of Souls" ability
# NOTE: increaseDamageAndExp() in original script
func aura_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(target, TargetType.new(TargetType.TOWERS), 1000)

	Effect.create_simple_at_unit("res://src/effects/spell_aiso.tscn", target)

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
