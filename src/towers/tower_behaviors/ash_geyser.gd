extends TowerBehavior


# NOTE: fixed bug in original script where lower tier tower
# could temporarily reduce damage of the Ignite. This
# happened because DAMAGE callback always changed user_real
# without checking if it's a downgrade.


var ignite_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_regen = 0.05, mod_regen_add = 0.001},
		2: {mod_regen = 0.10, mod_regen_add = 0.002},
		3: {mod_regen = 0.15, mod_regen_add = 0.003},
		4: {mod_regen = 0.20, mod_regen_add = 0.004},
		5: {mod_regen = 0.25, mod_regen_add = 0.005},
	}


const IGNITE_CHANCE: float = 0.30
const IGNITE_DURATION: float = 8.0
const IGNITE_DAMAGE: float = 0.15
const IGNITE_DAMAGE_ADD: float = 0.006


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var ignite_chance: String = Utils.format_percent(IGNITE_CHANCE, 2)
	var ignite_duration: String = Utils.format_percent(IGNITE_DURATION, 2)
	var mod_regen: String = Utils.format_percent(_stats.mod_regen, 2)
	var mod_regen_add: String = Utils.format_percent(_stats.mod_regen_add, 2)
	var ignite_damage: String = Utils.format_percent(IGNITE_DAMAGE, 2)
	var ignite_damage_add: String = Utils.format_percent(IGNITE_DAMAGE_ADD, 2)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ignite"
	ability.icon = "res://resources/icons/misc/teapot_04.tres"
	ability.description_short = "Chance to ignite hit creeps, dealing a portion of tower's attack damage as spell damage per second and reducing target's health regeneration.\n"
	ability.description_full = "%s chance to ignite hit creeps, dealing %s of tower's attack damage as spell damage per second and reducing target's health regeneration by %s for %s seconds.\n" % [ignite_chance, ignite_damage, mod_regen, ignite_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack damage\n" % ignite_damage_add \
	+ "+%s health regeneration reduction\n" % mod_regen_add

	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({175: 0.30})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, 0.20, 0.004)


# NOTE: drol_fireDot_Damage() in original script
func ignite_bt_periodic(event: Event):
	var b: Buff = event.get_buff()

	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", IGNITE_DURATION, 0, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	ignite_bt.set_buff_tooltip("Ignite\nDeals spell damage over time and reduces health regeneration.")
	ignite_bt.add_periodic_event(ignite_bt_periodic, 1)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -_stats.mod_regen, -_stats.mod_regen)
	ignite_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	if !tower.calc_chance(IGNITE_CHANCE):
		return

	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	CombatLog.log_ability(tower, event.get_target(), "Ignite")

	var buff: Buff = ignite_bt.apply(tower, target, level)

	var current_ignite_damage: float = buff.user_real
	var new_ignite_damage: float = tower.get_current_attack_damage_with_bonus() * (0.15 + tower.get_level() * 0.006)
	if new_ignite_damage > current_ignite_damage:
		buff.user_real = new_ignite_damage
