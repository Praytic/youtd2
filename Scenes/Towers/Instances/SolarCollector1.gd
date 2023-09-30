extends Tower


var cb_stun: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_add = 1, mana_regen_add = 0.02, attack_mana_cost = 1, release_energy_dmg = 4000, release_energy_dmg_add = 150, stun_duration = 3, stun_duration_for_bosses = 1},
		2: {mana_add = 2, mana_regen_add = 0.02, attack_mana_cost = 2, release_energy_dmg = 12000, release_energy_dmg_add = 450, stun_duration = 5, stun_duration_for_bosses = 1.75},
	}


func get_extra_tooltip_text() -> String:
	var attack_mana_cost: String = Utils.format_float(_stats.attack_mana_cost, 2)

	var text: String = ""

	text += "[color=GOLD]Energetic Attack[/color]\n"
	text += "Each attack costs %s mana. Without mana the tower can't attack.\n" % attack_mana_cost

	return text


func get_autocast_description() -> String:
	var release_energy_dmg: String = Utils.format_float(_stats.release_energy_dmg, 2)
	var release_energy_dmg_add: String = Utils.format_float(_stats.release_energy_dmg_add, 2)
	var stun_duration: String = Utils.format_float(_stats.stun_duration, 2)
	var stun_duration_for_bosses: String = Utils.format_float(_stats.stun_duration_for_bosses, 2)

	var text: String = ""

	text += "Deals %s damage to the attacked creep and stuns it for %s seconds (%s seconds on bosses).\n" % [release_energy_dmg, stun_duration, stun_duration_for_bosses]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % release_energy_dmg_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.005)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 2.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, _stats.mana_add)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, _stats.mana_regen_add)


func tower_init():
	cb_stun = CbStun.new("sollar_collector_stun", 0, 0, false, self)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Release Energy"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 800
	autocast.auto_range = 800
	autocast.cooldown = 5
	autocast.mana_cost = 15
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var creep_size: CreepSize.enm = creep.get_size()
	var damage: float = _stats.release_energy_dmg + _stats.release_energy_dmg_add * tower.get_level()

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("ReviveHuman.mdl", creep, "origin")

	var stun_duration: float
	if creep_size < CreepSize.enm.BOSS:
		stun_duration = _stats.stun_duration
	else:
		stun_duration = _stats.stun_duration_for_bosses

	cb_stun.apply_only_timed(tower, creep, stun_duration)


func on_attack(_event: Event):
	var tower: Tower = self
	var mana: float = tower.get_mana()

	if mana < _stats.attack_mana_cost:
		tower.order_stop()
	else:
		tower.subtract_mana(_stats.attack_mana_cost, false)
