extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug in original script
# where buff duration level bonus was equal to 0.6s instead
# of 0.1s. This happened becase apply() was called with "6 *
# lvl".


var curse_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {vuln = 0.15},
		2: {vuln = 0.22},
		3: {vuln = 0.29},
		4: {vuln = 0.36},
	}


const VULN_ADD: float = 0.006
const CURSE_DURATION: float = 5
const CURSE_DURATION_ADD: float = 0.1


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()

	curse_bt.apply(tower, target, lvl)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED, _stats.vuln, VULN_ADD)
	curse_bt = BuffType.new("curse_bt", CURSE_DURATION, CURSE_DURATION_ADD, false, self)
	curse_bt.set_buff_modifier(m)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	curse_bt.set_buff_tooltip(tr("N9AS"))
