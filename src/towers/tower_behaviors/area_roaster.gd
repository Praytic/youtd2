extends TowerBehavior


var ignite_bt: BuffType


const IGNITE_DURATION: float = 5.0
const IGNITE_DURATION_ADD: float = 0.05
const IGNITE_DAMAGE_PERIOD: float = 0.5


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_from_fire = 0.07, ignite_damage = 35, ignite_damage_add = 1.4},
		2: {mod_dmg_from_fire = 0.14, ignite_damage = 70, ignite_damage_add = 2.8},
		3: {mod_dmg_from_fire = 0.21, ignite_damage = 140, ignite_damage_add = 5.6},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: sir_area_damage() in original script
func ignite_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = event.get_target()
	var ignite_damage: float = buff.user_real

	tower.do_spell_damage(target, ignite_damage, tower.calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", IGNITE_DURATION, IGNITE_DURATION_ADD, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	ignite_bt.set_buff_tooltip(tr("WGVN"))
	ignite_bt.add_periodic_event(ignite_bt_periodic, IGNITE_DAMAGE_PERIOD)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_FROM_FIRE, _stats.mod_dmg_from_fire, 0.0)
	ignite_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var active_buff: Buff = target.get_buff_of_type(ignite_bt)
	var active_stacks: int = 0
	var active_damage: float = 0
	if active_buff != null:
		active_stacks = active_buff.user_int
		active_damage = active_buff.user_real

	var new_stacks: int = active_stacks + 1
	var added_damage: float = _stats.ignite_damage + _stats.ignite_damage_add * level
	var new_damage: float = active_damage + added_damage

#	NOTE: weaker tier tower increases damage without
#	refreshing duration
	active_buff = ignite_bt.apply(tower, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)
	active_buff.user_real = new_damage
