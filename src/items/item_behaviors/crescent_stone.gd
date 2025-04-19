extends ItemBehavior


var earth_and_moon_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func item_init():
	earth_and_moon_bt = BuffType.new("earth_and_moon_bt", 5, 0, true, self)
	earth_and_moon_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	earth_and_moon_bt.set_buff_tooltip(tr("O4EP"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_TRIGGER_CHANCES, 0.25, 0.01)
	earth_and_moon_bt.set_buff_modifier(mod)


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
	CombatLog.log_item_ability(item, null, "Earth and Moon")
	earth_and_moon_bt.apply(tower, tower, tower.get_level())
