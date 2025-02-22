extends ItemBehavior


var ensign_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	ensign_bt = BuffType.new("ensign_bt", 5, 0, false, self)
	ensign_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	ensign_bt.set_buff_tooltip("Ensign's Touch\nReduces armor.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -0.10, -0.006)
	ensign_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	if event.is_main_target():
		ensign_bt.apply(item.get_carrier(), event.get_target(), item.get_carrier().get_level())
