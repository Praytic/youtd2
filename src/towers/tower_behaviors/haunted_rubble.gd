extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Changed value for tier 1 stats:
# 15% + 0.15%/lvl -> 10% + 0.10%/lvl Changed because it
# didn't make sense, the values went down when upgrading to
# tier 2. Pretty sure this is a typo in original script.


var slow_bt: BuffType


const SLOW_DURATION: float = 5.0
const MULTIPLIER_FOR_BOSSES: float = 0.66


func get_tier_stats() -> Dictionary:
	return {
	1: {slow_value = 0.15, chance = 0.10, chance_add = 0.0010},
	2: {slow_value = 0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = 0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = 0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = 0.27, chance = 0.18, chance_add = 0.0018},
}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func tower_init():
	slow_bt = BuffType.new("slow_bt", SLOW_DURATION, 0, false, self)
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.slow_value, 0.0)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	slow_bt.set_buff_modifier(slow)
	
	slow_bt.set_buff_tooltip(tr("FCCP"))


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var atrophy_chance: float = _stats.chance + _stats.chance_add * level
	var target_size: int = target.get_size()
	if target_size == CreepSize.enm.BOSS:
		atrophy_chance *= MULTIPLIER_FOR_BOSSES

	if !tower.calc_chance(atrophy_chance):
		return

	CombatLog.log_ability(tower, target, "Atrophy")

	slow_bt.apply(tower, target, level)
