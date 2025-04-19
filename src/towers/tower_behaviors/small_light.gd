extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Commented out sections
# relevant to invisibility because invisible waves are
# not implemented.


var holy_weak_bt: BuffType
var magical_sight_bt: BuffType


# NOTE: mod_value and mod_value_add are multiplied by 1000,
# leaving as in original
func get_tier_stats() -> Dictionary:
	return {
		1: {magical_sight_range = 650, vuln = 0.05, vuln_add = 0.002, duration = 3, duration_add = 0.12},
		2: {magical_sight_range = 700, vuln = 0.10, vuln_add = 0.004, duration = 3, duration_add = 0.16},
		3: {magical_sight_range = 750, vuln = 0.15, vuln_add = 0.006, duration = 4, duration_add = 0.16},
		4: {magical_sight_range = 800, vuln = 0.20, vuln_add = 0.008, duration = 4, duration_add = 0.20},
		5: {magical_sight_range = 850, vuln = 0.30, vuln_add = 0.010, duration = 5, duration_add = 0.20},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	var light_mod: Modifier = Modifier.new()
	holy_weak_bt = BuffType.new("holy_weak_bt", _stats.duration, _stats.duration_add, false, self)
	light_mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED, _stats.vuln, _stats.vuln_add)
	light_mod.add_modification(ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED, _stats.vuln, _stats.vuln_add)
	holy_weak_bt.set_buff_modifier(light_mod)
	holy_weak_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	holy_weak_bt.set_buff_tooltip(tr("Y0VY"))


func on_damage(event: Event):
	var creep: Creep = event.get_target()
	var level: int = tower.get_level()

	if creep.get_category() == CreepCategory.enm.UNDEAD:
		holy_weak_bt.apply(tower, creep, level)
