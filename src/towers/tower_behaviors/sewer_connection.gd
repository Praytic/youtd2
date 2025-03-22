extends TowerBehavior


var toxic_bt: BuffType


# NOTE: vapor damage stat is multiplied by 10 and divided by
# 10 later, idk why.
func get_tier_stats() -> Dictionary:
	return {
		1: {vapor_damage = 2000, vapor_damage_add = 80},
		2: {vapor_damage = 6000, vapor_damage_add = 240},
		3: {vapor_damage = 12000, vapor_damage_add = 480},
		4: {vapor_damage = 22000, vapor_damage_add = 880},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func D1000_Toxic_Damage(event: Event):
	var b: Buff = event.get_buff()
	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.get_level() / 10, b.get_caster().calc_spell_crit_no_bonus())


func tower_init():
	toxic_bt = BuffType.new("toxic_bt", 10, 0, false, self)
	toxic_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	toxic_bt.add_periodic_event(D1000_Toxic_Damage, 1)
	toxic_bt.set_buff_tooltip(tr("JMRY"))


func on_attack(event: Event):
	if !tower.calc_chance(0.3):
		return

	CombatLog.log_ability(tower, event.get_target(), "Toxic Vapor")

	toxic_bt.apply(tower, event.get_target(), int(tower.get_level() * _stats.vapor_damage_add + _stats.vapor_damage))
