extends Tower


var cb_stun: BuffType
var boekie_charged_obelisk_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Electric Field[/color]\n"
	text += "On every attack this tower shocks a creep in 1000 range. This shock deals 1000 spelldamage and stuns for 0.2 seconds, the spelldamage has 20% bonus chance to crit. The stun does not work on bosses! \n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+40 spelldamage\n"
	text += "+0.4% bonus crit chance\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Applies a buff to target tower which lasts 10 seconds, it increases the attack speed of the tower by 25%. Every second this buff will grant an additional 5% bonus attackspeed.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% base attackspeed\n"
	text += "+0.1% bonus attackspeed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.04)


func tower_init():
	cb_stun = CbStun.new("charged_obelisk_stun", 0, 0, false, self)

	boekie_charged_obelisk_bt = BuffType.new("boekie_charged_obelisk_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.001)
	boekie_charged_obelisk_bt.set_buff_modifier(mod)
	boekie_charged_obelisk_bt.set_buff_icon("@@0@@")
	boekie_charged_obelisk_bt.set_buff_tooltip("Charge\nThis tower has been charged; it has increased attackspeed.")
	boekie_charged_obelisk_bt.add_periodic_event(boekie_charged_obelisk_bt_periodic, 1.0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Charge"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 5
	autocast.mana_cost = 20
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = boekie_charged_obelisk_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_attack(_event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
	var random_creep: Unit = it.next_random()

	if random_creep == null:
		return

	tower.do_spell_damage(random_creep, 1000 + 40 * lvl, tower.calc_spell_crit(0.20 + 0.004 * lvl, 0))

	if random_creep.get_size() < CreepSize.enm.BOSS:
		cb_stun.apply_only_timed(tower, random_creep, 0.2)

	SFX.sfx_at_unit("BoltImpact.mdl", random_creep)


func on_autocast(event: Event):
	var tower: Tower = self
	boekie_charged_obelisk_bt.apply(tower, event.get_target(), tower.get_level() * 6)


func boekie_charged_obelisk_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var new_level: int = buff.get_level() + 50 + caster.get_level()
	var duration: float = buff.get_remaining_duration()

	buff = boekie_charged_obelisk_bt.apply_custom_timed(caster, target, new_level, duration)
	buff.set_remaining_duration(duration)
