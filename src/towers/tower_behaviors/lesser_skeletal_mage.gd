extends TowerBehavior


# NOTE: fixed bug in original script where buff duration
# level bonus was equal to 0.6s instead of 0.1s. This
# happened becase apply() was called with "6 * lvl".


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
	m.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, _stats.vuln, VULN_ADD)
	curse_bt = BuffType.new("curse_bt", CURSE_DURATION, CURSE_DURATION_ADD, false, self)
	curse_bt.set_buff_modifier(m)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	curse_bt.set_buff_tooltip("Dark Curse\nIncreases attack damage taken.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var vuln: String = Utils.format_percent(_stats.vuln, 2)
	var vuln_add: String = Utils.format_percent(VULN_ADD, 2)
	var curse_duration: String = Utils.format_float(CURSE_DURATION, 2)
	var curse_duration_add: String = Utils.format_float(CURSE_DURATION_ADD, 2)

	autocast.title = "Dark Curse"
	autocast.icon = "res://resources/icons/fire/flame_purple.tres"
	autocast.description_short = "Causes the target creep to receive more attack damage.\n"
	autocast.description = "Increases the attack damage target creep receives by %s, the curse lasts %s seconds.\n" % [vuln, curse_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s bonusdamage\n" % vuln_add \
	+ "+%s second duration\n" % curse_duration_add
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 3
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.cast_range = 900
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 30
	autocast.buff_type = curse_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 900
	autocast.handler = on_autocast

	return [autocast]
