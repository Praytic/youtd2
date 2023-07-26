extends Tower


var D1000_Toxic_vapor: BuffType


# NOTE: vapor damage stat is multiplied by 10 and divided by
# 10 later, idk why.
func get_tier_stats() -> Dictionary:
	return {
		1: {vapor_damage = 2000, vapor_damage_add = 80},
		2: {vapor_damage = 6000, vapor_damage_add = 240},
		3: {vapor_damage = 12000, vapor_damage_add = 480},
		4: {vapor_damage = 22000, vapor_damage_add = 880},
	}


func get_extra_tooltip_text() -> String:
	var vapor_damage: String = str(_stats.vapor_damage / 10)
	var vapor_damage_add: String = str(_stats.vapor_damage_add / 10)

	var text: String = ""

	text += "[color=GOLD]Toxic Vapor[/color]\n"
	text += "On attack, has a 30%% chance to apply a buff that deals %s spell damage per second that lasts for 10 seconds.\n" % vapor_damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage per second\n" % vapor_damage_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.60, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.60, 0.02)


func D1000_Toxic_Damage(event: Event):
	var b: Buff = event.get_buff()
	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.get_level() / 10, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	D1000_Toxic_vapor = BuffType.new("D1000_Toxic_vapor", 10, 0, false, self)
	D1000_Toxic_vapor.set_buff_icon("@@0@@")
	D1000_Toxic_vapor.add_periodic_event(D1000_Toxic_Damage, 1)
	D1000_Toxic_vapor.set_buff_tooltip("Toxic Vapor\nThis unit is afflicted with Toxic Vapor; it receives periodic damage.")


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.3):
		return

	D1000_Toxic_vapor.apply(tower, event.get_target(), int(tower.get_level() * _stats.vapor_damage_add + _stats.vapor_damage))
