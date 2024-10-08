extends TowerBehavior


var mark_bt: BuffType


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 5.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func tower_init():
	mark_bt = BuffType.new("mark_bt", 10.0, 0.4, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.075, 0.002)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.006)
	mark_bt.set_buff_modifier(mod)
	mark_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	mark_bt.set_buff_tooltip("Burning Mark\nIncreases multicrit, crit chance and attack speed.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Burning Mark"
	autocast.icon = "res://resources/icons/tower_icons/small_fire_sprayer.tres"
	autocast.description_short = "This tower adds a buff to a tower in range. The buff increases multicrit, crit chance and attack speed.\n"
	autocast.description = "This tower adds a buff to a tower in 500 range that lasts 10 seconds. The buff increases multicrit count by 1, crit chance by 7.5% and attack speed by 25%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4 seconds duration\n" \
	+ "+0.6% attack speed\n" \
	+ "+0.2% crit chance\n"
	autocast.caster_art = ""
	autocast.target_art = "res://src/effects/doom_death.tscn"
	autocast.target_art_z_index = Effect.Z_INDEX_BELOW_TOWERS
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 2
	autocast.mana_cost = 20
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = mark_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = Callable()

	return [autocast]
