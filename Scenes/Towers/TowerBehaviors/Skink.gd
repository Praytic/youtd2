extends TowerBehavior


# NOTE: added aura levels which scale with posion damage.
# Original script doesn't define aura levels, not sure how
# it managed to work correctly.


var aura_bt: BuffType
var poison_bt: BuffType

const AURA_RANGE: int = 200


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg = 3, dmg_add = 0.12},
		2: {dmg = 10, dmg_add = 0.4},
		3: {dmg = 30, dmg_add = 1.2},
		4: {dmg = 76.5, dmg_add = 3.06},
		5: {dmg = 127.5, dmg_add = 5.1},
	}


func poisenskin(event: Event):
	var B: Buff = event.get_buff()

	var C: Tower = B.get_caster()
	var T: Tower = B.get_buffed_unit()
	var U: Unit = event.get_target()
	var P: Buff = U.get_buff_of_type(poison_bt)
	var dmg: float = (C.user_real + C.user_real2 * C.get_level()) * T.get_current_attack_speed() / (T.get_range() / 800.0)

	if P != null:
		if P.get_caster().get_instance_id() == P.user_int:
			P.refresh_duration()
			P.user_real = P.user_real + dmg
		else:
			dmg = P.user_real + dmg
			P.remove_buff()
			P = poison_bt.apply(C, U, C.get_level())
			P.user_int = C.get_instance_id()
			P.user_real = dmg
	else:
		P = poison_bt.apply(C, U, C.get_level())
		P.user_int = C.get_instance_id()
		P.user_real = dmg


func dot(event: Event):
	var B: Buff = event.get_buff()

	var T: Tower = B.get_caster()
	T.do_spell_damage(B.get_buffed_unit(), B.user_real, T.calc_spell_crit_no_bonus())
	var effect: int = Effect.add_special_effect_target("Abilities\\Spells\\NightElf\\CorrosiveBreath\\ChimaeraAcidTargetArt.mdl", T, Unit.BodyPart.HEAD)
	Effect.destroy_effect_after_its_over(effect)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/poison_gas.tres")
	aura_bt.add_event_on_attack(poisenskin)
	aura_bt.set_buff_tooltip("Poisonous attack\nApplies poison on attack.")

	poison_bt = BuffType.new("poison_bt", 5.00, 0.0, false, self)
	poison_bt.set_buff_icon("res://Resources/Icons/GenericIcons/poison_gas.tres")
	poison_bt.add_periodic_event(dot, 1.0)
	poison_bt.set_buff_tooltip("Poison\nDeals damage over time.")

	
func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var dmg: String = Utils.format_float(_stats.dmg, 2)
	var dmg_add: String = Utils.format_float(_stats.dmg_add, 2)

	aura.name = "Poisonous Skin"
	aura.icon = "res://Resources/Icons/TowerIcons/PoisonBattery.tres"
	aura.description_short = "This and nearby towers gain a poisonous attack.\n"
	aura.description_full = "This and any towers in %d range gain a poisonous attack. The poison deals %s spell damage per second for 5 seconds. The effect stacks and is attack speed and range adjusted.\n" % [AURA_RANGE, dmg] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per second" % dmg_add

	aura.level = _stats.dmg * 1000
	aura.level_add = _stats.dmg_add * 1000
	aura.power = 0
	aura.power_add = 1
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.aura_effect = aura_bt
	aura.target_self = true
	aura.aura_range = AURA_RANGE
	return [aura]


func on_create(_preceding_tower: Tower):
	tower.user_real = _stats.dmg
	tower.user_real2 = _stats.dmg_add
