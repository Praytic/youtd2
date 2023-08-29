extends Tower


# NOTE: the original script sets "timeLevelAdd" parameter
# for stun debuff to 0.75 but then also passes 0 for "level"
# so duration never changes. Leaving it as in original.


var chasm_entangle: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {entangle_duration = 1.50, base_entangle_dps = 120},
		2: {entangle_duration = 2.25, base_entangle_dps = 660},
		3: {entangle_duration = 3.00, base_entangle_dps = 1800},
		4: {entangle_duration = 3.75, base_entangle_dps = 4300},
	}


func get_extra_tooltip_text() -> String:
	var entangle_duration: String = Utils.format_float(_stats.entangle_duration, 2)
	var base_entangle_dps: String = Utils.format_float(_stats.base_entangle_dps, 2)
	var base_entangle_dps_add: String = Utils.format_float(_stats.base_entangle_dps / 20.0, 2)

	var text: String = ""

	text += "[color=GOLD]Entangle[/color]\n"
	text += "Has a chance of 12.5%% to entangle the attacked target for %s seconds. Entangled targets are immobile and suffer %s damage per second. Cannot entangle air or boss units. \n" % [entangle_duration, base_entangle_dps]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% chance to entangle\n"
	text += "+%s damage per second" % base_entangle_dps_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	chasm_entangle = CbStun.new("chasm_entangle", _stats.entangle_duration, 0.75, false, self)
	chasm_entangle.set_buff_icon('@@0@@')
	chasm_entangle.add_periodic_event(chasm_entangle_damage, 1.0)


func on_create(_preceding_tower: Tower):
	var tower = self

	#	base entangle dps
	tower.user_int = _stats.base_entangle_dps


func on_damage(event: Event):
	var tower = self

	if !tower.calc_chance(0.125 + tower.get_level() * 0.002):
		return

	var target: Creep = event.get_target()

	if target.get_size() < CreepSize.enm.BOSS && target.get_size() != CreepSize.enm.AIR:
		chasm_entangle.apply(tower, target, 0)

#		NOTE: not sure what reorder() does. Tower script
#		works correctly without this.
#		target.reorder()


func chasm_entangle_damage(event: Event):
	var buff: Buff = event.get_buff()

	var t = buff.get_caster()
	var c: Creep = buff.get_buffed_unit()
	t.do_spell_damage(c, t.user_int + t.user_int * t.get_level() / 20, t.calc_spell_crit_no_bonus())
