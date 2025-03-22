extends TowerBehavior


var mark_bt: BuffType


func tower_init():
	mark_bt = BuffType.new("mark_bt", 10.0, 0.4, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.075, 0.002)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.006)
	mark_bt.set_buff_modifier(mod)
	mark_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	mark_bt.set_buff_tooltip(tr("FYXT"))
