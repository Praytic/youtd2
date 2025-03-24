extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Changed behavior when
# multiple copies of this tower try to apply Ignite buff on
# same unit.
# 
# Original game: lower tier tower could temporarily reduce
# damage of Ignite.
#
# YouTD2: Lower tier tower can't reduce damage of Ignite.


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


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# NOTE: drol_fireDot_Damage() in original script
func ignite_bt_periodic(event: Event):
	var b: Buff = event.get_buff()

	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", IGNITE_DURATION, 0, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	ignite_bt.set_buff_tooltip(tr("M9RF"))
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
