extends TowerBehavior


var charm_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level = 1, buff_power = 100, buff_power_add = 6},
		2: {buff_level = 30, buff_power = 200, buff_power_add = 12},
		3: {buff_level = 60, buff_power = 300, buff_power_add = 18},
		4: {buff_level = 90, buff_power = 400, buff_power_add = 24},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MANA_PERC, 0.0, 0.001)
	m.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.001)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0005)
	charm_bt = BuffType.new("charm_bt", 0, 0.0005, true, self)
	charm_bt.set_buff_icon("res://Resources/Icons/GenericIcons/charm.tres")
	charm_bt.set_buff_modifier(m)
	charm_bt.set_stacking_group("charm_bt")
	charm_bt.set_buff_tooltip("Snake Charm\nIncreases maximum mana, mana regeneration and spell damage.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var mod_mana_max: String = Utils.format_percent(_stats.buff_power * 0.001, 2)
	var mod_mana_max_add: String = Utils.format_percent(_stats.buff_power_add * 0.001, 2)
	var mod_mana_regen: String = mod_mana_max
	var mod_mana_regen_add: String = mod_mana_max_add
	var mod_spell_damage: String = Utils.format_percent(_stats.buff_power * 0.0005, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.buff_power_add * 0.0005, 2)

	autocast.title = "Snake Charm"
	autocast.icon = "res://Resources/Icons/undead/skull_wand_03.tres"
	autocast.description_short = "This unit will increase nearby towers' mana, mana regeneration and spell damage.\n"
	autocast.description = "Increases the target's maximum mana by %s, its mana regeneration by %s and its spell damage by %s. The buff lasts 5 seconds.\n" % [mod_mana_max, mod_mana_regen, mod_spell_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s mana regeneration\n" % mod_mana_regen_add \
	+ "+%s mana \n" % mod_mana_max_add \
	+ "+%s spell damage\n" % mod_spell_damage_add \
	+ "+5 seconds duration at level 25\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 10
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 200
	autocast.handler = on_autocast

	return [autocast]


func on_autocast(event: Event):
	if tower.get_level() < 25:
		charm_bt.apply_advanced(tower, event.get_target(), _stats.buff_level + tower.get_level(), _stats.buff_power + tower.get_level() * _stats.buff_power_add, 5)
	else:
		charm_bt.apply_advanced(tower, event.get_target(), _stats.buff_level + tower.get_level(), _stats.buff_power + tower.get_level() * _stats.buff_power_add, 10)
