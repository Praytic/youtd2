extends TowerBehavior


# NOTE: fixed bug in original script where buff was lasting
# too long because level passed to apply() is much greater
# than tower.get_level() and was multiplied 0.1. Fixed by
# switching to apply_custom_timed().


var curse_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level = 0},
		2: {buff_level = 80},
		3: {buff_level = 140},
		4: {buff_level = 210},
	}


func on_autocast(event: Event):
	var lvl: int = tower.get_level()
	var buff_duration: float = 5 + 0.1 * lvl
	curse_bt.apply_custom_timed(tower, event.get_target(), _stats.buff_level + 6 * lvl, buff_duration)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.15, 0.001)
	curse_bt = BuffType.new("curse_bt", 0, 0, false, self)
	curse_bt.set_buff_modifier(m)
	curse_bt.set_stacking_group("curse_bt")
	curse_bt.set_buff_icon("res://Resources/Icons/GenericIcons/alien_skull.tres")
	curse_bt.set_buff_tooltip("Dark Curse\nIncreases attack damage taken.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var damage_increase: String = Utils.format_percent(0.15 + _stats.buff_level * 0.001, 0)

	autocast.title = "Dark Curse"
	autocast.icon = "res://Resources/Icons/fire/flame_purple.tres"
	autocast.description_short = "Causes the target creep to receive more attack damage.\n"
	autocast.description = "Increases the attack damage target creep receives by %s, the curse lasts 5 seconds.\n" % [damage_increase] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% bonusdamage\n" \
	+ "+0.1 second duration\n"
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
