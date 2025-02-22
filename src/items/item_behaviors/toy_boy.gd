extends ItemBehavior


var playtime_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.50, 0.01)


func item_init():
	playtime_bt = BuffType.new("playtime_bt", 2.0, 0, false, self)
	playtime_bt.set_buff_icon("res://resources/icons/generic_icons/pokecog.tres")
	playtime_bt.set_buff_tooltip("Playtime\nReduces attack speed.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.5, 0.0)
	playtime_bt.set_buff_modifier(mod)


func periodic(_event: Event):
	CombatLog.log_item_ability(item, null, "Play with me!")
	playtime_bt.apply(item.get_carrier(), item.get_carrier(), 1)
