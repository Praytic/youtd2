extends TowerBehavior


var bloodlust_bt: BuffType
var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bloodlust_crit_damage = 0.45, bloodlust_crit_damage_add = 0.004, bloodlust_attack_speed = 0.15, bloodlust_attack_speed_add = 0.002, bloody_experience_range = 250, bloody_experience_level_cap = 10},
		2: {bloodlust_crit_damage = 0.55, bloodlust_crit_damage_add = 0.006, bloodlust_attack_speed = 0.20, bloodlust_attack_speed_add = 0.003, bloody_experience_range = 300, bloody_experience_level_cap = 15},
		3: {bloodlust_crit_damage = 0.65, bloodlust_crit_damage_add = 0.008, bloodlust_attack_speed = 0.25, bloodlust_attack_speed_add = 0.004, bloody_experience_range = 350, bloody_experience_level_cap = 20},
	}

const BLOODLUST_DURATION: float = 5.0
const BLOODLUST_DURATION_ADD: float = 0.12
const BLOODY_EXPERIENCE_EXP_GAIN: float = 1


func tower_init():
	bloodlust_bt = BuffType.new("bloodlust_bt", BLOODLUST_DURATION, BLOODLUST_DURATION_ADD, true, self)
	var bloodlust_mod: Modifier = Modifier.new()
	bloodlust_mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, _stats.bloodlust_attack_speed, _stats.bloodlust_attack_speed_add)
	bloodlust_mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_DAMAGE, _stats.bloodlust_crit_damage, _stats.bloodlust_crit_damage_add)
	bloodlust_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	bloodlust_bt.set_buff_modifier(bloodlust_mod)
	bloodlust_bt.set_buff_tooltip(tr("NSMT"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.add_event_on_damage(bloody_exp_aura_on_damage)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	aura_bt.set_buff_tooltip(tr("UFI6"))


func on_autocast(event: Event):
	var level: int = tower.get_level()

	bloodlust_bt.apply(tower, event.get_target(), level)


func bloody_exp_aura_on_damage(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var max_level_for_gain: int = _stats.bloody_experience_level_cap + caster.get_level() / 5

	if event.get_number_of_crits() > 0 && (buffed_tower.get_level() < max_level_for_gain || buffed_tower == caster):
		var exp_gained: float = BLOODY_EXPERIENCE_EXP_GAIN * buffed_tower.get_base_attack_speed() * (800.0 / buffed_tower.get_base_range())
		buffed_tower.add_exp(exp_gained)
