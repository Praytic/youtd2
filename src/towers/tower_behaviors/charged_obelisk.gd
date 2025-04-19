extends TowerBehavior


var stun_bt: BuffType
var charge_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	stun_bt = CbStun.new("charged_obelisk_stun", 0, 0, false, self)

	charge_bt = BuffType.new("charge_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.25, 0.001)
	charge_bt.set_buff_modifier(mod)
	charge_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	charge_bt.set_buff_tooltip(tr("NJH8"))
	charge_bt.add_periodic_event(charge_bt_periodic, 1.0)


func on_attack(_event: Event):
	var lvl: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var random_creep: Unit = it.next_random()

	if random_creep == null:
		return

	tower.do_spell_damage(random_creep, 1000 + 40 * lvl, tower.calc_spell_crit(0.20 + 0.004 * lvl, 0))

	if random_creep.get_size() < CreepSize.enm.BOSS:
		stun_bt.apply_only_timed(tower, random_creep, 0.2)

	Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", random_creep)


func on_autocast(event: Event):
	charge_bt.apply(tower, event.get_target(), tower.get_level() * 6)


func charge_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var new_level: int = buff.get_level() + 50 + caster.get_level()
	var duration: float = buff.get_remaining_duration()

	buff = charge_bt.apply_custom_timed(caster, target, new_level, duration)
	buff.set_remaining_duration(duration)
