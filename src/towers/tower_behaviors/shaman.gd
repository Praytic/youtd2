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
const BLOODY_EXPERIENCE_RANGE: float = 250
const BLOODY_EXPERIENCE_EXP_GAIN: float = 1


# NOTE: this tower's tooltip in original game includes
# innate stats
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.1375, 0.0)


func tower_init():
	bloodlust_bt = BuffType.new("bloodlust_bt", BLOODLUST_DURATION, BLOODLUST_DURATION_ADD, true, self)
	var bloodlust_mod: Modifier = Modifier.new()
	bloodlust_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, _stats.bloodlust_attack_speed, _stats.bloodlust_attack_speed_add)
	bloodlust_mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, _stats.bloodlust_crit_damage, _stats.bloodlust_crit_damage_add)
	bloodlust_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	bloodlust_bt.set_buff_modifier(bloodlust_mod)
	bloodlust_bt.set_buff_tooltip("Bloodlust\nIncreases crit damage and attack speed.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.add_event_on_damage(bloody_exp_aura_on_damage)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/gold_bar.tres")
	aura_bt.set_buff_tooltip("Bloody Experience\nGrants experience every time tower crits.")


func create_autocasts_DELETEME() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var bloodlust_crit_damage: String = Utils.format_float(_stats.bloodlust_crit_damage, 2)
	var bloodlust_crit_damage_add: String = Utils.format_float(_stats.bloodlust_crit_damage_add, 3)
	var bloodlust_attack_speed: String = Utils.format_percent(_stats.bloodlust_attack_speed, 2)
	var bloodlust_attack_speed_add: String = Utils.format_percent(_stats.bloodlust_attack_speed_add, 2)

	autocast.title = "Bloodlust"
	autocast.icon = "res://resources/icons/masks/mask_07.tres"
	autocast.description_short = "The Shaman makes a friendly tower lust for blood, increasing its crit damage and attack speed.\n"
	autocast.description = "The Shaman makes a friendly tower lust for blood, increasing its crit damage by x%s and attack speed by %s for %s seconds.\n" % [bloodlust_crit_damage, bloodlust_attack_speed, BLOODLUST_DURATION] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+x%s crit damage\n" % bloodlust_crit_damage_add \
	+ "+%s attack speed\n" % bloodlust_attack_speed_add \
	+ "+%s seconds duration\n" % BLOODLUST_DURATION_ADD
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.cast_range = 500
	autocast.target_self = true
	autocast.target_art = "res://src/effects/roar.tscn"
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 15
	autocast.buff_type = bloodlust_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 500
	autocast.handler = on_autocast

	return [autocast]


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var bloody_experience_level_cap: String = Utils.format_float(_stats.bloody_experience_level_cap, 2)
	var bloody_experience_gain: String = Utils.format_float(BLOODY_EXPERIENCE_EXP_GAIN, 2)

	aura.name = "Bloody Experience"
	aura.icon = "res://resources/icons/gems/gem_07.tres"
	aura.description_short = "Nearby towers receive experience every time they crit with an attack.\n"
	aura.description_full = "Every tower below %s level in %d range receives %s experience every time it crits with an attack. The amount of experience gained is base attack speed and range adjusted. Level cap does not affect the Shaman himself.\n" % [bloody_experience_level_cap, _stats.bloody_experience_range, bloody_experience_gain] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1 level cap every 5 levels\n"

	aura.aura_range = _stats.bloody_experience_range
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_autocast(event: Event):
	var level: int = tower.get_level()

	bloodlust_bt.apply(tower, event.get_target(), level)


func bloody_exp_aura_on_damage(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var max_level_for_gain: int = _stats.bloody_experience_level_cap + caster.get_level() / 5

	if event.get_number_of_crits() > 0 && (buffed_tower.get_level() < max_level_for_gain || buffed_tower == caster):
		var exp_gained: float = BLOODY_EXPERIENCE_EXP_GAIN * buffed_tower.get_base_attack_speed() * (800.0 / buffed_tower.get_range())
		buffed_tower.add_exp(exp_gained)

